import 'package:flutter/material.dart';

// Navegación principal
import 'screens/main_screen.dart';

// Pantallas de módulos (para las rutas)
import 'screens/modulos/gestacion/gestacion_screen.dart';
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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111111),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1D9E75),
          surface: Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111111),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      // ✅ Ahora abre MainScreen (con las 4 pestañas)
      initialRoute: '/',
      routes: {
        '/':                 (context) => const MainScreen(),
        '/gestacion':        (context) => const GestacionScreen(),
        '/primera-infancia': (context) => const PrimeraInfanciaScreen(),
        '/infancia':         (context) => const InfanciaScreen(),
        '/adolescencia':     (context) => const AdolescenciaScreen(),
        '/juventud':         (context) => const JuventudScreen(),
        '/adultez':          (context) => const AdultezScreen(),
        '/vejez':            (context) => const VejezScreen(),
      },
    );
  }
}