import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/src/features/poin_kebaikan/data/poin_kebaikan_data.dart';
import 'package:reminder/src/features/poin_kebaikan/presentation/widgets/kebaikan_identity_card.dart';
import 'package:reminder/src/utils/date_utils.dart';

void main() {
  group('PoinKebaikanConfig Date Tests', () {
    test('formatDateForGoogleForm formats date as YYYY-MM-DD with zero padding', () {
      final date1 = DateTime(2026, 10, 21);
      expect(PoinKebaikanConfig.formatDateForGoogleForm(date1), '2026-10-21');

      final date2 = DateTime(2026, 5, 4);
      expect(PoinKebaikanConfig.formatDateForGoogleForm(date2), '2026-05-04');
    });

    test('entryTanggal matches the official Google Form field entry ID', () {
      expect(PoinKebaikanConfig.entryTanggal, 'entry.1918732472');
    });

    test('builds valid prefilled query parameters with auto-input date', () {
      final targetDate = DateTime(2026, 10, 21);
      final formattedDate =
          PoinKebaikanConfig.formatDateForGoogleForm(targetDate);

      final queryParams = <String, String>{
        'usp': 'pp_url',
        PoinKebaikanConfig.entryAngkatan: PoinKebaikanConfig.defaultAngkatan,
        PoinKebaikanConfig.entryProdi: 'TRPL (Programmer)',
        PoinKebaikanConfig.entryNama: 'Allam Permata Putra',
        PoinKebaikanConfig.entryTanggal: formattedDate,
        '${PoinKebaikanConfig.entryTanggal}_year': targetDate.year.toString(),
        '${PoinKebaikanConfig.entryTanggal}_month':
            targetDate.month.toString().padLeft(2, '0'),
        '${PoinKebaikanConfig.entryTanggal}_day':
            targetDate.day.toString().padLeft(2, '0'),
        PoinKebaikanConfig.entryJanji: PoinKebaikanConfig.janjiValue,
      };

      expect(queryParams['entry.1918732472'], '2026-10-21');
      expect(queryParams['entry.1918732472_year'], '2026');
      expect(queryParams['entry.1918732472_month'], '10');
      expect(queryParams['entry.1918732472_day'], '21');
      expect(queryParams['usp'], 'pp_url');
    });
  });

  group('KebaikanIdentityCard Widget Tests', () {
    testWidgets('renders today date with Hari Ini badge by default', (tester) async {
      final today = DateTime.now();
      bool picked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KebaikanIdentityCard(
              selectedNama: 'Allam Permata Putra',
              selectedProdi: 'TRPL (Programmer)',
              selectedAngkatan: 'Angkatan 5 (2026)',
              selectedTanggal: today,
              agreedToPromise: true,
              onNamaChanged: (_) {},
              onProdiChanged: (_) {},
              onPickTanggal: () => picked = true,
              onPromiseToggled: () {},
            ),
          ),
        ),
      );

      expect(find.text('Tanggal Kegiatan Yang Dilaporkan'), findsOneWidget);
      expect(find.text('Hari Ini'), findsOneWidget);
      expect(find.text(AppDateUtils.formatDateIndo(today)), findsOneWidget);
      expect(find.text('Ubah'), findsOneWidget);

      await tester.tap(find.text('Ubah'));
      expect(picked, isTrue);
    });

    testWidgets('does not show Hari Ini badge when date is yesterday', (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KebaikanIdentityCard(
              selectedNama: 'Allam Permata Putra',
              selectedProdi: 'TRPL (Programmer)',
              selectedAngkatan: 'Angkatan 5 (2026)',
              selectedTanggal: yesterday,
              agreedToPromise: true,
              onNamaChanged: (_) {},
              onProdiChanged: (_) {},
              onPickTanggal: () {},
              onPromiseToggled: () {},
            ),
          ),
        ),
      );

      expect(find.text('Tanggal Kegiatan Yang Dilaporkan'), findsOneWidget);
      expect(find.text('Hari Ini'), findsNothing);
      expect(find.text(AppDateUtils.formatDateIndo(yesterday)), findsOneWidget);
    });
  });
}
