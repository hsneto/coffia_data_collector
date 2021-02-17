import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:metadata/metadata.dart' as md;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'custom_alert.dart';

const bool ALLOW_UPLOAD = false;

class ImageCapture extends StatefulWidget {
  @override
  _ImageCaptureState createState() => _ImageCaptureState();
}

class _ImageCaptureState extends State<ImageCapture> {
  // Active image file
  double _label = 0.0;
  var _exifData;
  File _imageFile;
  final _imagePicker = ImagePicker();

  // Select an  image via gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    PickedFile selected = await _imagePicker.getImage(source: source);

    // Read image metadata
    var bytes = await selected.readAsBytes();
    var metadata = md.MetaData.exifData(bytes);
    var exifData = (metadata.error == null) ? metadata.exifData : {};

    setState(() {
      _imageFile = File(selected.path);
      _exifData = exifData;
    });
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

  // Remove image
  void _clear() {
    setState(() {
      _imageFile = null;
      _exifData = null;
    });
  }

  // Upload image and metadata collection
  void _sendImage() async {
    String idName = DateTime.now().millisecondsSinceEpoch.toString();

    if (ALLOW_UPLOAD) {
      StorageUploadTask _uploadTask = FirebaseStorage.instance
          .ref()
          .child("data")
          .child(idName)
          .putFile(_imageFile);

      StorageTaskSnapshot _taskSnapshot = await _uploadTask.onComplete;
      String url = await _taskSnapshot.ref.getDownloadURL();
      _exifData["firebase"] = {"idName": idName, "url": url, "label": _label};
      Firestore.instance.collection("data").add(_exifData);
    }

    _clear(); // Change to progress bar
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
                          builder: (context) {
                            return Dialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0)),
                              child: Container(
                                height: 200,
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      TextField(
                                        decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: "Hey ya im hint text",
                                            hintStyle: TextStyle(color: Colors.black)
                                        ),
                                      ),
                                      SizedBox(
                                        width: 320.0,
                                        child: RaisedButton(
                                          color: Colors.blueAccent,
                                          child: Text(
                                            "OK",
                                            style:
                                            TextStyle(color: Colors.white),
                                          ),
                                          onPressed: () {},
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          });
                    }),
                IconButton(
                    icon: Icon(Icons.plagiarism),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) => CustomDialog(
                            title: "Success",
                            description: "asydgfhpasidoflsnakdfm~ç/",
                            buttonText: "ok",
                            imagePath: "assets/images/check.gif",
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
                    onPressed: _sendImage),
              ]
            ],
          ),
        ),
      ),
      body: ListView(children: <Widget>[
        if (_imageFile != null) ...[
          Image.file(_imageFile),
          // Uploader(file: _imageFile),
        ] else ...[
          Column(
            children: <Widget>[
              Image.asset("assets/images/static_background.jpg",
                  fit: BoxFit.fitWidth),
            ],
          )
        ]
      ]),
    );
  }
}
