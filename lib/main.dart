// lib/main.dart — DISPERSALUD IA
// Cambio respecto al original: ruta /auth agregada + splash va a /auth no a /pin
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/auth_screen.dart';           // ← NUEVO
import 'screens/main_screen.dart';
import 'screens/modulos/gestacion/gestacion_screen.dart';
import 'screens/modulos/primera_infancia/primera_infancia_screen.dart';
import 'screens/modulos/infancia/infancia_screen.dart';
import 'screens/modulos/adolescencia/adolescencia_screen.dart';
import 'screens/modulos/juventud/juventud_screen.dart';
import 'screens/modulos/adultez/adultez_screen.dart';
import 'screens/modulos/vejez/vejez_screen.dart';
import 'screens/nuevo_paciente_screen.dart';
import 'screens/pacientes_screen.dart';
import 'screens/alertas_screen.dart';
import 'screens/medicamentos_screen.dart';
import 'screens/historia_clinica_screen.dart';
import 'screens/reportar_alerta_screen.dart';
import 'screens/seguimiento_screen.dart';
import 'screens/partera_saberes/partera_saberes_screen.dart';
import 'screens/partera_screen.dart';
import 'screens/saberes_ancestrales_screen.dart';
import 'screens/especialistas/especialistas_screen.dart';
import 'services/security_service.dart';
import 'services/connectivity_service.dart';
import 'core/app_theme.dart';

final supabase        = Supabase.instance.client;
final temaNotifier    = ValueNotifier<ThemeMode>(ThemeMode.system);
final fontSizeNotifier = ValueNotifier<double>(1.0);

Future<void> _cargarTemaGuardado() async {
  final prefs    = await SharedPreferences.getInstance();
  final guardado = prefs.getString('tema_app') ?? 'Sistema';
  temaNotifier.value = temaDesdeString(guardado);
  final escala = prefs.getDouble('fuente_escala') ?? 1.0;
  fontSizeNotifier.value = escala.clamp(0.8, 1.4);
  _aplicarEstiloSistema(guardado);
  temaNotifier.addListener(() {
    final modo = temaNotifier.value;
    final nombre = modo == ThemeMode.light
        ? 'Claro'
        : modo == ThemeMode.dark ? 'Oscuro' : 'Sistema';
    _aplicarEstiloSistema(nombre);
  });
}

void _aplicarEstiloSistema(String tema) {
  final plataformaBrightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;
  final esClaro = tema == 'Claro' ||
      (tema == 'Sistema' && plataformaBrightness == Brightness.light);
  const kVerdeApp = Color(0xFF1D9E75);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor:                    esClaro ? kVerdeApp : const Color(0xFF0A0A0A),
    statusBarIconBrightness:           Brightness.light,
    statusBarBrightness:               Brightness.dark,
    systemNavigationBarColor:          esClaro ? Colors.white : const Color(0xFF101010),
    systemNavigationBarIconBrightness: esClaro ? Brightness.dark : Brightness.light,
    systemNavigationBarDividerColor:   Colors.transparent,
  ));
}

ThemeMode temaDesdeString(String s) {
  switch (s) {
    case 'Claro':  return ThemeMode.light;
    case 'Oscuro': return ThemeMode.dark;
    default:       return ThemeMode.system;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;

  await Supabase.initialize(
    url:     'https://whsipsmeqrlyfyyzagnk.supabase.co',
    anonKey: 'sb_publishable_gITtOddpPlSH7npmFbh5rw_KAQTrVCw',
  ).catchError((_) {});

  await Future.wait([
    SecurityService.instance.init().catchError((_) {}),
    _cargarTemaGuardado().catchError((_) {}),
  ]);

  ConnectivityService.instance.init().catchError((_) {});
  runApp(const DispersaludApp());
}

class DispersaludApp extends StatelessWidget {
  const DispersaludApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaNotifier,
      builder: (_, modo, __) => ValueListenableBuilder<double>(
        valueListenable: fontSizeNotifier,
        builder: (_, escala, __) => MaterialApp(
          title: 'DISPERSALUD IA',
          debugShowCheckedModeBanner: false,
          theme:     AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: modo,
          builder: (ctx, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: (Theme.of(ctx).brightness == Brightness.dark)
                ? const SystemUiOverlayStyle(
                    statusBarColor:                    Color(0xFF0A0A0A),
                    statusBarIconBrightness:           Brightness.light,
                    statusBarBrightness:               Brightness.dark,
                    systemNavigationBarColor:          Color(0xFF101010),
                    systemNavigationBarIconBrightness: Brightness.light,
                  )
                : const SystemUiOverlayStyle(
                    statusBarColor:                    Color(0xFF1D9E75),
                    statusBarIconBrightness:           Brightness.light,
                    statusBarBrightness:               Brightness.dark,
                    systemNavigationBarColor:          Colors.white,
                    systemNavigationBarIconBrightness: Brightness.dark,
                  ),
            child: MediaQuery(
              data: MediaQuery.of(ctx).copyWith(
                  textScaler: TextScaler.linear(escala)),
              child: child!,
            ),
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es', 'CO')],
          home: const SplashScreen(),
          routes: {
            // ── NUEVA ruta de autenticación ────────────────────────────────
            '/auth':             (_) => const AuthScreen(),
            // ── rutas existentes (sin cambios) ─────────────────────────────
            '/home':             (_) => const MainScreen(),
            '/gestacion':        (_) => const GestacionScreen(),
            '/primera-infancia': (_) => const PrimeraInfanciaScreen(),
            '/infancia':         (_) => const InfanciaScreen(),
            '/adolescencia':     (_) => const AdolescenciaScreen(),
            '/juventud':         (_) => const JuventudScreen(),
            '/adultez':          (_) => const AdultezScreen(),
            '/vejez':            (_) => const VejezScreen(),
            '/nuevo-paciente':   (_) => const NuevoPacienteScreen(),
            '/pacientes':        (_) => PacientesScreen(),
            '/alertas':          (_) => AlertasScreen(),
            '/medicamentos':     (_) => const MedicamentosScreen(),
            '/historia-clinica': (_) => const HistoriaClinicaScreen(),
            '/reportar-alerta':  (_) => const ReportarAlertaScreen(),
            '/seguimiento':      (_) => const SeguimientoScreen(),
            '/salud-integral':      (_) => const ParteraSaberesScreen(),
            '/partera':             (_) => const ParteraScreen(),
            '/saberes-ancestrales': (_) => const SaberesAncestalesScreen(),
            '/especialistas':       (_) => const EspecialistasScreen(),
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
        ),
      ),
    );
  }
}