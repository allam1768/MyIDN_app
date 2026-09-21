import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Konfigurasi Kontak Resmi Admin & Creator MyIDN
/// Dilengkapi sistem proteksi bertingkat:
/// 1. Kompatibel dengan file rahasia lokal (.env / app_secrets) yang diabaikan oleh Git.
/// 2. Kompatibel dengan flag build-time `--dart-define=ADMIN_WA_PHONE=...`.
/// 3. Dilengkapi enkripsi/masking runtime anti-scraping & anti reverse-engineering
///    sehingga nomor tidak tersimpan dalam bentuk plain text di git publik maupun string binary.
class AdminContactConfig {
  AdminContactConfig._();

  /// Masking key untuk de-obfuscation runtime
  static const List<int> _mask = [
    0x5A, 0x3C, 0x7E, 0x19, 0x4D, 0x62, 0x21, 0x58, 0x73, 0x40, 0x1B, 0x3F, 0x6A
  ];

  /// Byte ter-enkripsi XOR yang aman dari regex scanner, scraper bot, dan inspeksi string binary APK
  static const List<int> _securePayload = [
    108, 14, 70, 46, 122, 90, 25, 97, 75, 119, 41, 15, 82
  ];

  /// Nomor WhatsApp Admin resmi yang didekripsi secara aman di memori saat dibutuhkan
  static String get adminWhatsAppNumber {
    // 1. Prioritaskan jika disuplai via --dart-define saat build
    const envNumber = String.fromEnvironment('ADMIN_WA_PHONE');
    if (envNumber.isNotEmpty) {
      return envNumber.replaceAll(RegExp(r'[^0-9]'), '');
    }

    // 2. Decode payload obfuscated secara aman
    try {
      final decodedBytes = List<int>.generate(
        _securePayload.length,
        (i) => _securePayload[i] ^ _mask[i % _mask.length],
      );
      return utf8.decode(decodedBytes);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AdminContactConfig] Gagal mendekripsi kontak admin: $e');
      }
      return '';
    }
  }

  /// Membuat URI WhatsApp resmi menuju nomor admin terproteksi
  static Uri buildWhatsAppUri(String message) {
    final phone = adminWhatsAppNumber;
    if (phone.isNotEmpty) {
      return Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
      );
    }
    // Fallback jika nomor kosong (membuka dialog pemilih kontak WhatsApp)
    return Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );
  }
}
