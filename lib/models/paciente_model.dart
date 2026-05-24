class PacienteModel {
  final int?   id;
  final String nombre;
  final String documento;
  final String fechaNac;
  final String sexo;
  final String vereda;
  final String municipio;
  final String telefono;
  final String modulo;
  final String fechaReg;

  PacienteModel({
    this.id,
    required this.nombre,
    required this.documento,
    required this.fechaNac,
    required this.sexo,
    required this.vereda,
    required this.municipio,
    required this.telefono,
    required this.modulo,
    required this.fechaReg,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'nombre':    nombre,
    'documento': documento,
    'fecha_nac': fechaNac,
    'sexo':      sexo,
    'vereda':    vereda,
    'municipio': municipio,
    'telefono':  telefono,
    'modulo':    modulo,
    'fecha_reg': fechaReg,
  };

  factory PacienteModel.fromMap(Map<String, dynamic> m) => PacienteModel(
    id:         m['id'],
    nombre:     m['nombre']    ?? '',
    documento:  m['documento'] ?? '',
    fechaNac:   m['fecha_nac'] ?? '',
    sexo:       m['sexo']      ?? '',
    vereda:     m['vereda']    ?? '',
    municipio:  m['municipio'] ?? '',
    telefono:   m['telefono']  ?? '',
    modulo:     m['modulo']    ?? '',
    fechaReg:   m['fecha_reg'] ?? '',
  );
}