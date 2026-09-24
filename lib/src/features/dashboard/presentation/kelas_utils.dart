import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Utilitas pemrosesan jadwal dan presentasi kelas
class KelasUtils {
  KelasUtils._();

  static const String _keyCachedSchedule = 'cached_schedule_today';
  static const String _keyCachedScheduleDate = 'cached_schedule_date';

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
    } catch (_) {}
  }

  /// Mengambil snapshot jadwal kelas tersimpan jika tanggal hari ini cocok
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
          if (decoded is List) return decoded;
        }
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
  /// fungsi akan otomatis mengambil data jadwal dari dashboardData.
  static List<dynamic> extractClassesList(
    dynamic kelasData, {
    dynamic dashboardData,
  }) {
    List<dynamic> listKelas = _extractFromSingleSource(kelasData);

    // Fallback: Jika kelasData masih kosong di pagi hari, coba ekstrak dari dashboardData
    if (listKelas.isEmpty && dashboardData != null) {
      listKelas = _extractFromSingleSource(dashboardData);
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
