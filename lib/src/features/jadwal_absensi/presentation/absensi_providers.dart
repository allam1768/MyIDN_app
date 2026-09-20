import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/lms_api_service.dart';

/// Provider data jadwal absensi bulanan per kelas (Auto-cached & deklaratif)
final listJadwalAbsensiProvider = FutureProvider.autoDispose
    .family<dynamic, ({String kodeKelas, String? monthParam})>((ref, arg) {
      final api = ref.watch(lmsApiServiceProvider);
      return api.getListJadwalAbsensi(
        arg.kodeKelas,
        monthParam: arg.monthParam,
      );
    });

/// Controller untuk submit presensi absensi
class PresensiSubmitState {
  final bool isSubmitting;
  final String? errorMessage;
  final bool? isSuccess;

  const PresensiSubmitState({
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess,
  });
}

class PresensiSubmitController extends StateNotifier<PresensiSubmitState> {
  final LmsApiService _apiService;

  PresensiSubmitController(this._apiService)
    : super(const PresensiSubmitState());

  Future<bool> submit({required int jadwalId, required String kodeUnik}) async {
    state = const PresensiSubmitState(isSubmitting: true);

    try {
      final res = await _apiService.submitPresensi(
        kodeUnik: kodeUnik,
        jadwalId: jadwalId,
      );

      final isSuccess = res['isSuccess'] == true;
      state = PresensiSubmitState(
        isSubmitting: false,
        isSuccess: isSuccess,
        errorMessage: isSuccess
            ? null
            : 'Presensi gagal (${res['statusCode']})',
      );
      return isSuccess;
    } catch (e) {
      state = PresensiSubmitState(
        isSubmitting: false,
        isSuccess: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final presensiSubmitControllerProvider =
    StateNotifierProvider.autoDispose<
      PresensiSubmitController,
      PresensiSubmitState
    >((ref) {
      final api = ref.watch(lmsApiServiceProvider);
      return PresensiSubmitController(api);
    });
