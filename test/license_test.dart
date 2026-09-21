import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/src/constants/admin_contact.dart';
import 'package:reminder/src/features/license/application/license_generator_service.dart';
import 'package:reminder/src/features/license/application/license_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Offline Cryptographic License System Tests', () {
    late LicenseService licenseService;
    const masterPrivHex =
        '58862a969bb24a1ad23d24adfe0fb34e0c767490a6bc9f685305c778be3925e5';

    // Helper untuk generate signature di unit test
    Future<String> signDevice(String deviceId) async {
      final algorithm = Ed25519();
      final privBytes = <int>[];
      for (int i = 0; i < masterPrivHex.length; i += 2) {
        privBytes.add(int.parse(masterPrivHex.substring(i, i + 2), radix: 16));
      }
      final keyPair = await algorithm.newKeyPairFromSeed(privBytes);
      final signature = await algorithm.sign(
        utf8.encode(deviceId.trim().toUpperCase()),
        keyPair: keyPair,
      );
      final hex = signature.bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase();
      return 'IDN-KEY-$hex';
    }

    setUp(() {
      licenseService = LicenseService();
    });

    test('Valid signature for target device passes verification', () async {
      const deviceId = 'IDN-7F8A-9B21';
      final validKey = await signDevice(deviceId);

      final isValid = await licenseService.verifySignature(
        deviceId: deviceId,
        serialKey: validKey,
      );

      expect(isValid, isTrue);
    });

    test(
      'Anti-Piracy Check: Same serial key FAILS on a different device',
      () async {
        const deviceA = 'IDN-7F8A-9B21';
        const deviceB =
            'IDN-1122-3344'; // HP teman yang mencoba pakai key yang sama

        // Key dibuat khusus untuk Device A
        final keyForDeviceA = await signDevice(deviceA);

        // Coba verifikasi di Device B
        final isValidOnDeviceB = await licenseService.verifySignature(
          deviceId: deviceB,
          serialKey: keyForDeviceA,
        );

        // HARUS GAGAL! Kunci Device A tidak boleh bisa dipakai di Device B
        expect(isValidOnDeviceB, isFalse);
      },
    );

    test('Malformed or tampered serial keys are rejected gracefully', () async {
      const deviceId = 'IDN-7F8A-9B21';

      expect(
        await licenseService.verifySignature(
          deviceId: deviceId,
          serialKey: 'IDN-KEY-INVALID-SHORT-KEY',
        ),
        isFalse,
      );

      expect(
        await licenseService.verifySignature(deviceId: deviceId, serialKey: ''),
        isFalse,
      );
    });

    test(
      'Key formatting is tolerant to spaces, lowercase, and newlines',
      () async {
        const deviceId = 'IDN-7F8A-9B21';
        final validKey = await signDevice(deviceId);

        // User paste dengan spasi atau huruf kecil
        final messyKey = '  ${validKey.toLowerCase()} \n ';

        final isValid = await licenseService.verifySignature(
          deviceId: deviceId,
          serialKey: messyKey,
        );

        expect(isValid, isTrue);
      },
    );

    test(
      'LicenseGeneratorService generates key that verifies perfectly',
      () async {
        final generator = LicenseGeneratorService();
        const testDevice = 'IDN-88AA-99BB';

        final item = await generator.generateKey(
          rawDeviceId: testDevice,
          customerName: 'Budi Santoso',
        );

        expect(item.deviceId, equals(testDevice));
        expect(item.serialKey.startsWith('IDN-KEY-'), isTrue);
        expect(item.customerName, equals('Budi Santoso'));

        final verified = await licenseService.verifySignature(
          deviceId: testDevice,
          serialKey: item.serialKey,
        );
        expect(verified, isTrue);

        final waMessage = generator.buildWhatsAppMessage(
          serialKey: item.serialKey,
          customerName: 'Budi',
        );
        expect(waMessage.contains('Halo kak Budi,'), isTrue);
        expect(waMessage.contains(item.serialKey), isTrue);
      },
    );

    test('AdminContactConfig decodes protected number and builds correct WhatsApp URI', () {
      final number = AdminContactConfig.adminWhatsAppNumber;
      expect(number.isNotEmpty, isTrue);
      expect(number.startsWith('628'), isTrue);
      expect(number.length, equals(13));

      const testMsg = 'Halo Admin, saya ingin membeli lisensi.';
      final uri = AdminContactConfig.buildWhatsAppUri(testMsg);
      expect(uri.scheme, equals('https'));
      expect(uri.host, equals('wa.me'));
      expect(uri.path, equals('/$number'));
      expect(uri.queryParameters['text'], equals(testMsg));
    });
  });
}

