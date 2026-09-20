import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/lms_api_service.dart';
import '../../poin_kebaikan/data/poin_kebaikan_data.dart';
import 'kelas_utils.dart';

/// Provider data kelas harian mahasiswa (Auto-cached & deklaratif)
final kelasHarianProvider = FutureProvider.autoDispose<dynamic>((ref) {
  final api = ref.watch(lmsApiServiceProvider);
  return api.getKelasHarian();
});

/// Provider data tugas harian mahasiswa (Lengkap dengan auto-fetch tugas per kelas)
final tugasHarianProvider = FutureProvider.autoDispose<dynamic>((ref) async {
  final api = ref.watch(lmsApiServiceProvider);
  final indexData = await api.getTugasHarian();

  if (indexData is! Map) return indexData;

  final Map<String, dynamic> mutableData = Map<String, dynamic>.from(indexData);
  final Map<String, dynamic> props = (mutableData['props'] is Map)
      ? Map<String, dynamic>.from(mutableData['props'] as Map)
      : <String, dynamic>{};

  // Ekstrak daftar kelas dari tugas harian
  final dynamic rawClasses = props['kelas']?['data'] ?? props['kelas'];
  final List<dynamic> classesList = [];
  if (rawClasses is List) {
    classesList.addAll(rawClasses);
  }

  // Tambahkan juga kelas aktif hari ini dari kelasHarian jika belum ada di daftar
  final todayKelasData = ref.read(kelasHarianProvider).valueOrNull;
  if (todayKelasData != null) {
    final todayClasses = KelasUtils.extractClassesList(todayKelasData);
    for (final tc in todayClasses) {
      if (tc is Map) {
        final tKode = tc['kode_kelas_harian']?.toString() ?? '';
        final alreadyIn = classesList.any(
          (c) => c is Map && c['kode_kelas_harian']?.toString() == tKode,
        );
        if (!alreadyIn && tKode.isNotEmpty) {
          classesList.add(tc);
        }
      }
    }
  }

  if (classesList.isEmpty) return mutableData;

  final List<dynamic> allExtractedTasks = [];

  // Filter kelas yang memiliki tugas atau berpotensi memiliki tugas
  final classesWithTasks = classesList.where((c) {
    if (c is! Map) return false;
    final count = int.tryParse(c['tugas_harians_count']?.toString() ?? '');
    return count == null || count > 0;
  }).toList();

  if (classesWithTasks.isNotEmpty) {
    final futures = classesWithTasks.map((c) async {
      if (c is! Map) return <dynamic>[];
      final kode = c['kode_kelas_harian']?.toString() ?? '';
      final namaKelas = c['nama_kelas']?.toString() ?? '';
      if (kode.isEmpty) return <dynamic>[];

      try {
        final detail = await api.getDetailTugasHarian(kode);
        if (detail is Map && detail['props'] is Map) {
          final detailProps = detail['props'];
          final rawTugas =
              detailProps['tugas']?['data'] ??
              detailProps['tugas'] ??
              detailProps['tugass'] ??
              detailProps['tugas_harian'] ??
              detailProps['tugas_harians'] ??
              detailProps['daftar_tugas'] ??
              detailProps['data'];

          if (rawTugas is List) {
            final List<dynamic> list = [];
            for (final t in rawTugas) {
              if (t is Map) {
                final taskMap = Map<String, dynamic>.from(t);
                taskMap['nama_kelas'] ??= namaKelas;
                taskMap['kode_kelas_harian'] ??= kode;
                list.add(taskMap);
              }
            }
            c['tugas'] = list;
            c['tugas_harian'] = list;
            return list;
          }
        }
      } catch (e) {
        // Fail Fast: Log error untuk observabilitas tanpa memutus eksekusi kelas lain
        debugPrint('[tugasHarianProvider] Gagal memuat tugas kelas $kode: $e');
      }
      return <dynamic>[];
    });

    final results = await Future.wait(futures);
    for (final r in results) {
      allExtractedTasks.addAll(r);
    }
  }

  // Simpan allExtractedTasks ke dalam props agar diekstrak oleh DashboardUtils
  props['all_tugas'] = allExtractedTasks;
  props['tugas_harian'] = allExtractedTasks;
  mutableData['props'] = props;

  return mutableData;
});

/// Provider data absensi harian mahasiswa
final absensiHarianProvider = FutureProvider.autoDispose<dynamic>((ref) {
  final api = ref.watch(lmsApiServiceProvider);
  return api.getAbsensiHarian();
});

/// Provider data materi harian mahasiswa
final materiHarianProvider = FutureProvider.autoDispose<dynamic>((ref) {
  final api = ref.watch(lmsApiServiceProvider);
  return api.getMateriHarian();
});

/// Provider data laporan ibadah harian mahasiswa
final ibadahHarianProvider = FutureProvider.autoDispose<dynamic>((ref) {
  final api = ref.watch(lmsApiServiceProvider);
  return api.getLaporanIbadahHarian();
});

/// Provider data dashboard mahasiswa (jadwal, online, dll)
final dashboardMahasiswaProvider = FutureProvider.autoDispose<dynamic>((ref) {
  final api = ref.watch(lmsApiServiceProvider);
  return api.getDashboardMahasiswa();
});

/// Provider informasi sesi debug (token & header)
final debugSessionProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) {
  final api = ref.watch(lmsApiServiceProvider);
  return api.getDebugSessionInfo();
});

/// Provider status submit laporan poin kebaikan hari ini
final poinKebaikanStatusProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  return PoinKebaikanConfig.isDoneToday();
});
