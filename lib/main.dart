import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/main_screen.dart';
import 'screens/modulos/gestacion/gestacion_screen.dart';
import 'screens/modulos/primera_infancia/primera_infancia_screen.dart';
import 'screens/modulos/infancia/infancia_screen.dart';
import 'screens/modulos/adolescencia/adolescencia_screen.dart';
import 'screens/modulos/juventud/juventud_screen.dart';
import 'screens/modulos/adultez/adultez_screen.dart';
import 'screens/modulos/vejez/vejez_screen.dart';
import 'services/security_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecurityService.instance.init();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF111111),
    systemNavigationBarColor: Color(0xFF111111),
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const DispersaludApp());
}

class DispersaludApp extends StatelessWidget {
  const DispersaludApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DISPERSALUD IA',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'CO')],
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
      // ── La app arranca en el PIN, no en el Splash ──
      home: const SplashScreen(),
      routes: {
        '/pin':              (context) => const PinScreen(),
        '/home':             (context) => const MainScreen(),
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