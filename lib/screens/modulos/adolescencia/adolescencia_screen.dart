import 'package:flutter/material.dart';

class AdolescenciaScreen extends StatelessWidget {
  const AdolescenciaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adolescencia'),
        backgroundColor: const Color(0xFF534AB7),
        foregroundColor: Colors.white,
      ),

      body: const Center(
        child: Text(
          'Módulo Adolescencia',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}