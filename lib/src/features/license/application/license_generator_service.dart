import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model item riwayat Serial Key yang pernah dibuat oleh Creator
class GeneratedLicenseItem {
  final String deviceId;
  final String serialKey;
  final DateTime createdAt;
  final String customerName;

  GeneratedLicenseItem({
    required this.deviceId,
    required this.serialKey,
    required this.createdAt,
    this.customerName = '',
  });

  Map<String, dynamic> toMap() => {
    'deviceId': deviceId,
    'serialKey': serialKey,
    'createdAt': createdAt.toIso8601String(),
    'customerName': customerName,
  };

  factory GeneratedLicenseItem.fromMap(Map<String, dynamic> map) {
    return GeneratedLicenseItem(
      deviceId: map['deviceId'] as String? ?? '',
      serialKey: map['serialKey'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      customerName: map['customerName'] as String? ?? '',
    );
  }
}

/// Service pembuat Serial Key khusus Creator (Allam Permata Putra)
class LicenseGeneratorService {
  static const String _masterPrivateKeyHex =
      '58862a969bb24a1ad23d24adfe0fb34e0c767490a6bc9f685305c778be3925e5';
  static const String _prefHistoryKey = 'creator_generated_keys_history';

  final Ed25519 _algorithm = Ed25519();

  /// Membuat Serial Key Ed25519 hardware-locked dari Device ID target
  Future<GeneratedLicenseItem> generateKey({
    required String rawDeviceId,
    String customerName = '',
  }) async {
    final cleanDevice = rawDeviceId.trim().toUpperCase();
    if (cleanDevice.isEmpty) {
      throw ArgumentError('Kode perangkat pembeli tidak boleh kosong.');
    }

    final privBytes = _hexToBytes(_masterPrivateKeyHex);
    final keyPair = await _algorithm.newKeyPairFromSeed(privBytes);

    // Tandatangani Device ID secara kriptografis
    final messageBytes = utf8.encode(cleanDevice);
    final signature = await _algorithm.sign(messageBytes, keyPair: keyPair);
    final signatureHex = _bytesToHex(signature.bytes).toUpperCase();

    final formattedKey = 'IDN-KEY-$signatureHex';

    final item = GeneratedLicenseItem(
      deviceId: cleanDevice,
      serialKey: formattedKey,
      createdAt: DateTime.now(),
      customerName: customerName.trim(),
    );

    await saveToHistory(item);
    return item;
  }

  /// Format template pesan WhatsApp ramah pelanggan
  String buildWhatsAppMessage({
    required String serialKey,
    String customerName = '',
  }) {
    final greeting = customerName.isNotEmpty
        ? 'Halo kak $customerName,'
        : 'Halo kak,';
    return '$greeting\n\n'
        'Berikut adalah Kode Lisensi Resmi IDN Reminder Anda:\n\n'
        '$serialKey\n\n'
        'Cara Aktivasi:\n'
        '1. Buka aplikasi IDN Reminder di HP Anda\n'
        '2. Tempel kode di atas pada kolom "MASUKKAN SERIAL KEY"\n'
        '3. Tekan "Aktivasi Sekarang"\n\n'
        'Aplikasi akan aktif permanen seumur hidup di perangkat Anda. Terima kasih!';
  }

  /// Mengambil seluruh riwayat key yang tersimpan di perangkat creator
  Future<List<GeneratedLicenseItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_prefHistoryKey) ?? [];
      return rawList
          .map((itemStr) {
            try {
              final map = jsonDecode(itemStr) as Map<String, dynamic>;
              return GeneratedLicenseItem.fromMap(map);
            } catch (_) {
              return null;
            }
          })
          .whereType<GeneratedLicenseItem>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Menyimpan key baru ke riwayat
  Future<void> saveToHistory(GeneratedLicenseItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();

      // Hapus jika deviceId yang sama sudah ada di riwayat, lalu masukkan di paling atas
      history.removeWhere((element) => element.deviceId == item.deviceId);
      history.insert(0, item);

      final encoded = history.map((e) => jsonEncode(e.toMap())).toList();
      await prefs.setStringList(_prefHistoryKey, encoded);
    } catch (_) {}
  }

  /// Menghapus item dari riwayat
  Future<void> deleteFromHistory(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();
      history.removeWhere((element) => element.deviceId == deviceId);
      final encoded = history.map((e) => jsonEncode(e.toMap())).toList();
      await prefs.setStringList(_prefHistoryKey, encoded);
    } catch (_) {}
  }

  /// Mengosongkan seluruh riwayat
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefHistoryKey);
    } catch (_) {}
  }

  List<int> _hexToBytes(String hex) {
    final bytes = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

final licenseGeneratorServiceProvider = Provider<LicenseGeneratorService>((
  ref,
) {
  return LicenseGeneratorService();
});
