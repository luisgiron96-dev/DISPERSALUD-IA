import 'package:flutter/material.dart';

class GestacionScreen extends StatefulWidget {
  const GestacionScreen({super.key});

  @override
  State<GestacionScreen> createState() => _GestacionScreenState();
}

class _GestacionScreenState extends State<GestacionScreen> {

  final TextEditingController nombreController =
      TextEditingController();

  final TextEditingController semanasController =
      TextEditingController();

  final TextEditingController edadController =
      TextEditingController();

  final TextEditingController presionController =
      TextEditingController();

  String diagnostico = '';
  Color colorDiagnostico = Colors.green;

  void evaluarPaciente() {

    final presion =
        int.tryParse(presionController.text) ?? 0;

    if (presion >= 140) {

      diagnostico =
          '⚠️ Riesgo de hipertensión gestacional. Requiere remisión inmediata.';

      colorDiagnostico = Colors.red;

    } else {

      diagnostico =
          '✅ Control prenatal estable. Continuar seguimiento.';

      colorDiagnostico = Colors.green;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFF111111),

      appBar: AppBar(

        backgroundColor: const Color(0xFF8E2C52),

        title: const Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Text(
              'Gestación',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              'Control prenatal · DISPERSALUD IA',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(14),

        child: Column(

          children: [

            // CARD 1

            Container(

              width: double.infinity,

              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(

                color: const Color(0xFF1E1E1E),

                borderRadius:
                    BorderRadius.circular(18),

                border: Border.all(
                  color: Colors.white10,
                ),
              ),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(

                    'Datos de la gestante',

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(

                    children: [

                      Expanded(
                        child: _campo(
                          controller:
                              semanasController,
                          label:
                              'Semanas gestación',
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _campo(
                          controller:
                              edadController,
                          label: 'Edad',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _campo(
                    controller: nombreController,
                    label: 'Nombre',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // CARD 2

            Container(

              width: double.infinity,

              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(

                color: const Color(0xFF1E1E1E),

                borderRadius:
                    BorderRadius.circular(18),

                border: Border.all(
                  color: Colors.white10,
                ),
              ),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(

                    'Signos vitales y control',

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  _campo(
                    controller: presionController,
                    label: 'Presión arterial',
                  ),

                  const SizedBox(height: 20),

                  _filaDato(
                    'Peso materno',
                    '62 kg',
                    'Normal',
                    Colors.green,
                  ),

                  const SizedBox(height: 12),

                  _filaDato(
                    'Frecuencia fetal',
                    '148 lpm',
                    'OK',
                    Colors.green,
                  ),

                  const SizedBox(height: 12),

                  _filaDato(
                    'Altura uterina',
                    '27 cm',
                    'Adecuado',
                    Colors.green,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // CARD 3

            Container(

              width: double.infinity,

              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(

                color: const Color(0xFF1E1E1E),

                borderRadius:
                    BorderRadius.circular(18),

                border: Border.all(
                  color: Colors.white10,
                ),
              ),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(

                    'Lista de chequeo prenatal',

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  _checkItem(
                    'Toxoide tetánico aplicado',
                    Colors.green,
                  ),

                  _checkItem(
                    'Ácido fólico suministrado',
                    Colors.green,
                  ),

                  _checkItem(
                    'Ecografía 2do trimestre pendiente',
                    Colors.orange,
                  ),

                  _checkItem(
                    'Hemoglobina baja · anemia leve',
                    Colors.red,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // DIAGNOSTICO IA

            if (diagnostico.isNotEmpty)

              Container(

                width: double.infinity,

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(

                  color:
                      colorDiagnostico.withOpacity(0.15),

                  borderRadius:
                      BorderRadius.circular(16),

                  border: Border.all(
                    color: colorDiagnostico,
                  ),
                ),

                child: Text(

                  diagnostico,

                  style: TextStyle(
                    color: colorDiagnostico,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // BOTON

            SizedBox(

              width: double.infinity,
              height: 55,

              child: ElevatedButton(

                onPressed: evaluarPaciente,

                style: ElevatedButton.styleFrom(

                  backgroundColor:
                      const Color(0xFF8E2C52),

                  shape: RoundedRectangleBorder(

                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),

                child: const Text(

                  'Guardar control prenatal',

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(

              width: double.infinity,
              height: 55,

              child: OutlinedButton(

                onPressed: () {},

                style: OutlinedButton.styleFrom(

                  side: const BorderSide(
                    color: Colors.white24,
                  ),

                  shape: RoundedRectangleBorder(

                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),

                child: const Text(

                  'Remitir a ginecobstetricia',

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
  }) {

    return TextField(

      controller: controller,

      style: const TextStyle(
        color: Colors.white,
      ),

      decoration: InputDecoration(

        labelText: label,

        labelStyle: const TextStyle(
          color: Colors.white60,
        ),

        filled: true,

        fillColor: const Color(0xFF2A2A2A),

        border: OutlineInputBorder(

          borderRadius:
              BorderRadius.circular(12),

          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _filaDato(
    String titulo,
    String valor,
    String estado,
    Color color,
  ) {

    return Row(

      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

      children: [

        Text(
          titulo,
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),

        Row(

          children: [

            Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(width: 10),

            Container(

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),

              decoration: BoxDecoration(

                color: color.withOpacity(0.2),

                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Text(

                estado,

                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _checkItem(
    String texto,
    Color color,
  ) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 12),

      child: Row(

        children: [

          Icon(
            Icons.check_circle,
            color: color,
            size: 18,
          ),

          const SizedBox(width: 10),

          Expanded(

            child: Text(

              texto,

              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}