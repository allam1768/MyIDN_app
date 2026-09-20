import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/lms_api_service.dart';

/// Provider detail tugas per kode kelas (Auto-cached & deklaratif)
final detailTugasProvider = FutureProvider.autoDispose.family<dynamic, String>((
  ref,
  kodeKelas,
) {
  final api = ref.watch(lmsApiServiceProvider);
  return api.getDetailTugasHarian(kodeKelas);
});

class TugasSubmitState {
  final bool isSubmitting;
  final String? errorMessage;
  final bool? isSuccess;

  const TugasSubmitState({
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess,
  });
}

class TugasSubmitController extends StateNotifier<TugasSubmitState> {
  final LmsApiService _apiService;

  TugasSubmitController(this._apiService) : super(const TugasSubmitState());

  Future<bool> submit({
    required dynamic tugasHarianId,
    required String kodeKelasHarian,
    required String linkTugas,
    String? kendala,
  }) async {
    state = const TugasSubmitState(isSubmitting: true);

    try {
      final res = await _apiService.submitTugasHarian(
        tugasHarianId: tugasHarianId,
        kodeKelasHarian: kodeKelasHarian,
        linkTugas: linkTugas,
        kendala: kendala,
      );

      final isSuccess = res['isSuccess'] == true;
      String? errorMsg;
      if (!isSuccess) {
        final data = res['data'];
        if (data is Map) {
          final flash = data['props']?['flash'];
          if (flash is Map && flash['error'] != null) {
            errorMsg = flash['error'].toString();
          } else if (data['props']?['errors'] is Map) {
            final errors = data['props']['errors'] as Map;
            if (errors.isNotEmpty) {
              errorMsg = errors.values.first.toString();
            }
          } else if (data['message'] != null) {
            errorMsg = data['message'].toString();
          }
        }
        errorMsg ??= 'Gagal mengirim tugas (Status: ${res['statusCode']})';
      }

      state = TugasSubmitState(
        isSubmitting: false,
        isSuccess: isSuccess,
        errorMessage: errorMsg,
      );
      return isSuccess;
    } catch (e) {
      state = TugasSubmitState(
        isSubmitting: false,
        isSuccess: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final tugasSubmitControllerProvider =
    StateNotifierProvider.autoDispose<TugasSubmitController, TugasSubmitState>((
      ref,
    ) {
      final api = ref.watch(lmsApiServiceProvider);
      return TugasSubmitController(api);
    });
