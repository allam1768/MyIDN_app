/// Utilitas pemformatan tanggal terpusat (DRY & Fail Fast)
class AppDateUtils {
  AppDateUtils._();

  static const List<String> namaBulanIndo = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> namaHariIndo = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  /// Format string tanggal "YYYY-MM-DD" atau DateTime menjadi "Hari, DD Bulan YYYY"
  /// Contoh: "2026-09-15" -> "Selasa, 15 September 2026"
  static String formatDateIndo(dynamic dateInput) {
    if (dateInput == null) return '-';

    DateTime? dt;
    if (dateInput is DateTime) {
      dt = dateInput;
    } else if (dateInput is String) {
      if (dateInput.trim().isEmpty) return '-';
      try {
        final parts = dateInput.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.tryParse(parts[1]) ?? 1;
          final day = int.tryParse(parts[2]) ?? 1;
          if (month >= 1 && month <= 12) {
            dt = DateTime(year, month, day);
          }
        } else {
          dt = DateTime.tryParse(dateInput);
        }
      } catch (_) {
        return '-';
      }
    }

    if (dt == null) return '-';

    final dayName = namaHariIndo[dt.weekday - 1];
    final monthName = namaBulanIndo[dt.month - 1];
    return '$dayName, ${dt.day} $monthName ${dt.year}';
  }

  /// Format tanggal tanpa nama hari: "DD Bulan YYYY"
  /// Contoh: "15 September 2026"
  static String formatShortDateIndo(dynamic dateInput) {
    if (dateInput == null) return '-';

    DateTime? dt;
    if (dateInput is DateTime) {
      dt = dateInput;
    } else if (dateInput is String) {
      dt = DateTime.tryParse(dateInput);
    }

    if (dt == null) return '-';
    final monthName = namaBulanIndo[dt.month - 1];
    return '${dt.day} $monthName ${dt.year}';
  }
}
