import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class WebDavCredentialStore {
  Future<String?> readPassword();

  Future<void> writePassword(String password);

  Future<void> deletePassword();
}

class SecureWebDavCredentialStore implements WebDavCredentialStore {
  const SecureWebDavCredentialStore();

  static const _passwordKey = 'webdav.connection.password.v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> readPassword() => _storage.read(key: _passwordKey);

  @override
  Future<void> writePassword(String password) =>
      _storage.write(key: _passwordKey, value: password);

  @override
  Future<void> deletePassword() => _storage.delete(key: _passwordKey);
}

final webDavCredentialStoreProvider = Provider<WebDavCredentialStore>(
  (ref) => const SecureWebDavCredentialStore(),
);
