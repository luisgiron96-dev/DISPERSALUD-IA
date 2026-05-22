import 'package:flutter/material.dart';

class PrimeraInfanciaScreen extends StatelessWidget {
  const PrimeraInfanciaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Primera Infancia'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),

      body: const Center(
        child: Text(
          'Módulo Primera Infancia',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}