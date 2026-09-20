// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';

/// PRIVATE KEY MASTER (HANYA ADA DI LAPTOP DEVELOPER - JANGAN PERNAH DISERTAKAN KE DALAM APK)
const String _masterPrivateKeyHex =
    '58862a969bb24a1ad23d24adfe0fb34e0c767490a6bc9f685305c778be3925e5';

void main(List<String> args) async {
  print('====================================================');
  print('    IDN REMINDER - LICENSE KEY GENERATOR (OFFLINE)  ');
  print('====================================================');

  String? deviceId;
  for (int i = 0; i < args.length; i++) {
    if ((args[i] == '--device' || args[i] == '-d') && i + 1 < args.length) {
      deviceId = args[i + 1].trim().toUpperCase();
      break;
    }
  }

  if (deviceId == null || deviceId.isEmpty) {
    stdout.write('Masukkan Kode Perangkat Pembeli (contoh: IDN-7F8A-9B21): ');
    deviceId = stdin.readLineSync()?.trim().toUpperCase();
  }

  if (deviceId == null || deviceId.isEmpty) {
    print('❌ Error: Kode perangkat tidak boleh kosong!');
    exit(1);
  }

  try {
    final algorithm = Ed25519();
    final privBytes = _hexToBytes(_masterPrivateKeyHex);
    final keyPair = await algorithm.newKeyPairFromSeed(privBytes);

    // Data yang ditandatangani adalah String Kode Perangkat yang dinormalisasi
    final messageBytes = utf8.encode(deviceId);
    final signature = await algorithm.sign(messageBytes, keyPair: keyPair);
    final signatureHex = _bytesToHex(signature.bytes).toUpperCase();

    // Format serial key yang ramah dan siap dikirim via WhatsApp
    final formattedKey = 'IDN-KEY-$signatureHex';

    print('\n✅ BERHASIL MEMBUAT SERIAL KEY!');
    print('----------------------------------------------------');
    print('Target Device : $deviceId');
    print('License Key   : $formattedKey');
    print('----------------------------------------------------');
    print('📲 Salin teks di bawah ini dan kirim ke WhatsApp pembeli:');
    print('----------------------------------------------------');
    print('Berikut adalah Kode Lisensi Pro Seumur Hidup Anda:\n');
    print(formattedKey);
    print(
      '\nBuka aplikasi IDN Reminder > Tempel kode di layar Aktivasi Perangkat > Tekan Aktivasi Sekarang.',
    );
    print('====================================================\n');
  } catch (e) {
    print('❌ Terjadi kesalahan saat membuat lisensi: $e');
    exit(1);
  }
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
