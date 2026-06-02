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
// ── Pantallas nuevas ──────────────────────────────────────────────────
import 'screens/nuevo_paciente_screen.dart';
import 'screens/pacientes_screen.dart';
import 'screens/alertas_screen.dart';
import 'screens/medicamentos_screen.dart';
import 'screens/historia_clinica_screen.dart';
import 'screens/historia_clinica_screen.dart';
// ─────────────────────────────────────────────────────────────────────
import 'services/security_service.dart';
import 'services/connectivity_service.dart';
import 'core/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecurityService.instance.init();
  await ConnectivityService.instance.init();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:           Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness:  Brightness.light,
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
      theme:     AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'CO')],
      home: const SplashScreen(),
      routes: {
        '/pin':              (context) => const PinScreen(),
        '/home':             (context) => const MainScreen(),
        // ── Módulos ciclo vital ──────────────────────────────────────
        '/gestacion':        (context) => const GestacionScreen(),
        '/primera-infancia': (context) => const PrimeraInfanciaScreen(),
        '/infancia':         (context) => const InfanciaScreen(),
        '/adolescencia':     (context) => const AdolescenciaScreen(),
        '/juventud':         (context) => const JuventudScreen(),
        '/adultez':          (context) => const AdultezScreen(),
        '/vejez':            (context) => const VejezScreen(),
        // ── Acciones rápidas ─────────────────────────────────────────
        '/nuevo-paciente':   (context) => const NuevoPacienteScreen(),
        '/pacientes':        (context) => PacientesScreen(),
        '/alertas':          (context) => AlertasScreen(),
        '/medicamentos':     (context) => const MedicamentosScreen(),
        '/historia-clinica': (context) => const HistoriaClinicaScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/historia-clinica') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => HistoriaClinicaScreen(
              pacienteId:     args['pacienteId']     as int,
              nombrePaciente: args['nombrePaciente'] as String,
            ),
          );
        }
        return null;
      },
    );
  }
}