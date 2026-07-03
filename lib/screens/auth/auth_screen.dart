// lib/screens/auth/auth_screen.dart
// ════════════════════════════════════════════════════════════════════════════
//  DISPERSALUD IA — Pantalla de Autenticación
//  Registro + Inicio de sesión con Supabase Auth
//  Al registrarse: guarda nombre/municipio en SharedPreferences
//  para que aparezca en toda la app (perfil, partera, pin, etc.)
// ════════════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {

  final _sb         = Supabase.instance.client;
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  late TabController _tab;

  bool   _cargando = false;
  bool   _verPass  = false;
  String _error    = '';
  String _municipioSel = 'Popayán';
  String _rolSel       = 'Promotor/a de salud';

  static const _municipios = [
    'Popayán', 'López de Micay', 'Timbiquí', 'Guapi',
    'Santander de Quilichao', 'Puerto Tejada', 'Corinto',
    'Miranda', 'Padilla', 'Buenos Aires', 'Suárez',
    'Morales', 'Piendamó', 'El Tambo', 'La Sierra',
    'Rosas', 'La Vega', 'Almaguer', 'Bolívar',
    'Mercaderes', 'Florencia', 'Pueblo Nasa', 'Otro',
  ];

  static const _roles = [
    'Promotor/a de salud',
    'Sabedora / Partera',
    'Médico/a',
    'Enfermera/o',
    'Auxiliar de salud',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() => _error = ''));
  }

  @override
  void dispose() {
    _tab.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  // ── Guardar datos del promotor en local (SharedPreferences) ───────────────
  Future<void> _guardarPerfilLocal({
    required String nombre,
    required String email,
    required String municipio,
    required String rol,
    String telefono = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('promotor_nombre',    nombre);
    await prefs.setString('promotor_correo',    email);
    await prefs.setString('promotor_municipio', municipio);
    await prefs.setString('promotor_rol',       rol);
    await prefs.setString('promotor_telefono',  telefono);
    // Estos los usa pin_screen para el saludo y config_screen para el perfil
  }

  // ── LOGIN ──────────────────────────────────────────────────────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _cargando = true; _error = ''; });

    try {
      final res = await _sb.auth.signInWithPassword(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      // Al hacer login, recuperar datos del perfil desde Supabase y guardarlos local
      if (res.user != null) {
        try {
          final perfil = await _sb
              .from('promotores')
              .select()
              .eq('id', res.user!.id)
              .maybeSingle();
          if (perfil != null) {
            await _guardarPerfilLocal(
              nombre:    perfil['nombre']    ?? '',
              email:     perfil['email']     ?? res.user!.email ?? '',
              municipio: perfil['municipio'] ?? '',
              rol:       perfil['rol']       ?? '',
              telefono:  perfil['telefono']  ?? '',
            );
          }
        } catch (_) {
          // Si no hay internet, sigue con datos que ya tenga en local
        }
      }

      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on AuthException catch (e) {
      setState(() => _error = _traducir(e.message));
    } catch (_) {
      setState(() => _error = 'Sin conexión. Verifica tu internet.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ── REGISTRO ───────────────────────────────────────────────────────────────
  Future<void> _registro() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _cargando = true; _error = ''; });

    final nombre    = _nombreCtrl.text.trim();
    final email     = _emailCtrl.text.trim();
    final telefono  = _telefonoCtrl.text.trim();

    try {
      final res = await _sb.auth.signUp(
        email:    email,
        password: _passCtrl.text,
        data: {
          'nombre':    nombre,
          'municipio': _municipioSel,
          'rol':       _rolSel,
        },
      );

      // Guardar en tabla promotores de Supabase
      if (res.user != null) {
        await _sb.from('promotores').upsert({
          'id':         res.user!.id,
          'nombre':     nombre,
          'email':      email,
          'municipio':  _municipioSel,
          'rol':        _rolSel,
          'telefono':   telefono,
          'activo':     true,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Guardar localmente para que aparezca en toda la app de inmediato
      await _guardarPerfilLocal(
        nombre:    nombre,
        email:     email,
        municipio: _municipioSel,
        rol:       _rolSel,
        telefono:  telefono,
      );

      if (mounted) {
        if (res.session == null) {
          _dialogo_confirmacion(email);
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on AuthException catch (e) {
      setState(() => _error = _traducir(e.message));
    } catch (_) {
      // Sin internet: guardar solo local y entrar
      await _guardarPerfilLocal(
        nombre:    nombre,
        email:     email,
        municipio: _municipioSel,
        rol:       _rolSel,
        telefono:  telefono,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ── RECUPERAR CONTRASEÑA ───────────────────────────────────────────────────
  Future<void> _recuperar() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Escribe tu correo primero');
      return;
    }
    try {
      await _sb.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('📧 Revisa tu correo para recuperar la contraseña'),
          backgroundColor: Color(0xFF1D9E75),
        ));
      }
    } catch (_) {
      setState(() => _error = 'No se pudo enviar el correo');
    }
  }

  void _dialogo_confirmacion(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.mark_email_read_rounded, color: Color(0xFF1D9E75)),
          SizedBox(width: 10),
          Text('Confirma tu correo'),
        ]),
        content: Text(
          'Te enviamos un correo a $email.\n\n'
          'Haz clic en el enlace para activar tu cuenta y luego inicia sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _tab.animateTo(0);
            },
            child: const Text('Entendido',
                style: TextStyle(color: Color(0xFF1D9E75))),
          ),
        ],
      ),
    );
  }

  String _traducir(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid login'))       return 'Correo o contraseña incorrectos';
    if (m.contains('email not confirmed')) return 'Confirma tu correo antes de entrar';
    if (m.contains('already registered')) return 'Este correo ya está registrado';
    if (m.contains('password'))           return 'La contraseña debe tener mínimo 6 caracteres';
    if (m.contains('rate limit'))         return 'Demasiados intentos. Espera un momento';
    return msg;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    const verde   = Color(0xFF1D9E75);
    final dark    = Theme.of(context).brightness == Brightness.dark;
    final bgColor = dark ? const Color(0xFF0F1923) : const Color(0xFFF0F7F4);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(children: [
            const SizedBox(height: 24),

            // ── Logo ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: verde.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset('assets/logo_dispersalud.png',
                    width: 64, height: 64, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 14),
            const Text('DISPERSALUD IA',
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900,
                  color: verde, letterSpacing: 1.2,
                )),
            const SizedBox(height: 4),
            Text('Salud rural inteligente — Cauca, Colombia',
                style: TextStyle(
                  fontSize: 12,
                  color: dark ? Colors.white54 : Colors.black45,
                )),
            const SizedBox(height: 28),

            // ── Card con tabs Login / Registro ─────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1C2A35) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20, offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(children: [
                // TabBar
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF0F1923)
                        : const Color(0xFFF0F7F4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    controller: _tab,
                    indicator: BoxDecoration(
                      color: verde,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor:
                        dark ? Colors.white54 : Colors.black45,
                    labelStyle:
                        const TextStyle(fontWeight: FontWeight.w700),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Iniciar sesión'),
                      Tab(text: 'Registrarse'),
                    ],
                  ),
                ),

                // Forms
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Form(
                    key: _formKey,
                    child: AnimatedBuilder(
                      animation: _tab,
                      builder: (_, __) => AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: SizedBox(
                          height: _tab.index == 0 ? 290 : 490,
                          child: TabBarView(
                            controller: _tab,
                            children: [
                              _formLogin(verde, dark),
                              _formRegistro(verde, dark),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),

            // ── Error ──────────────────────────────────────────────────────
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE24B4A).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFE24B4A).withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFE24B4A), size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error,
                      style: const TextStyle(
                          color: Color(0xFFE24B4A), fontSize: 13))),
                ]),
              ),
            ],

            const SizedBox(height: 20),

            // ── Modo offline ───────────────────────────────────────────────
            TextButton.icon(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/home'),
              icon: Icon(Icons.wifi_off_rounded,
                  size: 16,
                  color: dark ? Colors.white38 : Colors.black38),
              label: Text('Continuar sin internet (modo local)',
                  style: TextStyle(
                    fontSize: 12,
                    color: dark ? Colors.white38 : Colors.black38,
                  )),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  // ── FORM LOGIN ─────────────────────────────────────────────────────────────
  Widget _formLogin(Color verde, bool dark) => Column(children: [
    const SizedBox(height: 12),
    _campo(ctrl: _emailCtrl, label: 'Correo electrónico',
        icono: Icons.email_outlined,
        teclado: TextInputType.emailAddress,
        validator: (v) =>
            (v == null || !v.contains('@')) ? 'Correo inválido' : null),
    const SizedBox(height: 14),
    _campoPass(),
    const SizedBox(height: 6),
    Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _recuperar,
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: Text('¿Olvidaste tu contraseña?',
            style: TextStyle(fontSize: 12, color: verde)),
      ),
    ),
    const SizedBox(height: 10),
    _boton('Iniciar sesión', Icons.login_rounded, verde, _login),
  ]);

  // ── FORM REGISTRO ──────────────────────────────────────────────────────────
  Widget _formRegistro(Color verde, bool dark) => SingleChildScrollView(
    child: Column(children: [
      const SizedBox(height: 12),

      // Nombre completo
      _campo(ctrl: _nombreCtrl, label: 'Nombre completo',
          icono: Icons.person_outline_rounded,
          validator: (v) => (v == null || v.trim().length < 3)
              ? 'Escribe tu nombre completo' : null),
      const SizedBox(height: 14),

      // Correo
      _campo(ctrl: _emailCtrl, label: 'Correo electrónico',
          icono: Icons.email_outlined,
          teclado: TextInputType.emailAddress,
          validator: (v) =>
              (v == null || !v.contains('@')) ? 'Correo inválido' : null),
      const SizedBox(height: 14),

      // Contraseña
      _campoPass(),
      const SizedBox(height: 14),

      // Teléfono (opcional)
      _campo(ctrl: _telefonoCtrl, label: 'Teléfono (opcional)',
          icono: Icons.phone_outlined,
          teclado: TextInputType.phone),
      const SizedBox(height: 14),

      // Rol
      DropdownButtonFormField<String>(
        value: _rolSel,
        decoration: InputDecoration(
          labelText: 'Rol en salud',
          prefixIcon: const Icon(Icons.badge_outlined),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
        ),
        items: _roles.map((r) =>
            DropdownMenuItem(value: r, child: Text(r))).toList(),
        onChanged: (v) => setState(() => _rolSel = v!),
      ),
      const SizedBox(height: 14),

      // Municipio
      DropdownButtonFormField<String>(
        value: _municipioSel,
        decoration: InputDecoration(
          labelText: 'Municipio (Cauca)',
          prefixIcon: const Icon(Icons.location_on_outlined),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
        ),
        items: _municipios.map((m) =>
            DropdownMenuItem(value: m, child: Text(m))).toList(),
        onChanged: (v) => setState(() => _municipioSel = v!),
      ),
      const SizedBox(height: 20),

      _boton('Crear cuenta', Icons.person_add_rounded, verde, _registro),
    ]),
  );

  // ── HELPERS ────────────────────────────────────────────────────────────────
  Widget _campo({
    required TextEditingController ctrl,
    required String label,
    required IconData icono,
    TextInputType teclado = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: teclado,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icono),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      );

  Widget _campoPass() => TextFormField(
    controller: _passCtrl,
    obscureText: !_verPass,
    validator: (v) =>
        (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
    decoration: InputDecoration(
      labelText: 'Contraseña',
      prefixIcon: const Icon(Icons.lock_outline_rounded),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      suffixIcon: IconButton(
        icon: Icon(_verPass
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined),
        onPressed: () => setState(() => _verPass = !_verPass),
      ),
    ),
  );

  Widget _boton(
      String texto, IconData icono, Color verde, VoidCallback onTap) =>
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _cargando ? null : onTap,
          icon: _cargando
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Icon(icono, size: 20),
          label: Text(texto,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: verde,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
        ),
      );
}