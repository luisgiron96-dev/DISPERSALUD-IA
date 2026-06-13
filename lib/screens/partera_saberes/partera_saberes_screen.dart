import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../../database/database_helper.dart';
import '../../services/ia_service.dart';
import '../../services/connectivity_service.dart';
import '../saberes_ancestrales_screen.dart';
import '../partera_screen.dart';

// ════════════════════════════════════════════════════════════════════════════
//  partera_saberes_screen.dart — DISPERSALUD IA
//  Fusión de Partera + Saberes Ancestrales en un TabBar unificado
// ════════════════════════════════════════════════════════════════════════════

// ── Colores ──────────────────────────────────────────────────────────────────
const _kVerde       = Color(0xFF1D9E75);
const _kVerdeBI     = Color(0xFF2ECC71);  // verde brillante saberes
const _kVerdeOsc    = Color(0xFF1A7A42);
const _kRosa        = Color(0xFF993556);
const _kMorado      = Color(0xFF534AB7);
const _kMoradoClaro = Color(0xFF9B6FCF);
const _kNaranja     = Color(0xFFEF9F27);
const _kRojo        = Color(0xFFE24B4A);

// Fondo/card estilo ancestral
const _kFondoA  = Color(0xFF0D1A0F);
const _kCardA   = Color(0xFF132015);
const _kBorderA = Color(0xFF2A3D2C);
const _kTextoA  = Color(0xFFE8F5E9);
const _kTextoSA = Color(0xFFB2DFDB);
const _kTextoHA = Color(0xFF7AAB84);

DispersaludColors _dc(BuildContext ctx) =>
    Theme.of(ctx).extension<DispersaludColors>() ?? DispersaludColors.dark;

// ════════════════════════════════════════════════════════════════════════════
//  PANTALLA RAÍZ CON TABBAR
// ════════════════════════════════════════════════════════════════════════════
class ParteraSaberesScreen extends StatefulWidget {
  const ParteraSaberesScreen({super.key});
  @override
  State<ParteraSaberesScreen> createState() => _ParteraSaberesScreenState();
}

class _ParteraSaberesScreenState extends State<ParteraSaberesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _online = false;
  StreamSubscription<bool>? _connSub;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _initConn();
  }

  Future<void> _initConn() async {
    _online = await ConnectivityService.instance.verificarAhora();
    if (mounted) setState(() {});
    _connSub = ConnectivityService.instance.cambios.listen((v) {
      if (mounted) setState(() => _online = v);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _connSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dc = _dc(context);
    return Scaffold(
      backgroundColor: dc.bg,
      body: SafeArea(
        child: Column(children: [

          // ── HEADER UNIFICADO ────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2D0A1A), Color(0xFF0D1A0F)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(children: [
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Salud Integral',
                      style: TextStyle(color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Partera + Saberes Ancestrales',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 11)),
                ])),
                // Badge online/offline
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: (_online ? _kVerde : _kRojo).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _online ? _kVerde : _kRojo,
                        width: 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6,
                        decoration: BoxDecoration(
                            color: _online ? _kVerde : _kRojo,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(_online ? 'En línea' : 'Offline',
                        style: TextStyle(
                            color: _online ? _kVerde : _kRojo,
                            fontSize: 10, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),

              // ── TABS ──────────────────────────────────────────────────────
              TabBar(
                controller: _tabCtrl,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kRosa, _kMorado],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.favorite_rounded, size: 18),
                    text: 'Partera',
                    iconMargin: EdgeInsets.only(bottom: 2),
                  ),
                  Tab(
                    icon: Icon(Icons.eco_rounded, size: 18),
                    text: 'Saberes Ancestrales',
                    iconMargin: EdgeInsets.only(bottom: 2),
                  ),
                ],
              ),
            ]),
          ),

          // ── CONTENIDO DE TABS ────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: const [
                _ParteraTab(),
                _SaberesTab(),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  TAB 1 — PARTERA (usa pantalla original con diseño completo)
// ════════════════════════════════════════════════════════════════════════════
class _ParteraTab extends StatelessWidget {
  const _ParteraTab();

  @override
  Widget build(BuildContext context) {
    return const ParteraScreen();
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  TAB 2 — SABERES ANCESTRALES (usa pantalla original con diseño completo)
// ════════════════════════════════════════════════════════════════════════════
class _SaberesTab extends StatelessWidget {
  const _SaberesTab();

  @override
  Widget build(BuildContext context) {
    // Usa la pantalla original directamente para mantener su diseño selvático
    // El Navigator.pop() del AppBar original no afecta porque el TabBar
    // no tiene su propio route en el stack
    return const SaberesAncestalesScreen();
  }
}
