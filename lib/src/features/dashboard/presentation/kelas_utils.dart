import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Utilitas pemrosesan jadwal dan presentasi kelas
class KelasUtils {
  KelasUtils._();

  static const String _keyCachedSchedule = 'cached_schedule_today';
  static const String _keyCachedScheduleDate = 'cached_schedule_date';
  static const String _keyCachedWeekdayPrefix = 'cached_schedule_weekday_';

  /// Menyimpan snapshot jadwal kelas hari ini ke SharedPreferences (Offline & Morning Fallback)
  static Future<void> cacheScheduleToday(List<dynamic> classes) async {
    if (classes.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final dateKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await prefs.setString(_keyCachedScheduleDate, dateKey);
      await prefs.setString(_keyCachedSchedule, jsonEncode(classes));
      // Simpan juga berdasarkan pola hari dalam seminggu (1 = Senin s.d. 7 = Minggu)
      await prefs.setString(
        '$_keyCachedWeekdayPrefix${now.weekday}',
        jsonEncode(classes),
      );
    } catch (_) {}
  }

  /// Mengambil snapshot jadwal kelas tersimpan jika tanggal hari ini cocok
  /// atau fallback ke cache pola mingguan saat offline / pagi hari
  static Future<List<dynamic>> getCachedScheduleToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final dateKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final cachedDate = prefs.getString(_keyCachedScheduleDate);
      if (cachedDate == dateKey) {
        final rawJson = prefs.getString(_keyCachedSchedule);
        if (rawJson != null && rawJson.isNotEmpty) {
          final decoded = jsonDecode(rawJson);
          if (decoded is List && decoded.isNotEmpty) return decoded;
        }
      }

      // Fallback mingguan jika hari ini belum tersimpan (misal pagi hari baru mulai hari baru)
      final rawWeekdayJson =
          prefs.getString('$_keyCachedWeekdayPrefix${now.weekday}');
      if (rawWeekdayJson != null && rawWeekdayJson.isNotEmpty) {
        final decoded = jsonDecode(rawWeekdayJson);
        if (decoded is List && decoded.isNotEmpty) return decoded;
      }
    } catch (_) {}
    return [];
  }

  /// Konversi string waktu "HH:mm" menjadi total menit dari jam 00:00
  static int? parseMinutes(String timeStr) {
    if (timeStr.trim().isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hours = int.tryParse(parts[0]);
        final minutes = int.tryParse(parts[1]);
        if (hours != null && minutes != null) {
          return hours * 60 + minutes;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Mencocokkan daftar kelas terdaftar mahasiswa (dari absensi_harian)
  /// dengan jadwal sesi hari ini via query listJadwal per kelas secara paralel.
  static Future<List<Map<String, dynamic>>> resolveTodayClassesFromAbsensi({
    required List<dynamic> enrolledClasses,
    required Future<dynamic> Function(String kodeKelas) fetchJadwalAbsensi,
    DateTime? targetDate,
  }) async {
    if (enrolledClasses.isEmpty) return [];

    final now = targetDate ?? DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Deduplikasi kelas terdaftar
    final seenCodes = <String>{};
    final uniqueEnrolled = <Map>[];
    for (final item in enrolledClasses) {
      if (item is! Map) continue;
      final kode = (item['kode_kelas_harian'] ??
              item['kode_kelas'] ??
              item['id'] ??
              '')
          .toString()
          .trim();
      if (kode.isNotEmpty && !seenCodes.contains(kode)) {
        seenCodes.add(kode);
        uniqueEnrolled.add(Map<String, dynamic>.from(item));
      }
    }

    final futures = uniqueEnrolled.map((c) async {
      final kode = (c['kode_kelas_harian'] ??
              c['kode_kelas'] ??
              c['id'] ??
              '')
          .toString()
          .trim();
      if (kode.isEmpty) return null;

      try {
        final jadwalPayload = await fetchJadwalAbsensi(kode);
        if (jadwalPayload is Map && jadwalPayload['props'] is Map) {
          final props = jadwalPayload['props'];
          final rawJadwal = props['jadwal'];
          final kelasInfo =
              (props['kelasHarian'] is Map) ? props['kelasHarian'] : {};

          if (rawJadwal is List) {
            for (final j in rawJadwal) {
              if (j is Map && j['tanggal'] == todayStr) {
                final rawM = j['jam_mulai'] ??
                    kelasInfo['jam_mulai'] ??
                    c['jam_mulai'] ??
                    '08:00';
                final rawS = j['jam_selesai'] ??
                    kelasInfo['jam_selesai'] ??
                    c['jam_selesai'] ??
                    '10:00';

                return <String, dynamic>{
                  'kode_kelas_harian': kode,
                  'nama_kelas': kelasInfo['nama_kelas'] ??
                      c['nama_kelas'] ??
                      c['matakuliah'] ??
                      'Mata Kuliah',
                  'jam_mulai': rawM.toString(),
                  'jam_selesai': rawS.toString(),
                  'dosen': kelasInfo['dosen'] ?? c['dosen'],
                  'nama_dosen':
                      kelasInfo['nama_dosen'] ?? c['nama_dosen'],
                  'ruang': kelasInfo['ruang'] ?? c['ruang'] ?? '',
                  'jadwal_id': j['id'],
                  'kode_unik': j['kode_unik'],
                  'absensi_harians': j['absensi_harians'] ?? [],
                  'is_today_schedule': true,
                };
              }
            }
          }
        }
      } catch (e) {
        debugPrint(
          '[resolveTodayClassesFromAbsensi] Gagal memuat jadwal untuk $kode: $e',
        );
      }
      return null;
    });

    final results = await Future.wait(futures);
    final resolved = results.whereType<Map<String, dynamic>>().toList();

    // Urutkan jadwal: paling pagi di atas
    resolved.sort((a, b) {
      final aStart = parseMinutes(a['jam_mulai'] ?? '00:00') ?? 0;
      final bStart = parseMinutes(b['jam_mulai'] ?? '00:00') ?? 0;
      return aStart.compareTo(bStart);
    });

    return resolved;
  }

  /// Ekstraksi list kelas dari satu objek sumber data LMS (Inertia payload)
  static List<dynamic> _extractFromSingleSource(dynamic source) {
    if (source == null) return [];
    if (source is List) return List.from(source);

    if (source is Map) {
      final Map root = (source['props'] is Map) ? source['props'] : source;

      const candidateKeys = [
        'kelas',
        'kelas_harian',
        'kelases',
        'kelas_list',
        'jadwal',
        'jadwals',
        'jadwal_harian',
        'jadwal_kuliah',
        'jadwal_hari_ini',
        'classes',
        'today_classes',
        'data',
      ];

      for (final key in candidateKeys) {
        final val = root[key];
        if (val is List && val.isNotEmpty) {
          return List.from(val);
        } else if (val is Map) {
          if (val['data'] is List && (val['data'] as List).isNotEmpty) {
            return List.from(val['data']);
          }
          if (val['kelas'] is List && (val['kelas'] as List).isNotEmpty) {
            return List.from(val['kelas']);
          }
        }
      }
    }
    return [];
  }

  /// Ekstraksi dan pengurutan daftar kelas harian berdasarkan jam mulai.
  /// Mendukung multi-source fallback: jika kelasData kosong di pagi hari sebelum presensi dibuka,
  /// fungsi akan otomatis mengambil data jadwal dari dashboardData maupun absensiData.
  static List<dynamic> extractClassesList(
    dynamic kelasData, {
    dynamic dashboardData,
    dynamic absensiData,
  }) {
    List<dynamic> listKelas = _extractFromSingleSource(kelasData);

    // Fallback: Jika kelasData masih kosong di pagi hari, coba ekstrak dari dashboardData
    if (listKelas.isEmpty && dashboardData != null) {
      listKelas = _extractFromSingleSource(dashboardData);
    }

    // Fallback: Coba ekstrak dari absensiData jika tersedia
    if (listKelas.isEmpty && absensiData != null) {
      listKelas = _extractFromSingleSource(absensiData);
    }

    // Normalisasi dan deduplikasi item kelas
    final Set<String> seenCodes = {};
    final List<dynamic> uniqueClasses = [];

    for (final item in listKelas) {
      if (item is! Map) continue;
      final code = (item['kode_kelas_harian'] ??
              item['kode_kelas'] ??
              item['id'] ??
              item['nama_kelas'] ??
              item['matakuliah'] ??
              '')
          .toString()
          .trim();

      if (code.isNotEmpty) {
        if (!seenCodes.contains(code)) {
          seenCodes.add(code);
          uniqueClasses.add(item);
        }
      } else {
        uniqueClasses.add(item);
      }
    }

    // Urutkan jadwal: paling pagi di atas, paling sore di bawah
    uniqueClasses.sort((a, b) {
      final aMap = a is Map ? a : {};
      final bMap = b is Map ? b : {};
      final aStart =
          parseMinutes((aMap['jam_mulai'] ?? '00:00').toString()) ?? 0;
      final bStart =
          parseMinutes((bMap['jam_mulai'] ?? '00:00').toString()) ?? 0;
      return aStart.compareTo(bStart);
    });

    return uniqueClasses;
  }

  /// Ekstraksi nama dosen dari berbagai kemungkinan format payload LMS
  static String extractDosenName(dynamic rawDosen, dynamic rawNamaDosen) {
    if (rawNamaDosen != null && rawNamaDosen.toString().trim().isNotEmpty) {
      return rawNamaDosen.toString().trim();
    }
    if (rawDosen is Map) {
      return rawDosen['user']?['name']?.toString() ??
          rawDosen['name']?.toString() ??
          'Dosen Pengampu';
    }
    if (rawDosen is List && rawDosen.isNotEmpty && rawDosen.first is Map) {
      final first = rawDosen.first as Map;
      return first['user']?['name']?.toString() ??
          first['name']?.toString() ??
          'Dosen Pengampu';
    }
    return 'Dosen Pengampu';
  }

  /// Pemetaan visual ikon dan warna untuk mata kuliah berdasarkan kata kunci
  static ({IconData icon, String? svgAsset, Color color, Color bg})
  getMapelIcon(String namaKelas) {
    final lower = namaKelas.toLowerCase();

    // 1. TRPL
    if (lower.contains('trpl')) {
      return (
        icon: Icons.code_rounded,
        svgAsset: null,
        color: const Color(0xFF1F81FF),
        bg: const Color(0xFFEBF3FF),
      );
    }

    // 2. TRKJ
    if (lower.contains('trkj')) {
      return (
        icon: Icons.router_rounded,
        svgAsset: null,
        color: const Color(0xFF0284C7),
        bg: const Color(0xFFF0F9FF),
      );
    }

    // 3. TRMG
    if (lower.contains('trmg')) {
      return (
        icon: Icons.draw_rounded,
        svgAsset: null,
        color: const Color(0xFF7C3AED),
        bg: const Color(0xFFF5F3FF),
      );
    }

    // 4. English
    if (lower.contains('english') || lower.contains('inggris')) {
      return (
        icon: Icons.translate_rounded,
        svgAsset: 'assets/icon/bahasa.svg',
        color: const Color(0xFF4F46E5),
        bg: const Color(0xFFEFF6FF),
      );
    }

    // 5. Diniah / Diniyah
    if (lower.contains('dini') ||
        lower.contains('syariah') ||
        lower.contains('islam')) {
      return (
        icon: Icons.mosque_rounded,
        svgAsset: 'assets/icon/diniah.svg',
        color: const Color(0xFF0D9488),
        bg: const Color(0xFFF0FDFA),
      );
    }

    // 6. Tahfiz / Tahfidz
    if (lower.contains('tahf') || lower.contains('qur')) {
      return (
        icon: Icons.import_contacts_rounded,
        svgAsset: 'assets/icon/tahfiz.svg',
        color: const Color(0xFF16A34A),
        bg: const Color(0xFFF0FDF4),
      );
    }

    // Default icon
    return (
      icon: Icons.school_rounded,
      svgAsset: null,
      color: const Color(0xFF1F81FF),
      bg: const Color(0xFFEBF3FF),
    );
  }
}
