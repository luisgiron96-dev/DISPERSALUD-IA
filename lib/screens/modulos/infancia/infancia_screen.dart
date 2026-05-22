import 'package:flutter/material.dart';

class InfanciaScreen extends StatelessWidget {
  const InfanciaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infancia'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: const Center(
        child: Text(
          'Módulo Infancia',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}