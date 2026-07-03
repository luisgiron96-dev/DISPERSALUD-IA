import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

// ── Acceso global a Supabase desde cualquier archivo ────────────────────────
final supabase = Supabase.instance.client;

final temaNotifier     = ValueNotifier<ThemeMode>(ThemeMode.system);
final fontSizeNotifier = ValueNotifier<double>(1.0);

Future<void> _cargarTemaGuardado() async {
  final prefs    = await SharedPreferences.getInstance();
  final guardado = prefs.getString('tema_app') ?? 'Sistema';
  temaNotifier.value = temaDesdeString(guardado);
  final escala = prefs.getDouble('fuente_escala') ?? 1.0;
  fontSizeNotifier.value = escala.clamp(0.8, 1.4);

  // Aplicar estilo de barra de estado desde el arranque
  _aplicarEstiloSistema(guardado);

  // Escuchar cambios de tema para actualizar la barra siempre
  temaNotifier.addListener(() {
    final modo = temaNotifier.value;
    final nombre = modo == ThemeMode.light
        ? 'Claro'
        : modo == ThemeMode.dark
            ? 'Oscuro'
            : 'Sistema';
    _aplicarEstiloSistema(nombre);
  });
}

/// Actualiza statusBar + navigationBar según el tema elegido
void _aplicarEstiloSistema(String tema) {
  final plataformaBrightness = WidgetsBinding
      .instance.platformDispatcher.platformBrightness;
  final esClaro = tema == 'Claro' ||
      (tema == 'Sistema' && plataformaBrightness == Brightness.light);

  // En modo claro: barra de estado verde aguamarina de DISPERSALUD
  // En modo oscuro: barra de estado negra
  // NUNCA transparent — así no depende de qué haya debajo durante la transición
  const kVerdeApp = Color(0xFF1D9E75);

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    // Status bar (hora, wifi, batería)
    statusBarColor:          esClaro ? kVerdeApp : const Color(0xFF0A0A0A),
    statusBarIconBrightness: Brightness.light, // íconos siempre blancos (se ven sobre verde Y sobre negro)
    statusBarBrightness:     Brightness.dark,  // iOS equivalente
    // Navigation bar inferior (botones del sistema)
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

  // ── Inicializar SQLite para web ──────────────────────────────────────────
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // ── Inicializar Supabase ─────────────────────────────────────────────────
  await Supabase.initialize(
    url:     'https://whsipsmeqrlyfyyzagnk.supabase.co',
    anonKey: 'sb_publishable_gITtOddpPlSH7npmFbh5rw_KAQTrVCw',
  ).catchError((_) {});
  // Si no hay internet al arrancar, la app sigue funcionando en modo local

  // ── Servicios locales ────────────────────────────────────────────────────
  await Future.wait([
    SecurityService.instance.init().catchError((_) {}),
    _cargarTemaGuardado().catchError((_) {}),
  ]);

  // ConnectivityService se inicia en background — no bloquea el arranque
  ConnectivityService.instance.init().catchError((_) {});

  runApp(const DispersaludApp());

  if (kIsWeb) {
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }
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
                    statusBarColor:                    Color(0xFF1D9E75), // verde DISPERSALUD
                    statusBarIconBrightness:           Brightness.light,  // íconos blancos sobre verde
                    statusBarBrightness:               Brightness.dark,
                    systemNavigationBarColor:          Colors.white,
                    systemNavigationBarIconBrightness: Brightness.dark,
                  ),
            child: MediaQuery(
              data: MediaQuery.of(ctx).copyWith(
                textScaler: TextScaler.linear(escala),
              ),
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
            '/pin':              (context) => const PinScreen(),
            '/home':             (context) => const MainScreen(),
            '/gestacion':        (context) => const GestacionScreen(),
            '/primera-infancia': (context) => const PrimeraInfanciaScreen(),
            '/infancia':         (context) => const InfanciaScreen(),
            '/adolescencia':     (context) => const AdolescenciaScreen(),
            '/juventud':         (context) => const JuventudScreen(),
            '/adultez':          (context) => const AdultezScreen(),
            '/vejez':            (context) => const VejezScreen(),
            '/nuevo-paciente':   (context) => const NuevoPacienteScreen(),
            '/pacientes':        (context) => PacientesScreen(),
            '/alertas':          (context) => AlertasScreen(),
            '/medicamentos':     (context) => const MedicamentosScreen(),
            '/historia-clinica': (context) => const HistoriaClinicaScreen(),
            '/reportar-alerta':  (context) => const ReportarAlertaScreen(),
            '/seguimiento':      (context) => const SeguimientoScreen(),
            '/salud-integral':      (context) => const ParteraSaberesScreen(),
            '/partera':             (context) => const ParteraScreen(),
            '/saberes-ancestrales': (context) => const SaberesAncestalesScreen(),
            '/especialistas':       (context) => const EspecialistasScreen(),
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