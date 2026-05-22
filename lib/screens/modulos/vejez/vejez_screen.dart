import 'package:flutter/material.dart';

class VejezScreen extends StatelessWidget {
  const VejezScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vejez'),
        backgroundColor: const Color(0xFF5F5E5A),
        foregroundColor: Colors.white,
      ),

      body: const Center(
        child: Text(
          'Módulo Vejez',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}