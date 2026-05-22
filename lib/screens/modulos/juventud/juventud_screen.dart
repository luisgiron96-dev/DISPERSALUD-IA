import 'package:flutter/material.dart';

class JuventudScreen extends StatelessWidget {
  const JuventudScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Juventud'),
        backgroundColor: const Color(0xFF3B6D11),
        foregroundColor: Colors.white,
      ),

      body: const Center(
        child: Text(
          'Módulo Juventud',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}