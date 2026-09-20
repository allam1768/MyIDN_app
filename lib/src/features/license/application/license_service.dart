import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_identity_service.dart';

/// PUBLIC KEY MASTER (AMAN DILETAKKAN DI APK KARENA HANYA BISA MEMVERIFIKASI, BUKAN MEMBUAT KUNCI)
const String _masterPublicKeyHex =
    'c5f804478f2b9fcbcf479f6a5b1e9a1d5b09420d0deec78abf2eaf72e0d8a44e';

class LicenseService {
  static const String prefLicenseKey = 'idn_license_key';
  static const String prefLicenseDevice = 'idn_license_device';

  final Ed25519 _algorithm = Ed25519();

  /// Verifikasi apakah Serial Key valid untuk Device ID tertentu secara matematika kriptografi.
  Future<bool> verifySignature({
    required String deviceId,
    required String serialKey,
  }) async {
    try {
      final cleanKey = _sanitizeKey(serialKey);
      if (cleanKey.length != 128) {
        return false;
      }

      final signatureBytes = _hexToBytes(cleanKey);
      final publicKeyBytes = _hexToBytes(_masterPublicKeyHex);
      final publicKey = SimplePublicKey(
        publicKeyBytes,
        type: KeyPairType.ed25519,
      );

      final messageBytes = utf8.encode(deviceId.trim().toUpperCase());
      final signature = Signature(signatureBytes, publicKey: publicKey);

      final isValid = await _algorithm.verify(
        messageBytes,
        signature: signature,
      );
      return isValid;
    } catch (e) {
      debugPrint('License verification error: $e');
      return false;
    }
  }

  /// Memeriksa apakah perangkat saat ini memiliki lisensi Pro yang valid.
  Future<bool> isLicenseActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(prefLicenseKey);
      if (savedKey == null || savedKey.isEmpty) {
        return false;
      }

      final currentDeviceId = await DeviceIdentityService.getDeviceId();
      return await verifySignature(
        deviceId: currentDeviceId,
        serialKey: savedKey,
      );
    } catch (e) {
      debugPrint('isLicenseActive error: $e');
      return false;
    }
  }

  /// Mengaktivasi aplikasi menggunakan Serial Key baru.
  Future<bool> activate(String serialKey) async {
    final currentDeviceId = await DeviceIdentityService.getDeviceId();
    final isValid = await verifySignature(
      deviceId: currentDeviceId,
      serialKey: serialKey,
    );

    if (isValid) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefLicenseKey, serialKey.trim());
      await prefs.setString(prefLicenseDevice, currentDeviceId);
      return true;
    }
    return false;
  }

  /// Menghapus aktivasi lokal (misal untuk reset / pengujian)
  Future<void> revokeLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefLicenseKey);
    await prefs.remove(prefLicenseDevice);
  }

  String _sanitizeKey(String rawKey) {
    return rawKey
        .trim()
        .toUpperCase()
        .replaceAll('IDN-KEY-', '')
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '');
  }

  List<int> _hexToBytes(String hex) {
    final bytes = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }
}

/// Provider Singleton Service
final licenseServiceProvider = Provider<LicenseService>((ref) {
  return LicenseService();
});

/// StateNotifier untuk memantau status lisensi di seluruh aplikasi
class LicenseStateNotifier extends StateNotifier<AsyncValue<bool>> {
  final LicenseService _service;

  LicenseStateNotifier(this._service) : super(const AsyncValue.loading()) {
    checkStatus();
  }

  Future<void> checkStatus() async {
    try {
      final isActive = await _service.isLicenseActive();
      state = AsyncValue.data(isActive);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> activate(String serialKey) async {
    state = const AsyncValue.loading();
    try {
      final success = await _service.activate(serialKey);
      state = AsyncValue.data(success);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> revoke() async {
    await _service.revokeLicense();
    state = const AsyncValue.data(false);
  }
}

final licenseControllerProvider =
    StateNotifierProvider<LicenseStateNotifier, AsyncValue<bool>>((ref) {
      final service = ref.watch(licenseServiceProvider);
      return LicenseStateNotifier(service);
    });
