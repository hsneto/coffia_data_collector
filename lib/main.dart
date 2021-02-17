import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coffia_data_collector/image_capture.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      title: 'CoffIA: Data Collector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: Colors.blueAccent,
          accentColor: Colors.blueAccent,
          brightness: Brightness.dark,
          textTheme: TextTheme(bodyText2: TextStyle(color: Colors.white))),
      home: ImageCapture(),
    );
  }
}
