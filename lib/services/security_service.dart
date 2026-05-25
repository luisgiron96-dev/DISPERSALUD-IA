import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio de cifrado para DISPERSALUD IA.
///
/// Estrategia:
///   - La clave AES-256 se genera una sola vez y se guarda en el
///     llavero seguro del dispositivo (Keychain en iOS, Keystore en Android).
///   - Los campos sensibles se cifran con AES-256 en modo CBC + IV aleatorio.
///   - El texto cifrado se almacena como "iv:base64(ciphertext)" para que
///     cada valor tenga su propio IV sin necesidad de columnas extra.
///
/// Campos que se cifran en 'pacientes':
///   documento, telefono
///
/// Campos que se cifran en 'consultas':
///   diagnostico, observaciones, datos_json, datos_extra
class SecurityService {
  SecurityService._();
  static final SecurityService instance = SecurityService._();

  static const _kStorageKey = 'dispersalud_aes_key';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  enc.Encrypter? _encrypter;

  // ── Inicialización ──────────────────────────────────────────────────────
  /// Debe llamarse una vez al arrancar la app (en main o en el splash).
  Future<void> init() async {
    String? keyB64 = await _storage.read(key: _kStorageKey);

    if (keyB64 == null) {
      // Primera vez: generar clave aleatoria de 32 bytes (AES-256)
      final rng   = Random.secure();
      final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
      keyB64      = base64Url.encode(bytes);
      await _storage.write(key: _kStorageKey, value: keyB64);
    }

    final keyBytes = base64Url.decode(keyB64);
    final key      = enc.Key(keyBytes);
    _encrypter     = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  }

  // ── Cifrar ──────────────────────────────────────────────────────────────
  /// Devuelve "ivB64:ciphertextB64" o el texto original si falla.
  String cifrar(String texto) {
    if (_encrypter == null || texto.isEmpty) return texto;
    try {
      final iv        = enc.IV.fromSecureRandom(16);
      final encrypted = _encrypter!.encrypt(texto, iv: iv);
      return '${iv.base64}:${encrypted.base64}';
    } catch (_) {
      return texto; // Fallback: no romper la app si algo falla
    }
  }

  // ── Descifrar ───────────────────────────────────────────────────────────
  /// Recibe "ivB64:ciphertextB64" y devuelve el texto original.
  /// Si el valor no tiene ese formato (datos anteriores sin cifrar) lo
  /// devuelve tal cual para mantener compatibilidad hacia atrás.
  String descifrar(String? valor) {
    if (_encrypter == null || valor == null || valor.isEmpty) return valor ?? '';
    // Verificar que tiene el formato esperado "iv:ciphertext"
    final partes = valor.split(':');
    if (partes.length != 2) return valor; // dato antiguo sin cifrar
    try {
      final iv        = enc.IV.fromBase64(partes[0]);
      final encrypted = enc.Encrypted.fromBase64(partes[1]);
      return _encrypter!.decrypt(encrypted, iv: iv);
    } catch (_) {
      return valor; // Si falla, devolver el valor tal cual
    }
  }

  // ── Helpers para Maps ───────────────────────────────────────────────────

  /// Cifra los campos sensibles de un paciente antes de insertarlo.
  Map<String, dynamic> cifrarPaciente(Map<String, dynamic> data) {
    final m = Map<String, dynamic>.from(data);
    for (final campo in ['documento', 'telefono']) {
      if (m[campo] != null && (m[campo] as String).isNotEmpty) {
        m[campo] = cifrar(m[campo] as String);
      }
    }
    return m;
  }

  /// Descifra los campos sensibles de un paciente al leerlo.
  Map<String, dynamic> descifrarPaciente(Map<String, dynamic> row) {
    final m = Map<String, dynamic>.from(row);
    for (final campo in ['documento', 'telefono']) {
      if (m[campo] != null) {
        m[campo] = descifrar(m[campo] as String?);
      }
    }
    return m;
  }

  /// Cifra los campos sensibles de una consulta antes de insertarla.
  Map<String, dynamic> cifrarConsulta(Map<String, dynamic> data) {
    final m = Map<String, dynamic>.from(data);
    for (final campo in ['diagnostico', 'observaciones', 'datos_json', 'datos_extra']) {
      if (m[campo] != null && (m[campo] as String).isNotEmpty) {
        m[campo] = cifrar(m[campo] as String);
      }
    }
    return m;
  }

  /// Descifra los campos sensibles de una consulta al leerla.
  Map<String, dynamic> descifrarConsulta(Map<String, dynamic> row) {
    final m = Map<String, dynamic>.from(row);
    for (final campo in ['diagnostico', 'observaciones', 'datos_json', 'datos_extra']) {
      if (m[campo] != null) {
        m[campo] = descifrar(m[campo] as String?);
      }
    }
    return m;
  }

  // ── Estado ──────────────────────────────────────────────────────────────
  bool get inicializado => _encrypter != null;
}