import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reminder/src/utils/date_utils.dart';
import 'package:reminder/src/features/dashboard/presentation/dashboard_utils.dart';
import 'package:reminder/src/features/dashboard/presentation/kelas_utils.dart';

void main() {
  group('AppDateUtils Tests', () {
    test('formatDateIndo formats DateTime correctly', () {
      final dt = DateTime(2026, 9, 15);
      final formatted = AppDateUtils.formatDateIndo(dt);
      expect(formatted, 'Selasa, 15 September 2026');
    });

    test('formatDateIndo handles string input', () {
      final formatted = AppDateUtils.formatDateIndo('2026-08-17');
      expect(formatted, contains('17 Agustus 2026'));
    });

    test(
      'formatDateIndo handles null and invalid dates gracefully (Fail Fast)',
      () {
        expect(AppDateUtils.formatDateIndo(null), '-');
        expect(AppDateUtils.formatDateIndo('not-a-date'), '-');
        expect(AppDateUtils.formatDateIndo(''), '-');
      },
    );

    test('formatShortDateIndo formats date without day name', () {
      final dt = DateTime(2026, 1, 1);
      expect(AppDateUtils.formatShortDateIndo(dt), '1 Januari 2026');
      expect(AppDateUtils.formatShortDateIndo('2026-05-20'), '20 Mei 2026');
    });
  });

  group('KelasUtils Tests', () {
    test('parseMinutes parses HH:mm format correctly', () {
      expect(KelasUtils.parseMinutes('08:30'), 8 * 60 + 30);
      expect(KelasUtils.parseMinutes('14:15'), 14 * 60 + 15);
      expect(KelasUtils.parseMinutes('00:00'), 0);
    });

    test('parseMinutes handles invalid or empty inputs gracefully', () {
      expect(KelasUtils.parseMinutes(''), isNull);
      expect(KelasUtils.parseMinutes('invalid'), isNull);
    });

    test(
      'extractClassesList extracts nested Inertia props data list safely',
      () {
        final rawData = {
          'props': {
            'kelas': {
              'data': [
                {'matakuliah': 'Algoritma', 'jam_mulai': '10:00'},
                {'matakuliah': 'Basis Data', 'jam_mulai': '08:00'},
              ],
            },
          },
        };
        final list = KelasUtils.extractClassesList(rawData);
        expect(list.length, 2);
        // Diurutkan berdasarkan jam mulai (08:00 sebelum 10:00)
        expect(list.first['matakuliah'], 'Basis Data');
        expect(list.last['matakuliah'], 'Algoritma');
      },
    );

    test('extractClassesList returns empty on malformed data', () {
      expect(KelasUtils.extractClassesList(null), isEmpty);
      expect(KelasUtils.extractClassesList([]), isEmpty);
      expect(KelasUtils.extractClassesList({'data': 'string'}), isEmpty);
    });

    test(
      'extractClassesList falls back to dashboardData when kelasData is empty (morning fallback)',
      () {
        final emptyKelasData = {
          'props': {
            'kelas': {'data': []},
          },
        };
        final mockDashboardData = {
          'props': {
            'jadwal': [
              {'nama_kelas': 'Pemrograman Mobile', 'jam_mulai': '08:00'},
              {'nama_kelas': 'Jaringan Komputer', 'jam_mulai': '13:00'},
            ],
          },
        };

        final list = KelasUtils.extractClassesList(
          emptyKelasData,
          dashboardData: mockDashboardData,
        );
        expect(list.length, 2);
        expect(list.first['nama_kelas'], 'Pemrograman Mobile');
        expect(list.last['nama_kelas'], 'Jaringan Komputer');
      },
    );

    test(
      'extractClassesList falls back to absensiData when kelasData and dashboardData are empty',
      () {
        final emptyKelas = {
          'props': {
            'kelas': {'data': []},
          },
        };
        final absensiData = {
          'props': {
            'kelas': [
              {'nama_kelas': 'English for IT', 'jam_mulai': '09:00'},
            ],
          },
        };

        final list = KelasUtils.extractClassesList(
          emptyKelas,
          dashboardData: null,
          absensiData: absensiData,
        );
        expect(list.length, 1);
        expect(list.first['nama_kelas'], 'English for IT');
      },
    );

    test(
      'resolveTodayClassesFromAbsensi filters and constructs today classes accurately',
      () async {
        final mockEnrolled = [
          {'kode_kelas_harian': 'KH101', 'nama_kelas': 'Pemrograman Mobile'},
          {'kode_kelas_harian': 'KH102', 'nama_kelas': 'Basis Data'},
        ];

        final today = DateTime(2026, 10, 5);

        final result = await KelasUtils.resolveTodayClassesFromAbsensi(
          enrolledClasses: mockEnrolled,
          targetDate: today,
          fetchJadwalAbsensi: (kode) async {
            if (kode == 'KH101') {
              return {
                'props': {
                  'jadwal': [
                    {
                      'id': 11,
                      'tanggal': '2026-10-05',
                      'jam_mulai': '08:00',
                      'jam_selesai': '10:00',
                      'kode_unik': 'ABC1',
                    }
                  ],
                  'kelasHarian': {'nama_dosen': 'Ustadz Fulan'},
                }
              };
            }
            if (kode == 'KH102') {
              return {
                'props': {
                  'jadwal': [
                    {
                      'id': 12,
                      'tanggal': '2026-10-06', // Besok, bukan hari ini!
                      'jam_mulai': '10:00',
                    }
                  ],
                }
              };
            }
            return null;
          },
        );

        expect(result.length, 1);
        expect(result.first['kode_kelas_harian'], 'KH101');
        expect(result.first['nama_kelas'], 'Pemrograman Mobile');
        expect(result.first['jam_mulai'], '08:00');
        expect(result.first['jadwal_id'], 11);
        expect(result.first['nama_dosen'], 'Ustadz Fulan');
      },
    );

    test(
      'cacheScheduleToday and getCachedScheduleToday handles weekday fallback',
      () async {
        SharedPreferences.setMockInitialValues({});
        final mockClasses = [
          {'nama_kelas': 'TRPL Kelas A', 'jam_mulai': '08:00'},
        ];

        await KelasUtils.cacheScheduleToday(mockClasses);

        final cached = await KelasUtils.getCachedScheduleToday();
        expect(cached.length, 1);
        expect(cached.first['nama_kelas'], 'TRPL Kelas A');
      },
    );

    test('extractDosenName extracts name safely', () {
      expect(KelasUtils.extractDosenName(null, 'Pak Ustadz'), 'Pak Ustadz');
      expect(KelasUtils.extractDosenName({'name': 'Dosen A'}, null), 'Dosen A');
      expect(
        KelasUtils.extractDosenName({
          'user': {'name': 'Dosen B'},
        }, ''),
        'Dosen B',
      );
      expect(KelasUtils.extractDosenName(null, null), 'Dosen Pengampu');
    });

    test(
      'getMapelIcon returns appropriate icon and color based on subject keywords',
      () {
        final codeMapel = KelasUtils.getMapelIcon('TRPL Pemrograman Mobile');
        expect(codeMapel.icon.codePoint, isNotNull);
        expect(codeMapel.svgAsset, isNull);

        final englishMapel = KelasUtils.getMapelIcon('English for IT');
        expect(englishMapel.svgAsset, equals('assets/icon/bahasa.svg'));

        final diniahMapel = KelasUtils.getMapelIcon('Pendidikan Diniyah Islam');
        expect(diniahMapel.svgAsset, equals('assets/icon/diniah.svg'));

        final tahfizMapel = KelasUtils.getMapelIcon('Tahfidz Al-Quran');
        expect(tahfizMapel.icon.codePoint, isNotNull);
        expect(tahfizMapel.svgAsset, equals('assets/icon/tahfiz.svg'));
      },
    );
  });

  group('DashboardUtils Authorization Tests', () {
    test(
      'isAllamPermataPutra returns true for Allam Permata Putra name string',
      () {
        expect(
          DashboardUtils.isAllamPermataPutra(name: 'Allam Permata Putra'),
          isTrue,
        );
        expect(
          DashboardUtils.isAllamPermataPutra(name: 'allam permata putra'),
          isTrue,
        );
        expect(
          DashboardUtils.isAllamPermataPutra(name: 'ALLAM PERMATA PUTRA'),
          isTrue,
        );
      },
    );

    test(
      'isAllamPermataPutra returns true from nested payload / extraData',
      () {
        final mockJadwalPayload = {
          'props': {
            'auth': {
              'user': {'name': 'Allam Permata Putra', 'username': 'allam123'},
            },
          },
        };

        expect(
          DashboardUtils.isAllamPermataPutra(extraData: mockJadwalPayload),
          isTrue,
        );
      },
    );

    test(
      'isAllamPermataPutra returns false for other students or malformed data',
      () {
        expect(
          DashboardUtils.isAllamPermataPutra(name: 'Muhammad Budi Santoso'),
          isFalse,
        );
        expect(
          DashboardUtils.isAllamPermataPutra(
            dashboardData: {
              'props': {
                'auth': {
                  'user': {'name': 'Siti Aminah'},
                },
              },
            },
          ),
          isFalse,
        );
        expect(DashboardUtils.isAllamPermataPutra(), isFalse);
      },
    );
  });
}
