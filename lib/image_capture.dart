import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:metadata/metadata.dart' as md;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity/connectivity.dart';
import 'custom_alert.dart';
import 'feedback_dialog.dart';

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
  bool _isLogged = false;
  final _imagePicker = ImagePicker();

  TextEditingController labelController = TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Sign-in anonymously
  Future<void> _signInAnonymously() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      _isLogged = true;
    } catch (e) {
      print(e); // TODO: show dialog with error
    }
  }

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
                imagePath: "assets/images/attention.gif",
                onPressed: _clear,
              ));
    } else {
      PickedFile selected = await _imagePicker.getImage(source: source);

      // SignIn Anonymously
      if (!_isLogged) await _signInAnonymously();

      // Read image metadata
      var bytes = await selected.readAsBytes();
      var metadata = md.MetaData.exifData(bytes);
      var exifData = (metadata.error == null) ? metadata.exifData : {};

      setState(() {
        _imageFile = File(selected.path);
        _exifData = exifData;
      });
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

  // Remove image
  void _clear() {
    labelController.text = "";

    setState(() {
      _imageFile = null;
      _exifData = null;
      _formKey = GlobalKey<FormState>();
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
    String idName = DateTime.now().millisecondsSinceEpoch.toString();

    // Check Internet Connection
    bool isConnected = await checkInternet();
    if (isConnected) {
      StorageUploadTask _uploadTask = FirebaseStorage.instance
          .ref()
          .child("data")
          .child(idName)
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
      _exifData["firebase"] = {"idName": idName, "url": url, "label": _label};
      Firestore.instance.collection("data").add(_exifData);

      showDialog(
          context: context,
          builder: (context) => CustomDialog(
                title: "Upload",
                description: "Imagem enviada com sucesso!",
                buttonText: "OK",
                imagePath: "assets/images/checked.gif",
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
                imagePath: "assets/images/failed.gif",
                onPressed: _clear,
              )).then((value) {
        _isLoading = false;
        _progress = 0.0;
      });
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
                          builder: (context) => CustomDialog(
                                title: "Instruções",
                                description: "bla bla bla",
                                buttonText: "OK",
                                imagePath: "assets/images/instruction.gif",
                              ));
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
      body: ListView(children: <Widget>[
        if (_imageFile != null) ...[
          Image.file(_imageFile),
          if (_isLoading)
            LinearProgressIndicator(
              value: _progress,
            ),
        ] else ...[
          Column(
            children: <Widget>[
              Image.asset("assets/images/static_background.jpg",
                  fit: BoxFit.fitWidth),
            ],
          ),
        ]
      ]),
    );
  }
}
