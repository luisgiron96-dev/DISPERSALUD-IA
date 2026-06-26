// lib/screens/auth/auth_screen.dart
// ============================================================
//  PANTALLA DE AUTENTICACIÓN — DISPERSALUD IA
//  Registro + Inicio de sesión con Supabase Auth
//  Reemplaza al PinScreen anterior.
// ============================================================
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_theme.dart';

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
  final _muniCtrl   = TextEditingController();

  late TabController _tab;

  bool _cargando    = false;
  bool _verPass     = false;
  String _error     = '';

  // Municipios del Cauca para el selector
  static const _municipiosCauca = [
    'Popayán', 'López de Micay', 'Timbiquí', 'Guapi',
    'Santander de Quilichao', 'Puerto Tejada', 'Corinto',
    'Miranda', 'Padilla', 'Buenos Aires', 'Suárez',
    'Morales', 'Piendamó', 'El Tambo', 'La Sierra',
    'Rosas', 'La Vega', 'Almaguer', 'Bolívar',
    'Mercaderes', 'Florencia', 'Otro',
  ];
  String _municipioSel = 'Popayán';

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
    _muniCtrl.dispose();
    super.dispose();
  }

  // ── LOGIN ──────────────────────────────────────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _cargando = true; _error = ''; });

    try {
      await _sb.auth.signInWithPassword(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on AuthException catch (e) {
      setState(() => _error = _traducirError(e.message));
    } catch (_) {
      setState(() => _error = 'Sin conexión. Verifica tu internet.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ── REGISTRO ───────────────────────────────────────────────
  Future<void> _registro() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _cargando = true; _error = ''; });

    try {
      final res = await _sb.auth.signUp(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
        data: {
          'nombre':    _nombreCtrl.text.trim(),
          'municipio': _municipioSel,
          'rol':       'promotor',
        },
      );

      // Guardar perfil en tabla promotores
      if (res.user != null) {
        await _sb.from('promotores').upsert({
          'id':        res.user!.id,
          'nombre':    _nombreCtrl.text.trim(),
          'email':     _emailCtrl.text.trim(),
          'municipio': _municipioSel,
          'rol':       'promotor',
          'activo':    true,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        // Si Supabase requiere confirmación de email
        if (res.session == null) {
          _mostrarDialogoConfirmacion();
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on AuthException catch (e) {
      setState(() => _error = _traducirError(e.message));
    } catch (_) {
      setState(() => _error = 'Sin conexión. Los datos se guardarán localmente.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ── RECUPERAR CONTRASEÑA ───────────────────────────────────
  Future<void> _recuperar() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Escribe tu correo primero');
      return;
    }
    try {
      await _sb.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📧 Revisa tu correo para recuperar la contraseña'),
            backgroundColor: Color(0xFF1D9E75),
          ),
        );
      }
    } catch (_) {
      setState(() => _error = 'No se pudo enviar el correo');
    }
  }

  void _mostrarDialogoConfirmacion() {
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
          'Te enviamos un correo a ${_emailCtrl.text.trim()}.\n\n'
          'Haz clic en el enlace para activar tu cuenta y luego inicia sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _tab.animateTo(0); // ir a login
            },
            child: const Text('Entendido', style: TextStyle(color: Color(0xFF1D9E75))),
          ),
        ],
      ),
    );
  }

  String _traducirError(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid login'))    return 'Correo o contraseña incorrectos';
    if (m.contains('email not confirmed')) return 'Confirma tu correo antes de entrar';
    if (m.contains('already registered')) return 'Este correo ya está registrado';
    if (m.contains('password'))         return 'La contraseña debe tener mínimo 6 caracteres';
    if (m.contains('rate limit'))       return 'Demasiados intentos. Espera un momento';
    return msg;
  }

  // ── UI ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final dark    = Theme.of(context).brightness == Brightness.dark;
    final verde   = const Color(0xFF1D9E75);
    final bgColor = dark ? const Color(0xFF0F1923) : const Color(0xFFF0F7F4);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Logo / Header ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: verde.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.health_and_safety_rounded,
                    size: 56, color: verde),
              ),
              const SizedBox(height: 14),
              Text('DISPERSALUD IA',
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

              // ── Tabs Login / Registro ──────────────────────
              Container(
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF1C2A35) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // TabBar
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF0F1923) : const Color(0xFFF0F7F4),
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
                        unselectedLabelColor: dark ? Colors.white54 : Colors.black45,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
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
                        child: SizedBox(
                          height: _tab.index == 0 ? 280 : 420,
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
                  ],
                ),
              ),

              // ── Error ──────────────────────────────────────
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE24B4A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE24B4A).withValues(alpha: 0.3)),
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

              const SizedBox(height: 24),

              // ── Modo offline ───────────────────────────────
              TextButton.icon(
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                icon: Icon(Icons.wifi_off_rounded,
                    size: 16, color: dark ? Colors.white38 : Colors.black38),
                label: Text('Continuar sin internet (modo local)',
                    style: TextStyle(
                      fontSize: 12,
                      color: dark ? Colors.white38 : Colors.black38,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── FORM LOGIN ─────────────────────────────────────────────
  Widget _formLogin(Color verde, bool dark) {
    return Column(
      children: [
        const SizedBox(height: 12),
        _campo(
          ctrl: _emailCtrl,
          label: 'Correo electrónico',
          icono: Icons.email_outlined,
          teclado: TextInputType.emailAddress,
          validator: (v) => (v == null || !v.contains('@'))
              ? 'Escribe un correo válido' : null,
        ),
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
        _botonPrincipal('Iniciar sesión', Icons.login_rounded, verde, _login),
      ],
    );
  }

  // ── FORM REGISTRO ──────────────────────────────────────────
  Widget _formRegistro(Color verde, bool dark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          _campo(
            ctrl: _nombreCtrl,
            label: 'Nombre completo',
            icono: Icons.person_outline_rounded,
            validator: (v) => (v == null || v.trim().length < 3)
                ? 'Escribe tu nombre completo' : null,
          ),
          const SizedBox(height: 14),
          _campo(
            ctrl: _emailCtrl,
            label: 'Correo electrónico',
            icono: Icons.email_outlined,
            teclado: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@'))
                ? 'Escribe un correo válido' : null,
          ),
          const SizedBox(height: 14),
          _campoPass(),
          const SizedBox(height: 14),
          // Selector de municipio
          DropdownButtonFormField<String>(
            value: _municipioSel,
            decoration: InputDecoration(
              labelText: 'Municipio del Cauca',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            items: _municipiosCauca.map((m) =>
                DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _municipioSel = v!),
          ),
          const SizedBox(height: 18),
          _botonPrincipal('Crear cuenta', Icons.person_add_rounded, verde, _registro),
        ],
      ),
    );
  }

  // ── WIDGETS REUTILIZABLES ──────────────────────────────────
  Widget _campo({
    required TextEditingController ctrl,
    required String label,
    required IconData icono,
    TextInputType teclado = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: teclado,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _campoPass() {
    return TextFormField(
      controller:  _passCtrl,
      obscureText: !_verPass,
      validator:   (v) => (v == null || v.length < 6)
          ? 'Mínimo 6 caracteres' : null,
      decoration: InputDecoration(
        labelText:   'Contraseña',
        prefixIcon:  const Icon(Icons.lock_outline_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(_verPass
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined),
          onPressed: () => setState(() => _verPass = !_verPass),
        ),
      ),
    );
  }

  Widget _botonPrincipal(
      String texto, IconData icono, Color verde, VoidCallback onTap) {
    return SizedBox(
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
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: verde,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
    );
  }
}