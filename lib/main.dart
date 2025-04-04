import 'package:flutter/material.dart';
import 'record_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '간단한 녹음 앱',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RecordScreen(),
    );
  }
}