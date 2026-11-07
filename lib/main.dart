import 'package:flutter/material.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            'SOFTIES test screen opened',
            style: TextStyle(fontSize: 22, color: Color(0xFFD81860)),
          ),
        ),
      ),
    );
  }
}
