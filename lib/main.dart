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
import 'core/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecurityService.instance.init();

  // La barra de estado se adapta al tema del sistema automáticamente
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
      // ── Tema adaptativo según el sistema ──────────────────────────────
      theme:      AppTheme.light,
      darkTheme:  AppTheme.dark,
      themeMode:  ThemeMode.system,
      // ── La app arranca en el PIN, no en el Splash ──
      home: Builder(builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          ),
          child: const PinScreen(),
        );
      }),
      routes: {
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