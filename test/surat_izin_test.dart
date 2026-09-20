import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/src/features/surat_izin/application/surat_izin_pdf_service.dart';
import 'package:reminder/src/features/surat_izin/domain/models/surat_izin_model.dart';
import 'package:reminder/src/features/surat_izin/presentation/widgets/pencil_signature_pad.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SuratIzinModel Unit Tests', () {
    test('Calculates 1 day duration correctly', () {
      final model = SuratIzinModel(
        namaLengkap: 'Musa Abdurrohim',
        nim: '250490346014',
        jurusanKelas: 'Teknik Rekayasa Komputer Jaringan',
        mulaiIzin: DateTime(2026, 5, 29),
        akhirIzin: DateTime(2026, 5, 29),
        noHp: '081904485273',
        jenisIzin: JenisIzin.sakitDiRumah,
        keterangan: 'Demam tinggi',
        namaMentor: 'Ka Aghna Damarula Priatna',
      );

      expect(model.durasiHari, 1);
      expect(model.lamaIzinFormatted, '1 Hari (Jumat, 29 Mei 2026)');
      expect(model.isSakit, isTrue);
    });

    test('Calculates multi-day duration correctly', () {
      final model = SuratIzinModel(
        namaLengkap: 'Musa Abdurrohim',
        nim: '250490346014',
        jurusanKelas: 'Teknik Rekayasa Komputer Jaringan',
        mulaiIzin: DateTime(2026, 6, 1),
        akhirIzin: DateTime(2026, 6, 3),
        noHp: '081904485273',
        jenisIzin: JenisIzin.sakitDiRs,
        keterangan: 'Rawat Inap',
        namaMentor: 'Ka Aghna Damarula Priatna',
      );

      expect(model.durasiHari, 3);
      expect(
        model.lamaIzinFormatted,
        '3 Hari (Senin, 1 Juni 2026 s.d. Rabu, 3 Juni 2026)',
      );
      expect(model.isSakit, isTrue);
    });

    test('Generates formal WhatsApp intro message', () {
      final model = SuratIzinModel(
        namaLengkap: 'Musa Abdurrohim',
        nim: '250490346014',
        jurusanKelas: 'TRKJ',
        mulaiIzin: DateTime(2026, 5, 29),
        akhirIzin: DateTime(2026, 5, 29),
        noHp: '081904485273',
        jenisIzin: JenisIzin.lainnya,
        keterangan: 'Membayar Pajak',
        namaMatkul: 'Jaringan Komputer',
        namaMentor: 'Ka Aghna Damarula Priatna',
      );

      final msg = model.generateWhatsAppMessage();
      expect(msg, contains('Yth. Ka Aghna Damarula Priatna'));
      expect(msg, contains('Musa Abdurrohim'));
      expect(msg, contains('250490346014'));
      expect(msg, contains('Jaringan Komputer'));
      expect(msg, contains('Membayar Pajak'));
    });
  });

  group('SuratIzinPdfService Tests', () {
    final dummyImg = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
      0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
      0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
      0x42, 0x60, 0x82,
    ]);

    test(
      'Generates PDF document bytes successfully without doctor note',
      () async {
        final model = SuratIzinModel(
          namaLengkap: 'Musa Abdurrohim',
          nim: '250490346014',
          jurusanKelas: 'Teknik Rekayasa Komputer Jaringan',
          mulaiIzin: DateTime(2026, 5, 29),
          akhirIzin: DateTime(2026, 5, 29),
          noHp: '081904485273',
          jenisIzin: JenisIzin.sakitDiRumah,
          keterangan: 'Demam',
          namaMentor: 'Ka Aghna Damarula Priatna',
          tandaTanganBytes: dummyImg,
        );

        final pdfBytes = await SuratIzinPdfService.generatePdf(model);
        expect(pdfBytes, isNotEmpty);
        expect(pdfBytes[0], 0x25); // %
        expect(pdfBytes[1], 0x50); // P
        expect(pdfBytes[2], 0x44); // D
        expect(pdfBytes[3], 0x46); // F
      },
    );

    test(
      'Generates 2-page PDF document bytes with doctor note attached',
      () async {
        final model = SuratIzinModel(
          namaLengkap: 'Musa Abdurrohim',
          nim: '250490346014',
          jurusanKelas: 'Teknik Rekayasa Komputer Jaringan',
          mulaiIzin: DateTime(2026, 5, 29),
          akhirIzin: DateTime(2026, 5, 30),
          noHp: '081904485273',
          jenisIzin: JenisIzin.sakitDiRumah,
          keterangan: 'Demam Berdarah',
          namaMentor: 'Ka Aghna Damarula Priatna',
          tandaTanganBytes: dummyImg,
          suratDokterBytes: dummyImg,
        );

        final pdfBytes = await SuratIzinPdfService.generatePdf(model);
        expect(pdfBytes, isNotEmpty);
        expect(pdfBytes[0], 0x25); // %
        expect(pdfBytes[1], 0x50); // P
        expect(pdfBytes[2], 0x44); // D
        expect(pdfBytes[3], 0x46); // F
      },
    );
  });

  group('PencilSignatureController Unit Tests', () {
    test('Calculates thinner stroke for faster movements', () async {
      final controller = PencilSignatureController(
        minStrokeWidth: 1.0,
        maxStrokeWidth: 4.0,
        maxVelocity: 2.0,
      );

      expect(controller.isEmpty, isTrue);

      // Start stroke
      controller.onPointerDown(const Offset(10, 10));
      expect(controller.isNotEmpty, isTrue);

      // Slow movement: wait a bit or move small distance
      controller.onPointerMove(const Offset(12, 12));
      final slowWidth = controller.allStrokes.first.last.width;

      // Fast flick: large distance moved in same time frame
      controller.onPointerMove(const Offset(150, 150));
      final fastWidth = controller.allStrokes.first.last.width;

      controller.onPointerUp();

      // Fast movement must produce a thinner stroke than slow movement
      expect(fastWidth, lessThan(slowWidth));
      expect(fastWidth, greaterThanOrEqualTo(1.0));
      expect(slowWidth, lessThanOrEqualTo(4.0));
    });

    test('Undo and Clear operate properly', () {
      final controller = PencilSignatureController();

      // Stroke 1
      controller.onPointerDown(const Offset(10, 10));
      controller.onPointerMove(const Offset(20, 20));
      controller.onPointerUp();

      // Stroke 2
      controller.onPointerDown(const Offset(30, 30));
      controller.onPointerMove(const Offset(40, 40));
      controller.onPointerUp();

      expect(controller.strokeCount, 2);

      controller.undo();
      expect(controller.strokeCount, 1);

      controller.clear();
      expect(controller.isEmpty, isTrue);
      expect(controller.strokeCount, 0);
    });

    test('Exports valid PNG bytes', () async {
      final controller = PencilSignatureController();
      controller.onPointerDown(const Offset(20, 20));
      controller.onPointerMove(const Offset(40, 50));
      controller.onPointerMove(const Offset(60, 30));
      controller.onPointerUp();

      final pngBytes = await controller.toPngBytes();
      expect(pngBytes, isNotNull);
      expect(pngBytes!, isNotEmpty);
      // PNG magic number: 0x89 0x50 0x4E 0x47 (\x89PNG)
      expect(pngBytes[0], 0x89);
      expect(pngBytes[1], 0x50);
      expect(pngBytes[2], 0x4E);
      expect(pngBytes[3], 0x47);
    });

    testWidgets(
      'PencilSignaturePad captures strokes inside a ListView cleanly',
      (tester) async {
        final controller = PencilSignatureController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  SizedBox(
                    height: 200,
                    child: PencilSignaturePad(controller: controller),
                  ),
                ],
              ),
            ),
          ),
        );

        final padFinder = find.byType(PencilSignaturePad);
        final gesture = await tester.startGesture(tester.getCenter(padFinder));
        await tester.pump();
        await gesture.moveBy(const Offset(30, 30));
        await tester.pump();
        await gesture.moveBy(const Offset(30, -10));
        await tester.pump();
        await gesture.up();
        await tester.pump();

        expect(controller.isNotEmpty, isTrue);
        expect(controller.allStrokes.first.length, greaterThanOrEqualTo(2));
      },
    );
  });
}
