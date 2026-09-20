import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/lms_api_service.dart';

/// Provider detail materi per kode kelas (Auto-cached & deklaratif)
final detailMateriProvider = FutureProvider.autoDispose.family<dynamic, String>(
  (ref, kodeKelas) {
    final api = ref.watch(lmsApiServiceProvider);
    return api.getDetailMateriHarian(kodeKelas);
  },
);
