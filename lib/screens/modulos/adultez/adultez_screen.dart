import 'package:flutter/material.dart';

class AdultezScreen extends StatelessWidget {
  const AdultezScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adultez'),
        backgroundColor: const Color(0xFF0F6E56),
        foregroundColor: Colors.white,
      ),

      body: const Center(
        child: Text(
          'Módulo Adultez',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}