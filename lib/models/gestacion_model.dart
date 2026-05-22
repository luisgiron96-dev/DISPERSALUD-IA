class GestacionModel {

  final int? id;
  final String nombre;
  final int edad;
  final String presion;

  GestacionModel({
    this.id,
    required this.nombre,
    required this.edad,
    required this.presion,
  });

  Map<String, dynamic> toMap() {

    return {
      'id': id,
      'nombre': nombre,
      'edad': edad,
      'presion': presion,
    };
  }
}