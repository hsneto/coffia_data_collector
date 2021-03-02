import 'package:flutter/material.dart';
import 'image_dialog.dart';

class InstructionDialog extends StatelessWidget {
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
              Text("Instruções",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 24.0,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 16.0),
              Text(
                  "Segue abaixo alguns exemplos para serem usados como referência:",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black, fontSize: 16.0)),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  GestureDetector(
                      onTap: () async {
                        await showDialog(
                            context: context, builder: (_) => ImageDialog(
                            imagePath: "assets/samples/sample_0.jpeg"
                        ));
                      },
                      child: Column(children: <Widget>[
                        Image.asset(
                          'assets/samples/sample_0.jpeg',
                          fit: BoxFit.cover,
                          // this is the solution for border
                          width: 50.0,
                          height: 50.0,
                        ),
                        Padding(
                            padding: EdgeInsets.only(top: 5.0),
                            child: Text("0%",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.black, fontSize: 16.0))),
                      ])),
                  GestureDetector(
                      onTap: () async {
                        await showDialog(
                            context: context, builder: (_) => ImageDialog(
                            imagePath: "assets/samples/sample_1.jpeg"
                        ));
                      },
                      child: Column(children: <Widget>[
                        Image.asset(
                          'assets/samples/sample_1.jpeg',
                          fit: BoxFit.cover,
                          // this is the solution for border
                          width: 50.0,
                          height: 50.0,
                        ),
                        Padding(
                            padding: EdgeInsets.only(top: 5.0),
                            child: Text("15%",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.black, fontSize: 16.0))),
                      ])),
                  GestureDetector(
                      onTap: () async {
                        await showDialog(
                            context: context, builder: (_) => ImageDialog(
                            imagePath: "assets/samples/sample_2.jpeg"
                        ));
                      },
                      child: Column(children: <Widget>[
                        Image.asset(
                          'assets/samples/sample_2.jpeg',
                          fit: BoxFit.cover,
                          // this is the solution for border
                          width: 50.0,
                          height: 50.0,
                        ),
                        Padding(
                            padding: EdgeInsets.only(top: 5.0),
                            child: Text("100%",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.black, fontSize: 16.0))),
                      ])),
                ],
              ),
              SizedBox(height: 24.0),
              Align(
                alignment: Alignment.bottomRight,
                child: FlatButton(
                  child: Text("OK", style: TextStyle(color: Colors.black45)),
                  onPressed: () {
                    Navigator.pop(context);
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
                  backgroundImage: AssetImage("assets/gifs/instruction.gif"),
                )))
      ],
    );
  }
}
