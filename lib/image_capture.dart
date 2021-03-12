import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:metadata/metadata.dart' as md;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity/connectivity.dart';
import 'custom_dialog.dart';
import 'feedback_dialog.dart';
import 'instruction_dialog.dart';

const int CAPTURE_START_TIME = 9;
const int CAPTURE_END_TIME = 15;

class ImageCapture extends StatefulWidget {
  @override
  _ImageCaptureState createState() => _ImageCaptureState();
}

class _ImageCaptureState extends State<ImageCapture> {
  var _exifData;
  File _imageFile;
  double _label;
  double _progress;
  bool _isLoading = false;
  FirebaseUser _currentUser;

  int introCounter = 0;

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final _imagePicker = ImagePicker();

  TextEditingController labelController = TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Select an  image via gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    DateTime currentDateTime = new DateTime.now();
    DateTime startDateTime = DateTime(currentDateTime.year,
        currentDateTime.month, currentDateTime.day, CAPTURE_START_TIME);
    DateTime endDateTime = DateTime(currentDateTime.year, currentDateTime.month,
        currentDateTime.day, CAPTURE_END_TIME);

    if (source == ImageSource.camera &&
        !(currentDateTime.isAfter(startDateTime) &&
            currentDateTime.isBefore(endDateTime))) {
      showDialog(
          context: context,
          builder: (context) => CustomDialog(
                title: "Desculpas",
                description:
                    "Por motivos do projeto, o aplicativo bloqueia o uso da câmera antes das $CAPTURE_START_TIME e depois das $CAPTURE_END_TIME horas.",
                buttonText: "OK",
                imagePath: "assets/gifs/attention.gif",
                onPressed: _clear,
              ));
    } else {
      PickedFile selected = await _imagePicker.getImage(source: source);

      // Read image metadata
      if (selected != null) {
        var bytes = await selected.readAsBytes();
        var metadata = md.MetaData.exifData(bytes);
        var exifData =
            (metadata.error == null) ? metadata.exifData : {"firebase": {}};

        setState(() {
          _imageFile = File(selected.path);
          _exifData = exifData;
        });
      }
    }
  }

  // Cropper plugin
  Future<void> _cropImage() async {
    File cropped = await ImageCropper.cropImage(
        sourcePath: _imageFile.path,
        // ratioX: 1.0,
        // ratioY: 1.0,
        // maxWidth: 512,
        // maxHeight: 512,
        toolbarColor: Colors.purple,
        toolbarWidgetColor: Colors.white,
        toolbarTitle: 'Crop It');

    setState(() {
      _imageFile = cropped ?? _imageFile;
    });
  }

  // Check Internet Connection
  Future<bool> checkInternet() async {
    var connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi)
      return true;
    else
      return false;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    FirebaseAuth.instance.onAuthStateChanged.listen((user) {
      _currentUser = user;
    });
  }

  // Ger current user
  Future<FirebaseUser> _getUser() async {
    if (_currentUser != null) return _currentUser;

    try {
      final GoogleSignInAccount googleSignInAccount =
          await googleSignIn.signIn();
      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.getCredential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken);

      final AuthResult authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final FirebaseUser user = authResult.user;
      return user;
    } catch (error) {
      print(error);
      return null;
    }
  }

  // Remove image
  void _clear() {
    labelController.text = "";

    setState(() {
      _imageFile = null;
      _exifData = null;
      _formKey = GlobalKey<FormState>();
      introCounter = 0;
    });
  }

  // Remove image
  void _cancelUpload() {
    labelController.text = "";

    setState(() {
      _formKey = GlobalKey<FormState>();
    });
  }

  // Label image
  void _labelImage() async {
    bool uploadCancelled = await showDialog(
        context: context,
        builder: (context) => FeedbackDialog(
              feedbackController: labelController,
              formKey: _formKey,
            ));

    if (!uploadCancelled) {
      setState(() {
        _label = double.parse(labelController.text);
      });
      _sendImage();
    } else {
      _cancelUpload();
    }
  }

  // Upload image and metadata collection
  void _sendImage() async {
    final FirebaseUser user = await _getUser();

    if (user == null) {
      showDialog(
          context: context,
          builder: (context) => CustomDialog(
                title: "Falha de Autenticação",
                description:
                    "Não foi possível fazer o login. Tente novamente!.",
                buttonText: "OK",
                imagePath: "assets/gifs/failed.gif",
                onPressed: _clear,
              ));
    } else {
      String imageId = user.uid.toString() +
          "_" +
          DateTime.now().millisecondsSinceEpoch.toString();

      // Check Internet Connection
      bool isConnected = await checkInternet();
      if (isConnected) {
        StorageUploadTask _uploadTask = FirebaseStorage.instance
            .ref()
            .child("data")
            .child(imageId)
            .putFile(_imageFile);

        _uploadTask.events.listen((event) {
          setState(() {
            _isLoading = true;
            _progress = event.snapshot.bytesTransferred.toDouble() /
                event.snapshot.totalByteCount.toDouble();
          });
        }).onError((error) {
          print(error);
        });

        StorageTaskSnapshot _taskSnapshot = await _uploadTask.onComplete;
        String url = await _taskSnapshot.ref.getDownloadURL();
        _exifData["firebase"] = {
          "id": imageId,
          "label": _label,
          "url": url,
        };
        Firestore.instance
            .collection(user.uid)
            .document(imageId)
            .setData(_exifData);

        Firestore.instance.collection(user.uid).document("user").setData({
          "displayName": user.displayName,
          "uid": user.uid,
          "email": user.email,
          "phoneNumber": user.phoneNumber,
          "auth": "Google SignIn"
        });

        showDialog(
            context: context,
            builder: (context) => CustomDialog(
                  title: "Upload",
                  description: "Imagem enviada com sucesso!",
                  buttonText: "OK",
                  imagePath: "assets/gifs/checked.gif",
                  onPressed: _clear,
                )).then((value) {
          _isLoading = false;
          _progress = 0.0;
        });
      } else {
        showDialog(
            context: context,
            builder: (context) => CustomDialog(
                  title: "Upload",
                  description:
                      "Falha no envio da imagem!\nConfira sua conexão com a internet.",
                  buttonText: "OK",
                  imagePath: "assets/gifs/failed.gif",
                  onPressed: _clear,
                )).then((value) {
          _isLoading = false;
          _progress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        child: Container(
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              if (_imageFile == null) ...[
                IconButton(
                    icon: Icon(Icons.photo_camera),
                    onPressed: () => _pickImage(ImageSource.camera)),
                IconButton(
                    icon: Icon(Icons.photo_library),
                    onPressed: () => _pickImage(ImageSource.gallery)),
                IconButton(
                    icon: Icon(Icons.help),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) => InstructionDialog());
                    }),
              ],
              if (_imageFile != null) ...[
                IconButton(
                    icon: Icon(Icons.refresh),
                    tooltip: 'Retake Image',
                    onPressed: _clear),
                IconButton(
                    icon: Icon(Icons.crop),
                    tooltip: 'Edit Image',
                    onPressed: _cropImage),
                IconButton(
                    icon: Icon(Icons.cloud_upload),
                    tooltip: 'Upload Image',
                    onPressed: _labelImage),
              ]
            ],
          ),
        ),
      ),
      body: _imageFile == null
          ?
          // Center(
          //         child: Image.asset("assets/images/static_background.png",
          //             fit: BoxFit.fitHeight),
          //       )
          GestureDetector(
              onTap: () async {
                if (introCounter == 2) {
                  await showDialog(
                      context: context,
                      builder: (context) => CustomDialog(
                            title: "CoffIA: Data Collector",
                            description:
                                "Este aplicativo coleta imagens de diferentes porcentagens de maturação do grão do café para criar um banco de imagens que será usado em projeto de parceria entre o Ifes - Campus Vitória e o Incaper.\n\nAgradecemos sua colaboração!",
                            buttonText: "OK",
                            imagePath: "assets/gifs/info.gif",
                            onPressed: _clear,
                          ));
                  introCounter = 0;
                } else {
                  introCounter++;
                }
              },
              child: Center(
                  child: Image.asset(
                'assets/images/static_background.png',
                fit: BoxFit.fitHeight,
              )),
            )
          : ListView(children: <Widget>[
              Image.file(_imageFile),
              if (_isLoading)
                LinearProgressIndicator(
                  value: _progress,
                ),
            ]),
    );
  }
}
