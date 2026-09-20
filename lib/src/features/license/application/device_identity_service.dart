import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Layanan penentuan identitas hardware unik perangkat (Device Fingerprinting).
/// Digunakan untuk mengunci lisensi ke 1 perangkat fisik saja.
class DeviceIdentityService {
  static const String _prefCachedDeviceId = 'idn_cached_device_id';

  /// Mengambil Device Code yang ramah manusia (contoh: IDN-7F8A-9B21).
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_prefCachedDeviceId);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final rawHardwareId = await _getRawHardwareId();
    final formattedId = _formatToDeviceCode(rawHardwareId);

    // Simpan ke SharedPreferences agar ID konsisten selama aplikasi terinstal
    await prefs.setString(_prefCachedDeviceId, formattedId);
    return formattedId;
  }

  /// Membaca identitas fisik mentah dari hardware Android/iOS/Desktop.
  static Future<String> _getRawHardwareId() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return '${webInfo.vendor}-${webInfo.userAgent}';
      }

      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        // Gabungan ID hardware permanen: androidId + model + brand
        return '${android.id}_${android.brand}_${android.model}';
      }

      if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        return ios.identifierForVendor ?? '${ios.name}_${ios.model}';
      }

      if (Platform.isLinux) {
        final linux = await deviceInfo.linuxInfo;
        return linux.machineId ?? linux.id;
      }

      if (Platform.isMacOS) {
        final mac = await deviceInfo.macOsInfo;
        return mac.systemGUID ?? mac.computerName;
      }

      if (Platform.isWindows) {
        final win = await deviceInfo.windowsInfo;
        return win.deviceId;
      }
    } catch (e) {
      debugPrint('Gagal membaca hardware ID: $e');
    }

    // Fallback acak yang di-persist jika hardware info gagal dibaca
    return 'FALLBACK_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Mengonversi hardware ID menjadi format pendek yang mudah dibaca mahasiswa.
  /// Format: IDN-XXXX-XXXX (8 karakter hex terenkripsi SHA-256)
  static String _formatToDeviceCode(String rawId) {
    final bytes = utf8.encode(rawId);
    final digest = sha256.convert(bytes);
    final hex = digest.toString().toUpperCase();

    final part1 = hex.substring(0, 4);
    final part2 = hex.substring(4, 8);
    return 'IDN-$part1-$part2';
  }
}
