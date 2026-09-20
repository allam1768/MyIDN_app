/// Kumpulan helper terpusat untuk evaluasi kondisi status data dashboard (DRY)
class DashboardHelpers {
  DashboardHelpers._();

  /// Mengecek apakah laporan ibadah harian sudah selesai / terkirim hari ini.
  /// Mencegah duplikasi pengecekan Map/props yang sebelumnya tersebar di berbagai file.
  static bool isIbadahDone(dynamic ibadahData) {
    if (ibadahData is! Map) return false;

    final props = ibadahData['props'];
    if (props is! Map) return false;

    final statuses = props['laporanStatuses'];
    if (statuses is List && statuses.isNotEmpty) {
      final first = statuses.first;
      if (first is Map) {
        final status = (first['status'] ?? '').toString().trim().toLowerCase();
        return status.contains('terkirim') ||
            status.contains('selesai') ||
            status.contains('done') ||
            status.contains('submitted');
      }
    }

    return false;
  }

  /// Mengecek apakah suatu tugas sudah selesai dikerjakan / dikumpulkan.
  static bool isTaskCompleted(dynamic task) {
    if (task is! Map) return false;

    // 1. Cek dari daftar pengumpulan tugas
    final dynamic rawSubmissions =
        task['pengumpulan_tugas_harians'] ??
        task['pengumpulan_tugas'] ??
        task['pengumpulan'] ??
        task['submissions'] ??
        task['submission'];

    if ((rawSubmissions is List && rawSubmissions.isNotEmpty) ||
        (rawSubmissions is Map && rawSubmissions.isNotEmpty)) {
      return true;
    }

    // 2. Cek dari field status
    final status = (task['status'] ?? '').toString().toLowerCase().trim();
    return status.contains('selesai') ||
        status.contains('terkirim') ||
        status.contains('sudah') ||
        status.contains('submitted') ||
        status.contains('done');
  }
}
