import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/lms_api_service.dart';

/// Provider detail materi per kode kelas harian (Auto-cached & deklaratif)
final detailMateriProvider = FutureProvider.autoDispose.family<dynamic, String>(
  (ref, kodeKelas) {
    final api = ref.watch(lmsApiServiceProvider);
    return api.getDetailMateriHarian(kodeKelas);
  },
);

/// Provider detail materi per kode kelas matkul dosen (Semester Reguler)
final detailMateriMatkulProvider =
    FutureProvider.autoDispose.family<dynamic, String>((ref, kodeKelas) {
  final api = ref.watch(lmsApiServiceProvider);
  return api.getDetailMateriMatkul(kodeKelas);
});

/// Provider list materi matkul dosen
final materiMatkulProvider = FutureProvider.autoDispose<dynamic>((ref) {
  final api = ref.watch(lmsApiServiceProvider);
  return api.getMateriMatkul();
});
