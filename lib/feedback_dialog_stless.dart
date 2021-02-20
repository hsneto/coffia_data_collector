import 'package:flutter/material.dart';

class FeedbackDialog extends StatelessWidget {
  final TextEditingController feedbackController;
  final GlobalKey<FormState> formKey;
  bool isCancelled;

  FeedbackDialog({this.feedbackController, this.formKey, this.isCancelled});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: dialogContent(context),
    ));
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
              Text("Rotulação",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 24.0,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 16.0),
              Text(
                  "Na sua opinião, qual a porcentagem de grãos maduros é representado nessa imagem?",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black, fontSize: 16.0)),
              SizedBox(height: 16.0),
              Form(
                  key: formKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Porcentagem (%)",
                            // suffixText: "%",
                            suffixStyle:
                                TextStyle(color: Colors.black, fontSize: 18.0),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black45),
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0)),
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontSize: 18.0),
                          controller: feedbackController,
                          validator: (value) {
                            try {
                              double _value = double.parse(value);
                              if (_value < 0.0 || _value > 100.0)
                                return "Insira um valor entre 0 e 100%.";
                            } catch (e) {
                              return "Valor inválido!";
                            }
                          },
                        )
                      ])),
              SizedBox(height: 24.0),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FlatButton(
                      child: Text("CANCELAR",
                          style: TextStyle(color: Colors.redAccent)),
                      onPressed: () {
                        isCancelled = true;
                        Navigator.pop(context);
                      },
                    ),
                    FlatButton(
                      child: Text("ENVIAR",
                          style: TextStyle(color: Colors.blueAccent)),
                      onPressed: () {
                        if (formKey.currentState.validate()) {
                          isCancelled = false;
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ]),
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
                        blurRadius: 10, color: Colors.black26, spreadRadius: 5)
                  ]),
              child: CircleAvatar(
                backgroundColor: Colors.blueAccent,
                radius: 50,
                backgroundImage: AssetImage("assets/images/question_mark.gif"),
              ),
            ))
      ],
    );
  }
}
