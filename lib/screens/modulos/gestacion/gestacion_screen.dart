import 'package:flutter/material.dart';

class GestacionScreen extends StatelessWidget {
  const GestacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestación'),
        backgroundColor: const Color(0xFF993556),
        foregroundColor: Colors.white,
      ),

      body: const Center(
        child: Text(
          'Módulo Gestación',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}