import 'package:flutter/material.dart';

// Importa todas las pantallas
import 'screens/home/home_screen.dart';
import 'screens/gestacion/gestacion_screen.dart';
import 'screens/modulos/primera_infancia/primera_infancia_screen.dart';
import 'screens/modulos/infancia/infancia_screen.dart';
import 'screens/modulos/adolescencia/adolescencia_screen.dart';
import 'screens/modulos/juventud/juventud_screen.dart';
import 'screens/modulos/adultez/adultez_screen.dart';
import 'screens/modulos/vejez/vejez_screen.dart';

void main() {
  runApp(const DispersaludApp());
}

class DispersaludApp extends StatelessWidget {
  const DispersaludApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DISPERSALUD IA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0F6E56),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/':                (context) => const HomeScreen(),
        '/gestacion':       (context) => const GestacionScreen(),
        '/primera-infancia':(context) => const PrimeraInfanciaScreen(),
        '/infancia':        (context) => const InfanciaScreen(),
        '/adolescencia':    (context) => const AdolescenciaScreen(),
        '/juventud':        (context) => const JuventudScreen(),
        '/adultez':         (context) => const AdultezScreen(),
        '/vejez':           (context) => const VejezScreen(),
      },
    );
  }
}