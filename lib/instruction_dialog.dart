import 'package:flutter/material.dart';

class InstructionDialog extends StatelessWidget {
  final String title, description, buttonText, imagePath;
  final VoidCallback onPressed;

  InstructionDialog(
      {this.title,
      this.description,
      this.buttonText,
      this.imagePath,
      this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: dialogContent(context),
    );
  }

  dialogContent(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(top: 100, bottom: 16, left: 16, right: 16),
          margin: EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(title,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 24.0,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 16.0),
              Text(description,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black, fontSize: 16.0)),
              SizedBox(height: 24.0),
              Align(
                alignment: Alignment.bottomRight,
                child: FlatButton(
                  child:
                      Text(buttonText, style: TextStyle(color: Colors.black45)),
                  onPressed: () {
                    Navigator.pop(context);
                    if (onPressed != null) onPressed();
                  },
                ),
              ),
            ],
          ),
        ),
        Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: Container(
                decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          blurRadius: 10,
                          color: Colors.black26,
                          spreadRadius: 5)
                    ]),
                child: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  radius: 50,
                  backgroundImage: AssetImage(imagePath),
                )))
      ],
    );
  }
}
