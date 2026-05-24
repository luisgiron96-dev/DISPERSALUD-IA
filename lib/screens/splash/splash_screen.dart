import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset>  _textSlide;
  late Animation<double> _pulse;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack)
        .drive(Tween(begin: 0.5, end: 1.0));
    _logoFade  = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));

    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _textFade  = CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _textSlide = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: const Offset(0, 0.25), end: Offset.zero));

    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut)
        .drive(Tween(begin: 0.85, end: 1.15));

    _fadeCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _fadeOut = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn)
        .drive(Tween(begin: 1.0, end: 0.0));

    _iniciar();
  }

  Future<void> _iniciar() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 650));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 2400));
    await _fadeCtrl.forward();
    if (mounted) Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _fadeOut,
      builder: (_, child) => Opacity(opacity: _fadeOut.value, child: child),
      child: Scaffold(
        backgroundColor: const Color(0xFF50C8C8),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF7ED8D8), Color(0xFF3DAEAE)],
            ),
          ),
          child: Stack(
            children: [
              // ── Fondo decorativo ──────────────────────────────────
              Positioned.fill(child: CustomPaint(painter: _FondoPainter())),

              // ── Contenido centrado ────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Logo circular
                    AnimatedBuilder(
                      animation: _logoCtrl,
                      builder: (_, child) => FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(scale: _logoScale, child: child),
                      ),
                      child: Container(
                        width: size.width * 0.58,
                        height: size.width * 0.58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 32,
                              spreadRadius: 4,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo_dispersalud.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.06),

                    // Texto eslogan
                    AnimatedBuilder(
                      animation: _textCtrl,
                      builder: (_, child) => FadeTransition(
                        opacity: _textFade,
                        child: SlideTransition(position: _textSlide, child: child),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
                        child: const Text(
                          'Tecnología que cuida tu salud,\ndonde más se necesita.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color.fromARGB(255, 248, 250, 250),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),

                    
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Fondo con cruces y hexágonos ─────────────────────────────────────────
class _FondoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final pos in [
      [0.07, 0.05], [0.88, 0.04], [0.04, 0.38],
      [0.94, 0.28], [0.05, 0.70], [0.92, 0.62],
      [0.17, 0.92], [0.82, 0.90], [0.50, 0.03],
    ]) {
      final x = size.width * pos[0];
      final y = size.height * pos[1];
      canvas.drawLine(Offset(x - 11, y), Offset(x + 11, y), p);
      canvas.drawLine(Offset(x, y - 11), Offset(x, y + 11), p);
    }

    for (final pos in [
      [0.79, 0.12], [0.07, 0.52], [0.88, 0.76],
      [0.21, 0.76], [0.61, 0.95], [0.36, 0.08],
      [0.72, 0.48],
    ]) {
      _hex(canvas, p, Offset(size.width * pos[0], size.height * pos[1]), 22);
    }

    // ECG línea abajo
    final ecg = Paint()
      ..color = Colors.white.withOpacity(0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final path = Path();
    final y = size.height * 0.93;
    path.moveTo(0, y);
    path.lineTo(size.width * 0.22, y);
    path.lineTo(size.width * 0.27, y - 14);
    path.lineTo(size.width * 0.30, y + 24);
    path.lineTo(size.width * 0.34, y - 34);
    path.lineTo(size.width * 0.38, y + 12);
    path.lineTo(size.width * 0.43, y);
    path.lineTo(size.width, y);
    canvas.drawPath(path, ecg);
  }

  void _hex(Canvas canvas, Paint p, Offset c, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = math.pi / 180 * (60 * i - 30);
      final x = c.dx + r * math.cos(a);
      final y = c.dy + r * math.sin(a);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_) => false;
}