import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/lms_api_service.dart';
import '../../poin_kebaikan/data/poin_kebaikan_data.dart';
import 'kelas_utils.dart';

/// Provider data kelas harian mahasiswa (Auto-cached & deklaratif, dengan Morning Fallback Resolver)
final kelasHarianProvider = FutureProvider.autoDispose<dynamic>((ref) async {
  final api = ref.watch(lmsApiServiceProvider);

  // 1. Coba ambil data kelas harian langsung dari server
  dynamic kelasData;
  try {
    kelasData = await api.getKelasHarian();
  } catch (e) {
    debugPrint('[kelasHarianProvider] Gagal getKelasHarian: $e');
  }

  // Cek apakah data dari kelas_harian sudah berisi kelas
  final extracted = KelasUtils.extractClassesList(kelasData);
  if (extracted.isNotEmpty) {
    // Fast path: server sudah memiliki daftar kelas aktif hari ini
    await KelasUtils.cacheScheduleToday(extracted);
    return kelasData;
  }

  // 2. MORNING FALLBACK RESOLVER:
  // Di pagi hari sebelum mahasiswa presensi kelas pertama, endpoint kelas_harian
  // seringkali belum terisi ([]). Kita selesaikan dengan mengambil daftar kelas terdaftar
  // dari absensi_harian lalu mencocokkan jadwal hari ini secara paralel.
  debugPrint(
    '[kelasHarianProvider] Kelas harian kosong di pagi hari. Memulai Morning Fallback Resolver...',
  );

  try {
    // Ambil data absensi harian (daftar kelas semester aktif)
    dynamic absensiData;
    try {
      absensiData = await api.getAbsensiHarian();
    } catch (e) {
      debugPrint('[kelasHarianProvider] Gagal getAbsensiHarian: $e');
    }

    final List<dynamic> enrolledClasses = [];
    if (absensiData is Map && absensiData['props'] is Map) {
      final props = absensiData['props'];
      final raw = props['kelas']?['data'] ??
          props['kelas'] ??
          props['kelases'] ??
          props['data'];
      if (raw is List) {
        enrolledClasses.addAll(raw);
      }
    }

    // Jika absensi_harian kosong, coba ambil dari tugas_harian
    if (enrolledClasses.isEmpty) {
      try {
        final tugasData = await api.getTugasHarian();
        if (tugasData is Map && tugasData['props'] is Map) {
          final props = tugasData['props'];
          final raw = props['kelas']?['data'] ??
              props['kelas'] ??
              props['kelases'] ??
              props['data'];
          if (raw is List) enrolledClasses.addAll(raw);
        }
      } catch (_) {}
    }

    if (enrolledClasses.isNotEmpty) {
      final resolvedTodayClasses =
          await KelasUtils.resolveTodayClassesFromAbsensi(
        enrolledClasses: enrolledClasses,
        fetchJadwalAbsensi: (kode) => api.getListJadwalAbsensi(kode),
      );

      if (resolvedTodayClasses.isNotEmpty) {
        debugPrint(
          '[kelasHarianProvider] Morning Fallback berhasil memuat ${resolvedTodayClasses.length} kelas hari ini!',
        );
        await KelasUtils.cacheScheduleToday(resolvedTodayClasses);

        final Map<String, dynamic> resultPayload = {
          'component': 'Mhs/Harian/KelasHarian/Index',
          'props': {
            'kelas': {
              'data': resolvedTodayClasses,
            },
            if (kelasData is Map && kelasData['props'] is Map)
              ...Map<String, dynamic>.from(kelasData['props'] as Map),
          },
        };
        return resultPayload;
      }
    }
  } catch (e) {
    debugPrint('[kelasHarianProvider] Error Morning Fallback Resolver: $e');
  }

  // 3. Fallback Offline Cache jika network gagal / belum ada kelas
  final cached = await KelasUtils.getCachedScheduleToday();
  if (cached.isNotEmpty) {
    debugPrint(
      '[kelasHarianProvider] Menggunakan cached schedule (${cached.length} kelas)',
    );
    return {
      'component': 'Mhs/Harian/KelasHarian/Index',
      'props': {
        'kelas': {
          'data': cached,
        },
        if (kelasData is Map && kelasData['props'] is Map)
          ...Map<String, dynamic>.from(kelasData['props'] as Map),
      },
    };
  }

  return kelasData;
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
    final todayClasses = KelasUtils.extractClassesList(
      todayKelasData,
      dashboardData: ref.read(dashboardMahasiswaProvider).valueOrNull,
    );
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

/// Provider snapshot jadwal kelas tersimpan (offline & morning fallback)
final cachedScheduleProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
      return KelasUtils.getCachedScheduleToday();
    });
