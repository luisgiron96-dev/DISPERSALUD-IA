import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../core/app_theme.dart';
import '../core/responsive.dart';

const Color _kVerde = Color(0xFF1D9E75);

// ════════════════════════════════════════════════════════════════════
// EPS — Régimen contributivo, subsidiado y no asegurado
// ════════════════════════════════════════════════════════════════════
const List<String> _kEps = [
  // ── Contributivo ─────────────────────────────────────────────────
  'Acemi',
  'Aliansalud EPS',
  'Asociación Mutual Ser',
  'Capital Salud EPS-S',
  'Comfenalco Valle',
  'Compensar EPS',
  'Cooperativa de Salud Comunitaria - Coosalud',
  'Cruz Blanca EPS',
  'EPS Familiar de Colombia',
  'EPS Sanitas',
  'EPS SOS',
  'Famisanar EPS',
  'Medimás EPS',
  'Nueva EPS',
  'Pijaos Salud EPSI',
  'Salud Bolívar EPS SAS',
  'Salud Total EPS',
  'Salud Vida EPS',
  'Savia Salud EPS',
  'Servicio Occidental de Salud - SOS',
  'Suramericana EPS',
  'Unimec',
  // ── Subsidiado (SISBEN) ───────────────────────────────────────────
  'Régimen Subsidiado - Coosalud',
  'Régimen Subsidiado - Capital Salud',
  'Régimen Subsidiado - Cajacopi Atlántico',
  'Régimen Subsidiado - Comfacor',
  'Régimen Subsidiado - Comfaoriente',
  'Régimen Subsidiado - Comfasucre',
  'Régimen Subsidiado - Emdisalud',
  'Régimen Subsidiado - Emssanar',
  'Régimen Subsidiado - Mallamás',
  'Régimen Subsidiado - Mutual SER',
  'Régimen Subsidiado - Pijaos Salud',
  'Régimen Subsidiado - Salud Bolívar',
  'Régimen Subsidiado - Savia Salud',
  'Régimen Subsidiado - Solsalud',
  'Régimen Subsidiado - Anas Wayuu',
  'Régimen Subsidiado - Dusakawi',
  // ── Especiales / Excepción ────────────────────────────────────────
  'Magisterio (FOMAG)',
  'Fuerzas Militares (DGSM)',
  'Policía Nacional (SANIDAD)',
  'Ecopetrol (OCSF)',
  // ── Sin aseguramiento ─────────────────────────────────────────────
  'No asegurado (vinculado)',
  'En trámite de afiliación',
];

// ════════════════════════════════════════════════════════════════════
// COLOMBIA — Departamentos y sus municipios
// ════════════════════════════════════════════════════════════════════
const Map<String, List<String>> _kColombia = {
  'Amazonas': ['Leticia','Puerto Nariño','El Encanto','La Chorrera','La Pedrera','La Victoria','Mirití-Paraná','Puerto Alegría','Puerto Arica','Puerto Santander','Tarapacá'],
  'Antioquia': ['Medellín','Abejorral','Abriaquí','Alejandría','Amagá','Amalfi','Andes','Angelópolis','Angostura','Anorí','Anza','Apartadó','Arboletes','Argelia','Armenia','Barbosa','Bello','Betania','Betulia','Briceño','Buriticá','Cáceres','Caicedo','Caldas','Campamento','Cañasgordas','Caracolí','Carepa','Carolina del Príncipe','Caucasia','Chigorodó','Cisneros','Cocorná','Concepción','Concordia','Copacabana','Dabeiba','Don Matías','Ebéjico','El Bagre','El Carmen de Viboral','El Santuario','Entrerríos','Envigado','Fredonia','Frontino','Giraldo','Girardota','Gómez Plata','Granada','Guadalupe','Guarne','Guatapé','Heliconia','Hispania','Itagüí','Ituango','Jardín','Jericó','La Ceja','La Estrella','La Pintada','La Unión','Liborina','Maceo','Marinilla','Montebello','Murindó','Mutatá','Nariño','Nechí','Necoclí','Olaya','Peñol','Peque','Pueblorrico','Puerto Berrío','Puerto Nare','Puerto Triunfo','Remedios','Retiro','Rionegro','Sabanalarga','Sabaneta','Salgar','San Andrés de Cuerquia','San Carlos','San Francisco','San Jerónimo','San José de la Montaña','San Juan de Urabá','San Luis','San Pedro de los Milagros','San Pedro de Urabá','San Rafael','San Roque','San Vicente Ferrer','Santa Bárbara','Santa Fe de Antioquia','Santa Rosa de Osos','Santo Domingo','Segovia','Sonsón','Sopetrán','Támesis','Tarazá','Tarso','Titiribí','Toledo','Turbo','Uramita','Urrao','Valdivia','Valparaíso','Vegachí','Venecia','Vigía del Fuerte','Yalí','Yarumal','Yolombó','Yondó','Zaragoza'],
  'Arauca': ['Arauca','Arauquita','Cravo Norte','Fortul','Puerto Rondón','Saravena','Tame'],
  'Atlántico': ['Barranquilla','Baranoa','Campo de la Cruz','Candelaria','Galapa','Juan de Acosta','Luruaco','Malambo','Manatí','Palmar de Varela','Piojó','Polonuevo','Ponedera','Puerto Colombia','Repelón','Sabanagrande','Sabanalarga','Santa Lucía','Santo Tomás','Soledad','Suán','Tubará','Usiacurí'],
  'Bolívar': ['Cartagena','Achí','Altos del Rosario','Arenal','Arjona','Arroyohondo','Barranco de Loba','Calamar','Cantagallo','Cicuco','Clemencia','Córdoba','El Carmen de Bolívar','El Guamo','El Peñón','Hatillo de Loba','Magangué','Mahates','Margarita','María la Baja','Mompós','Montecristo','Morales','Norosí','Pinillos','Regidor','Río Viejo','San Cristóbal','San Estanislao','San Fernando','San Jacinto','San Jacinto del Cauca','San Juan Nepomuceno','San Martín de Loba','San Pablo','Santa Catalina','Santa Rosa','Santa Rosa del Sur','Simití','Soplaviento','Talaigua Nuevo','Tiquisio','Turbaco','Turbaná','Villanueva','Zambrano'],
  'Boyacá': ['Tunja','Almeida','Aquitania','Arcabuco','Belén','Berbeo','Betéitiva','Boavita','Boyacá','Briceño','Buenavista','Busbanzá','Caldas','Campohermoso','Cerinza','Chinavita','Chiquinquirá','Chíquiza','Chiscas','Chita','Chitaraque','Chivatá','Ciénega','Cómbita','Coper','Corrales','Covarachía','Cubará','Cucaita','Cuítiva','Duitama','El Cocuy','El Espino','Firavitoba','Floresta','Gachantivá','Gámeza','Garagoa','Guacamayas','Guateque','Guayatá','Güicán','Iza','Jenesano','Jericó','La Capilla','La Uvita','La Victoria','Labranzagrande','Macanal','Maripí','Miraflores','Mongua','Monguí','Moniquirá','Muzo','Nobsa','Nuevo Colón','Oicatá','Otanche','Pachavita','Páez','Paipa','Pajarito','Panqueba','Pauna','Paya','Paz de Río','Pesca','Pisba','Puerto Boyacá','Quípama','Ramiriquí','Ráquira','Rondón','Saboyá','Sáchica','Samacá','San Eduardo','San José de Pare','San Luis de Gaceno','San Mateo','San Miguel de Sema','San Pablo de Borbur','Santana','Santa María','Santa Rosa de Viterbo','Santa Sofía','Sativanorte','Sativasur','Siachoque','Soatá','Socotá','Socha','Sogamoso','Somondoco','Sora','Soracá','Sotaquirá','Susacón','Sutamarchán','Sutatenza','Tasco','Tenza','Tibaná','Tibasosa','Tinjacá','Tipacoque','Toca','Togüí','Tópaga','Tota','Tununguá','Turmequé','Tuta','Tutazá','Umbita','Ventaquemada','Villa de Leyva','Viracachá','Zetaquira'],
  'Caldas': ['Manizales','Aguadas','Anserma','Aranzazu','Belalcázar','Chinchiná','Filadelfia','La Dorada','La Merced','Manzanares','Marmato','Marquetalia','Marulanda','Neira','Norcasia','Pácora','Palestina','Pensilvania','Riosucio','Risaralda','Salamina','Samaná','San José','Supía','Victoria','Villamaría','Viterbo'],
  'Caquetá': ['Florencia','Albania','Belén de los Andaquíes','Cartagena del Chairá','Curillo','El Doncello','El Paujil','Milán','Morelia','Puerto Rico','San José del Fragua','San Vicente del Caguán','Solano','Solita','Valparaíso'],
  'Casanare': ['Yopal','Aguazul','Chámeza','Hato Corozal','La Salina','Maní','Monterrey','Nunchía','Orocué','Paz de Ariporo','Pore','Recetor','Sabanalarga','Sácama','San Luis de Palenque','Tauramena','Trinidad','Villanueva'],
  'Cauca': ['Popayán','Almaguer','Argelia','Balboa','Bolívar','Buenos Aires','Cajibío','Caldono','Caloto','Coconuco','Corinto','El Tambo','Florencia','Guachené','Guapi','Inzá','Jambaló','La Sierra','La Vega','López de Micay','Mercaderes','Miranda','Morales','Padilla','Páez','Patía','Piamonte','Piendamó','Puerto Tejada','Puracé','Rosas','San Sebastián','Santa Rosa','Santander de Quilichao','Silvia','Sotará','Sucre','Suárez','Timbío','Timbiquí','Toribío','Totoró','Villa Rica'],
  'Cesar': ['Valledupar','Aguachica','Agustín Codazzi','Astrea','Becerril','Bosconia','Chimichagua','Chiriguaná','Curumaní','El Copey','El Paso','Gamarra','González','La Gloria','La Jagua de Ibirico','La Paz','Manaure Balcón del Cesar','Pailitas','Pelaya','Pueblo Bello','Río de Oro','San Alberto','San Diego','San Martín','Tamalameque'],
  'Chocó': ['Quibdó','Acandí','Alto Baudó','Atrato','Bagadó','Bahía Solano','Bajo Baudó','Bojayá','Carmen del Darién','Cértegui','Condoto','El Carmen de Atrato','El Litoral del San Juan','Istmina','Juradó','Lloró','Medio Atrato','Medio Baudó','Medio San Juan','Nóvita','Nuquí','Río Iro','Río Quito','Riosucio','San José del Palmar','Sipí','Tadó','Unguía','Unión Panamericana'],
  'Córdoba': ['Montería','Ayapel','Buenavista','Canalete','Cereté','Chimá','Chinú','Ciénaga de Oro','Cotorra','La Apartada','Lorica','Los Córdobas','Momil','Montelíbano','Moñitos','Planeta Rica','Pueblo Nuevo','Puerto Escondido','Puerto Libertador','Purísima de la Concepción','Sahagún','San Andrés de Sotavento','San Antero','San Bernardo del Viento','San Carlos','San José de Uré','San Pelayo','Tierralta','Tuchín','Valencia'],
  'Cundinamarca': ['Bogotá D.C.','Agua de Dios','Albán','Anapoima','Anolaima','Apulo','Arbeláez','Beltrán','Bituima','Bogotá','Bojacá','Cabrera','Cachipay','Cajicá','Caparrapí','Cáqueza','Carmen de Carupa','Chaguaní','Chía','Chipaque','Choachí','Chocontá','Cogua','Cota','Cucunubá','El Colegio','El Peñón','El Rosal','Facatativá','Fómeque','Fosca','Funza','Fúquene','Fusagasugá','Gachalá','Gachancipá','Gachetá','Gama','Girardot','Granada','Guachetá','Guaduas','Guasca','Guataquí','Guatavita','Guayabal de Síquima','Guayabetal','Gutiérrez','Jerusalén','Junín','La Calera','La Mesa','La Palma','La Peña','La Vega','Lenguazaque','Macheta','Madrid','Manta','Medina','Mosquera','Nariño','Nemocón','Nilo','Nimaima','Nocaima','Venecia','Pacho','Paime','Pandi','Paratebueno','Pasca','Puerto Salgar','Pulí','Quebradanegra','Quetame','Quipile','Ricaurte','San Antonio del Tequendama','San Bernardo','San Cayetano','San Francisco','San Juan de Río Seco','Sasaima','Sesquilé','Sibaté','Silvania','Simijaca','Soacha','Sopó','Subachoque','Suesca','Supatá','Susa','Sutatausa','Tabio','Tausa','Tena','Tenjo','Tibacuy','Tibirita','Tocaima','Tocancipá','Topaipí','Ubalá','Ubaque','Une','Útica','Vergara','Vianí','Villa de San Diego de Ubate','Villagómez','Villapinzón','Villeta','Viotá','Yacopí','Zipacón','Zipaquirá'],
  'Guainía': ['Inírida','Barranco Minas','Cacahual','La Guadalupe','Mapiripana','Morichal Nuevo','Pana Pana','Puerto Colombia','San Felipe'],
  'Guaviare': ['San José del Guaviare','Calamar','El Retorno','Miraflores'],
  'Huila': ['Neiva','Acevedo','Agrado','Aipe','Algeciras','Altamira','Baraya','Campoalegre','Colombia','Elías','Garzón','Gigante','Guadalupe','Hobo','Iquira','Isnos','La Argentina','La Plata','Nátaga','Oporapa','Paicol','Palermo','Palestina','Pital','Pitalito','Rivera','Saladoblanco','San Agustín','Santa María','Suaza','Tarqui','Tesalia','Tello','Teruel','Timaná','Villavieja','Yaguará'],
  'La Guajira': ['Riohacha','Albania','Barrancas','Dibulla','Distracción','El Molino','Fonseca','Hatonuevo','La Jagua del Pilar','Maicao','Manaure','San Juan del Cesar','Uribia','Urumita','Villanueva'],
  'Magdalena': ['Santa Marta','Algarrobo','Aracataca','Ariguaní','Cerro de San Antonio','Chivolo','Ciénaga','Concordia','El Banco','El Piñón','El Retén','Fundación','Guamal','Nueva Granada','Pedraza','Pijiño del Carmen','Pivijay','Plato','Pueblo Viejo','Remolino','Sabanas de San Ángel','Salamina','San Sebastián de Buenavista','San Zenón','Santa Ana','Santa Bárbara de Pinto','Sitionuevo','Tenerife','Zapayán','Zona Bananera'],
  'Meta': ['Villavicencio','Acacías','Barranca de Upía','Cabuyaro','Castilla la Nueva','Cubarral','Cumaral','El Calvario','El Castillo','El Dorado','Fuente de Oro','Granada','Guamal','La Macarena','Lejanías','Mapiripán','Mesetas','La Uribe','Puerto Concordia','Puerto Gaitán','Puerto Lleras','Puerto López','Puerto Rico','Restrepo','San Carlos de Guaroa','San Juan de Arama','San Juanito','San Martín','Vistahermosa'],
  'Nariño': ['Pasto','Albán','Aldana','Ancuya','Arboleda','Barbacoas','Belén','Buesaco','Chachagüí','Colón','Consacá','Contadero','Córdoba','Cuaspud','Cumbal','Cumbitara','El Charco','El Peñol','El Rosario','El Tablón de Gómez','El Tambo','Francisco Pizarro','Funes','Guachucal','Guaitarilla','Gualmatán','Iles','Imués','Ipiales','La Cruz','La Florida','La Llanada','La Tola','La Unión','Leiva','Linares','Los Andes','Magüí Payán','Mallama','Mosquera','Nariño','Olaya Herrera','Ospina','Policarpa','Potosí','Providencia','Puerres','Pupiales','Ricaurte','Roberto Payán','Samaniego','San Bernardo','San Lorenzo','San Pablo','San Pedro de Cartago','Sandoná','Santa Bárbara','Santacruz','Sapuyes','Taminango','Tangua','Tumaco','Túquerres','Yacuanquer'],
  'Norte de Santander': ['Cúcuta','Abrego','Arboledas','Bochalema','Bucarasica','Cácota','Cachirá','Chinácota','Chitagá','Convención','Cucutilla','Durania','El Carmen','El Tarra','El Zulia','Gramalote','Hacarí','Herrán','La Esperanza','La Playa de Belén','Labateca','Los Patios','Lourdes','Mutiscua','Ocaña','Pamplona','Pamplonita','Puerto Santander','Ragonvalia','Salazar','San Calixto','San Cayetano','Santiago','Sardinata','Silos','Teorama','Tibú','Toledo','Villa Caro','Villa del Rosario'],
  'Putumayo': ['Mocoa','Colón','Orito','Puerto Asís','Puerto Caicedo','Puerto Guzmán','Puerto Leguízamo','San Francisco','San Miguel','Santiago','Sibundoy','Valle de Guamez','Villagarzón'],
  'Quindío': ['Armenia','Buenavista','Calarcá','Circasia','Córdoba','Filandia','Génova','La Tebaida','Montenegro','Pijao','Quimbaya','Salento'],
  'Risaralda': ['Pereira','Apía','Balboa','Belén de Umbría','Dosquebradas','Guática','La Celia','La Virginia','Marsella','Mistrató','Pueblo Rico','Quinchía','Santa Rosa de Cabal','Santuario'],
  'San Andrés y Providencia': ['San Andrés','Providencia y Santa Catalina'],
  'Santander': ['Bucaramanga','Aguada','Albania','Aratoca','Barbosa','Barichara','Barrancabermeja','Betulia','Bolívar','Cabrera','California','Capitanejo','Carcasí','Cepitá','Cerrito','Charalá','Charta','Chima','Chipatá','Cimitarra','Confines','Contratación','Coromoro','Curití','El Carmen de Chucurí','El Guacamayo','El Peñón','El Playón','Encino','Enciso','Florián','Floridablanca','Galán','Gámbita','Girón','Guaca','Guadalupe','Guapotá','Guavatá','Güepsa','Hato','Jesús María','La Belleza','La Paz','Landázuri','Lebríja','Los Santos','Macaravita','Málaga','Matanza','Mogotes','Molagavita','Ocamonte','Oiba','Onzaga','Palmar','Palmas del Socorro','Páramo','Piedecuesta','Pinchote','Puente Nacional','Puerto Parra','Puerto Wilches','Rionegro','Sabana de Torres','San Andrés','San Benito','San Gil','San Joaquín','San José de Miranda','San Miguel','San Vicente de Chucurí','Santa Bárbara','Santa Helena del Opón','Simacota','Socorro','Suaita','Sucre','Suratá','Tona','Valle de San José','Vélez','Vetas','Villanueva','Zapatoca'],
  'Sucre': ['Sincelejo','Buenavista','Caimito','Chalán','Colosó','Corozal','Coveñas','El Roble','Galeras','Guaranda','La Unión','Los Palmitos','Majagual','Morroa','Ovejas','Palmito','Sampués','San Benito Abad','San Juan de Betulia','San Marcos','San Onofre','San Pedro','San Luis de Sincé','Santiago de Tolú','Sincé','Sucre','Tolú Viejo'],
  'Tolima': ['Ibagué','Alpujarra','Alvarado','Ambalema','Anzoátegui','Armero-Guayabal','Ataco','Cajamarca','Carmen de Apicalá','Casabianca','Chaparral','Coello','Coyaima','Cunday','Dolores','Espinal','Falan','Flandes','Fresno','Guamo','Herveo','Honda','Icononzo','Lérida','Líbano','Mariquita','Melgar','Murillo','Natagaima','Ortega','Palocabildo','Piedras','Planadas','Prado','Purificación','Rioblanco','Roncesvalles','Rovira','Saldaña','San Antonio','San Luis','Santa Isabel','Suárez','Valle de San Juan','Venadillo','Villahermosa','Villarrica'],
  'Valle del Cauca': ['Cali','Alcalá','Andalucía','Ansermanuevo','Argelia','Bolívar','Buenaventura','Buga','Bugalagrande','Caicedonia','Calima','Candelaria','Cartago','Dagua','El Águila','El Cairo','El Cerrito','El Dovio','Florida','Ginebra','Guacarí','Jamundí','La Cumbre','La Unión','La Victoria','Obando','Palmira','Pradera','Restrepo','Riofrío','Roldanillo','San Pedro','Sevilla','Toro','Trujillo','Tuluá','Ulloa','Versalles','Vijes','Yotoco','Yumbo','Zarzal'],
  'Vaupés': ['Mitú','Carurú','Pacoa','Papunahua','Taraira','Yavaraté'],
  'Vichada': ['Puerto Carreño','Cumaribo','La Primavera','Santa Rosalía'],
};

// ════════════════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL
// ════════════════════════════════════════════════════════════════════
class NuevoPacienteScreen extends StatefulWidget {
  final Map<String, dynamic>? pacienteEditar;
  const NuevoPacienteScreen({super.key, this.pacienteEditar});
  @override
  State<NuevoPacienteScreen> createState() => _NuevoPacienteScreenState();
}

class _NuevoPacienteScreenState extends State<NuevoPacienteScreen> {
  final _nombreCtrl   = TextEditingController();
  final _docCtrl      = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  String  _sexo          = 'Femenino';
  String  _modulo        = 'Gestación';
  String? _departamento;
  String? _municipio;
  String? _vereda;
  String? _eps;
  DateTime? _fechaNac;
  bool    _guardando     = false;

  bool get _esEdicion => widget.pacienteEditar != null;
  int? get _idEdicion => widget.pacienteEditar?['id'] as int?;

  List<String> get _departamentos => _kColombia.keys.toList()..sort();
  List<String> get _municipios    => _departamento != null ? (_kColombia[_departamento] ?? []) : [];

  final List<String> _modulos = [
    'Gestación','Primera infancia','Infancia',
    'Adolescencia','Juventud','Adultez','Vejez',
  ];

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      final p = widget.pacienteEditar!;
      _nombreCtrl.text   = p['nombre']   ?? '';
      _docCtrl.text      = p['documento'] ?? '';
      _telefonoCtrl.text = p['telefono'] ?? '';
      _sexo   = (p['sexo']   as String?)?.isNotEmpty == true ? p['sexo']   : 'Femenino';
      _modulo = (p['modulo'] as String?)?.isNotEmpty == true ? p['modulo'] : 'Gestación';
      if (!_modulos.contains(_modulo))  _modulo = 'Gestación';
      if (!['Femenino','Masculino','Intersexual'].contains(_sexo)) _sexo = 'Femenino';

      // Ubicación
      final dep = p['departamento'] as String?;
      final mun = p['municipio']   as String?;
      final ver = p['vereda']      as String?;
      if (dep != null && _kColombia.containsKey(dep)) {
        _departamento = dep;
        if (mun != null && (_kColombia[dep]?.contains(mun) ?? false)) {
          _municipio = mun;
        }
      }
      _vereda = ver?.isNotEmpty == true ? ver : null;

      // EPS
      final eps = p['eps'] as String?;
      if (eps != null && _kEps.contains(eps)) _eps = eps;

      // Fecha
      final fn = p['fecha_nac'] as String?;
      if (fn != null && fn.isNotEmpty) {
        try {
          if (fn.contains('/')) {
            final parts = fn.split('/');
            _fechaNac = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          } else {
            _fechaNac = DateTime.parse(fn);
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _seleccionarFecha() async {
    final hoy    = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNac ?? DateTime(hoy.year - 25, hoy.month, hoy.day),
      firstDate: DateTime(1920), lastDate: hoy,
      locale: const Locale('es', 'CO'),
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar', confirmText: 'Aceptar',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: _kVerde,
            onPrimary: Colors.white,
            surface: Theme.of(context).extension<DispersaludColors>()!.card,
            onSurface: Theme.of(context).extension<DispersaludColors>()!.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaNac = picked);
  }

  String get _fechaTexto {
    if (_fechaNac == null) return 'Seleccionar fecha';
    return '${_fechaNac!.day.toString().padLeft(2,'0')}/${_fechaNac!.month.toString().padLeft(2,'0')}/${_fechaNac!.year}';
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('El nombre es obligatorio'),
        backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _guardando = true);
    final datos = {
      'nombre':       _nombreCtrl.text.trim(),
      'documento':    _docCtrl.text.trim(),
      'fecha_nac':    _fechaNac != null ? _fechaTexto : '',
      'sexo':         _sexo,
      'departamento': _departamento ?? '',
      'municipio':    _municipio   ?? '',
      'vereda':       _vereda      ?? '',
      'telefono':     _telefonoCtrl.text.trim(),
      'eps':          _eps         ?? '',
      'modulo':       _modulo,
    };
    // NOTA: agregamos try/catch + timeout a propósito. Antes, si
    // DatabaseHelper se quedaba esperando indefinidamente (por ejemplo,
    // si el motor de base de datos del navegador no llegó a inicializar
    // bien), el botón se quedaba en "Guardando..." para siempre sin
    // ningún mensaje de error. Ahora, después de 10 segundos sin
    // respuesta, se muestra el error real en pantalla y en la consola.
    try {
      if (_esEdicion) {
        await DatabaseHelper.instance
            .actualizarPaciente(_idEdicion!, datos)
            .timeout(const Duration(seconds: 10));
      } else {
        await DatabaseHelper.instance.insertarPaciente({
          ...datos, 'created_at': DateTime.now().toIso8601String(),
        }).timeout(const Duration(seconds: 10));
      }
    } catch (e, st) {
      debugPrint('⚠️ Error guardando paciente: $e');
      debugPrintStack(stackTrace: st);
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se pudo guardar: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    setState(() => _guardando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_esEdicion
            ? '${_nombreCtrl.text.trim()} actualizado correctamente ✓'
            : '${_nombreCtrl.text.trim()} registrado correctamente ✓'),
        backgroundColor: _kVerde, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    for (final c in [_nombreCtrl, _docCtrl, _telefonoCtrl]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dc    = Theme.of(context).extension<DispersaludColors>()!;
    final verde = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: dc.bg,
      appBar: AppBar(
        backgroundColor: dc.bg, foregroundColor: dc.textPrimary,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_esEdicion ? 'Editar paciente' : 'Nuevo paciente',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: dc.textPrimary)),
          Text(_esEdicion
              ? 'Modificar · ${widget.pacienteEditar!['nombre'] ?? ''}'
              : 'Registro local · sin internet',
              style: TextStyle(color: dc.textHint, fontSize: 12)),
        ]),
      ),
      body: ResponsiveCenter(maxWidth: 700, child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // ── Datos personales ────────────────────────────────────────
          _Card(titulo: '👤 Datos personales', child: Column(children: [
            _Campo(label: 'Nombre completo *', controller: _nombreCtrl),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _Campo(label: 'N.° documento', controller: _docCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _FechaCampo(
                label: 'Fecha de nacimiento',
                texto: _fechaTexto,
                onTap: _seleccionarFecha,
              )),
            ]),
            const SizedBox(height: 12),
            _DropField(
              label: 'Sexo biológico',
              value: _sexo,
              options: const ['Femenino','Masculino','Intersexual'],
              onChanged: (v) => setState(() => _sexo = v!),
            ),
            const SizedBox(height: 12),
            _DropBuscable(
              label: 'EPS / Aseguradora',
              hint: 'Seleccionar EPS...',
              value: _eps,
              options: _kEps,
              onChanged: (v) => setState(() => _eps = v),
            ),
          ])),
          const SizedBox(height: 14),

          // ── Ubicación ────────────────────────────────────────────────
          _Card(titulo: '📍 Ubicación — Colombia', child: Column(children: [
            _DropBuscable(
              label: 'Departamento',
              hint: 'Seleccionar departamento...',
              value: _departamento,
              options: _departamentos,
              onChanged: (v) => setState(() {
                _departamento = v;
                _municipio = null;
                _vereda    = null;
              }),
            ),
            const SizedBox(height: 12),
            _DropBuscable(
              label: 'Municipio',
              hint: _departamento == null ? 'Primero selecciona departamento' : 'Seleccionar municipio...',
              value: _municipio,
              options: _municipios,
              enabled: _departamento != null,
              onChanged: (v) => setState(() { _municipio = v; _vereda = null; }),
            ),
            const SizedBox(height: 12),
            _Campo(
              label: 'Vereda / Barrio',
              controller: TextEditingController(text: _vereda ?? '')
                ..addListener(() {}),
              hint: 'Ej: El Palmar, Barrio La Esperanza',
              onChanged: (v) => _vereda = v,
            ),
            const SizedBox(height: 12),
            _Campo(label: 'Teléfono / celular', controller: _telefonoCtrl, hint: 'Opcional'),
          ])),
          const SizedBox(height: 14),

          // ── Módulo ───────────────────────────────────────────────────
          _Card(titulo: '🏥 Módulo de atención', child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ciclo de vida principal del paciente',
                style: TextStyle(color: dc.textHint, fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: _modulos.map((m) {
              final sel = m == _modulo;
              return GestureDetector(
                onTap: () => setState(() => _modulo = m),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? verde : dc.border.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? verde : dc.border),
                  ),
                  child: Text(m, style: TextStyle(
                    color: sel ? Colors.white : dc.textSecondary,
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                ),
              );
            }).toList()),
          ])),
          const SizedBox(height: 20),

          // ── Botón guardar ─────────────────────────────────────────────
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(_esEdicion ? Icons.edit_outlined : Icons.save_outlined, color: Colors.white),
              label: Text(
                _guardando
                    ? (_esEdicion ? 'Actualizando...' : 'Guardando...')
                    : (_esEdicion ? 'Guardar cambios' : 'Registrar paciente'),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: verde,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ), ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ════════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final String titulo; final Widget child;
  const _Card({required this.titulo, required this.child});
  @override
  Widget build(BuildContext context) {
    final dc = Theme.of(context).extension<DispersaludColors>()!;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dc.card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dc.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: TextStyle(color: dc.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14), child,
      ]));
  }
}

class _Campo extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  const _Campo({required this.label, required this.controller, this.hint, this.onChanged});
  @override
  Widget build(BuildContext context) {
    final dc = Theme.of(context).extension<DispersaludColors>()!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: dc.textHint, fontSize: 11)),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: dc.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: dc.textHint, fontSize: 13),
          isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          filled: true, fillColor: dc.border.withOpacity(0.4),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
    ]);
  }
}

class _FechaCampo extends StatelessWidget {
  final String label, texto; final VoidCallback onTap;
  const _FechaCampo({required this.label, required this.texto, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final dc    = Theme.of(context).extension<DispersaludColors>()!;
    final verde = Theme.of(context).colorScheme.primary;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: dc.textHint, fontSize: 11)),
      const SizedBox(height: 4),
      GestureDetector(onTap: onTap, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(color: dc.border.withOpacity(0.4), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Expanded(child: Text(texto, style: TextStyle(
              color: texto == 'Seleccionar fecha' ? dc.textHint : dc.textPrimary, fontSize: 14))),
          Icon(Icons.calendar_today_outlined, color: verde, size: 16),
        ]))),
    ]);
  }
}

class _DropBuscable extends StatelessWidget {
  final String label, hint;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  const _DropBuscable({
    required this.label, required this.hint, required this.value,
    required this.options, required this.onChanged, this.enabled = true,
  });
  @override
  Widget build(BuildContext context) {
    final dc    = Theme.of(context).extension<DispersaludColors>()!;
    final verde = Theme.of(context).colorScheme.primary;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: dc.textHint, fontSize: 11)),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: enabled && options.isNotEmpty ? () => _abrir(context, dc, verde) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
              color: enabled ? dc.border.withOpacity(0.4) : dc.border.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Expanded(child: Text(value ?? hint,
                style: TextStyle(color: value != null ? dc.textPrimary : dc.textHint, fontSize: 14))),
            Icon(Icons.arrow_drop_down, color: enabled ? verde : dc.textHint, size: 20),
          ]))),
    ]);
  }

  void _abrir(BuildContext context, DispersaludColors dc, Color verde) {
    showModalBottomSheet(
      context: context, backgroundColor: dc.card, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SelectorSheet(
        titulo: label, opciones: options, seleccionado: value,
        dc: dc, verde: verde,
        onSeleccionar: (v) { Navigator.pop(context); onChanged(v); }),
    );
  }
}

class _SelectorSheet extends StatefulWidget {
  final String titulo; final List<String> opciones; final String? seleccionado;
  final ValueChanged<String> onSeleccionar; final DispersaludColors dc; final Color verde;
  const _SelectorSheet({required this.titulo, required this.opciones, required this.seleccionado,
      required this.onSeleccionar, required this.dc, required this.verde});
  @override
  State<_SelectorSheet> createState() => _SelectorSheetState();
}

class _SelectorSheetState extends State<_SelectorSheet> {
  final _ctrl = TextEditingController();
  List<String> _filtradas = [];
  @override
  void initState() {
    super.initState();
    _filtradas = widget.opciones;
    _ctrl.addListener(() {
      final q = _ctrl.text.toLowerCase();
      setState(() { _filtradas = q.isEmpty ? widget.opciones : widget.opciones.where((o) => o.toLowerCase().contains(q)).toList(); });
    });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false, initialChildSize: 0.6, maxChildSize: 0.92, minChildSize: 0.4,
    builder: (_, ctrl) => Column(children: [
      Container(margin: const EdgeInsets.only(top: 10, bottom: 6), width: 36, height: 4,
          decoration: BoxDecoration(color: widget.dc.border, borderRadius: BorderRadius.circular(2))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(widget.titulo, style: TextStyle(color: widget.dc.textPrimary, fontSize: 16, fontWeight: FontWeight.bold))),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: TextField(controller: _ctrl, autofocus: true,
          style: TextStyle(color: widget.dc.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Buscar...', hintStyle: TextStyle(color: widget.dc.textHint),
            prefixIcon: Icon(Icons.search, color: widget.dc.textHint, size: 20),
            filled: true, fillColor: widget.dc.border.withOpacity(0.4), isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
      Expanded(child: ListView.builder(controller: ctrl, itemCount: _filtradas.length,
        itemBuilder: (_, i) {
          final op = _filtradas[i]; final sel = op == widget.seleccionado;
          return ListTile(dense: true,
            title: Text(op, style: TextStyle(
                color: sel ? widget.verde : widget.dc.textPrimary,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal, fontSize: 14)),
            trailing: sel ? Icon(Icons.check, color: widget.verde, size: 18) : null,
            onTap: () => widget.onSeleccionar(op));
        })),
    ]));
}

class _DropField extends StatelessWidget {
  final String label, value; final List<String> options; final ValueChanged<String?> onChanged;
  const _DropField({required this.label, required this.value, required this.options, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final dc = Theme.of(context).extension<DispersaludColors>()!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: dc.textHint, fontSize: 11)),
      const SizedBox(height: 4),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: dc.border.withOpacity(0.4), borderRadius: BorderRadius.circular(10)),
        child: DropdownButton<String>(value: value, isExpanded: true, underline: const SizedBox(),
          dropdownColor: dc.card, style: TextStyle(color: dc.textPrimary, fontSize: 14),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: onChanged)),
    ]);
  }
}