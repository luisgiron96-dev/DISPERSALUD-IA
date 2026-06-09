// Stub de local_auth para Flutter Web
// Ubicación: lib/stubs/local_auth_stub.dart

class LocalAuthentication {
  Future<bool> get canCheckBiometrics async => false;
  Future<bool> isDeviceSupported() async => false;
  Future<bool> authenticate({
    required String localizedReason,
  }) async => false;
}