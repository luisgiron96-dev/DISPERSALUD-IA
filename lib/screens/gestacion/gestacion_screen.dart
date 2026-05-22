import 'package:flutter/material.dart';

import '../../../database/database_helper.dart';
import '../../../models/gestacion_model.dart';

class GestacionScreen extends StatefulWidget {
  const GestacionScreen({super.key});

  @override
  State<GestacionScreen> createState() => _GestacionScreenState();
}

class _GestacionScreenState extends State<GestacionScreen> {

  final TextEditingController nombreController =
      TextEditingController();

  final TextEditingController edadController =
      TextEditingController();

  final TextEditingController presionController =
      TextEditingController();

  Future<void> guardarPaciente() async {

    final paciente = GestacionModel(
      nombre: nombreController.text,
      edad: int.parse(edadController.text),
      presion: presionController.text,
    );

    final db = await DatabaseHelper.instance.database;

    await db.insert(
      'gestacion',
      paciente.toMap(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paciente guardado correctamente'),
      ),
    );

    nombreController.clear();
    edadController.clear();
    presionController.clear();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text('Gestación'),
        backgroundColor: const Color(0xFF993556),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: SingleChildScrollView(
          child: Column(

            children: [

              TextField(
                controller: nombreController,

                decoration: const InputDecoration(
                  labelText: 'Nombre paciente',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: edadController,
                keyboardType: TextInputType.number,

                decoration: const InputDecoration(
                  labelText: 'Edad',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: presionController,

                decoration: const InputDecoration(
                  labelText: 'Presión arterial',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(

                  onPressed: guardarPaciente,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF993556),
                    foregroundColor: Colors.white,
                  ),

                  child: const Text(
                    'Guardar paciente',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}