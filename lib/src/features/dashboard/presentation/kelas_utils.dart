import 'package:flutter/material.dart';

/// Utilitas pemrosesan jadwal dan presentasi kelas
class KelasUtils {
  KelasUtils._();

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

  /// Ekstraksi dan pengurutan daftar kelas harian berdasarkan jam mulai
  static List<dynamic> extractClassesList(dynamic kelasData) {
    if (kelasData == null) return [];

    List<dynamic> listKelas = [];
    if (kelasData is Map && kelasData['props'] is Map) {
      final props = kelasData['props'];
      dynamic raw =
          props['kelas']?['data'] ??
          props['kelas_harian'] ??
          props['kelases'] ??
          props['kelas'];
      if (raw is Map && raw['data'] is List) {
        raw = raw['data'];
      }
      if (raw is List) {
        listKelas = List.from(raw);
      }
    }

    // Urutkan jadwal: paling pagi di atas, paling sore di bawah
    listKelas.sort((a, b) {
      final aMap = a is Map ? a : {};
      final bMap = b is Map ? b : {};
      final aStart =
          parseMinutes((aMap['jam_mulai'] ?? '00:00').toString()) ?? 0;
      final bStart =
          parseMinutes((bMap['jam_mulai'] ?? '00:00').toString()) ?? 0;
      return aStart.compareTo(bStart);
    });

    return listKelas;
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
