import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/lms_api_service.dart';

/// Provider data pertanyaan form ibadah per tanggal (Auto-cached & deklaratif)
final formIbadahProvider = FutureProvider.autoDispose
    .family<List<dynamic>, String>((ref, tanggal) async {
      final api = ref.watch(lmsApiServiceProvider);
      final data = await api.getFormIbadahHarian(tanggal: tanggal);

      List<dynamic> list = [];
      if (data is Map && data['props'] is Map) {
        final props = data['props'];
        if (props['pertanyaans'] is Map &&
            props['pertanyaans']['umum'] is List) {
          list = props['pertanyaans']['umum'];
        }
      }
      return list;
    });

/// Controller untuk submit laporan ibadah harian
class IbadahSubmitState {
  final bool isSubmitting;
  final String? errorMessage;
  final bool? isSuccess;

  const IbadahSubmitState({
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess,
  });
}

class IbadahSubmitController extends StateNotifier<IbadahSubmitState> {
  final LmsApiService _apiService;

  IbadahSubmitController(this._apiService) : super(const IbadahSubmitState());

  Future<bool> submit({
    required String tanggalLaporan,
    required bool isHaid,
    required Map<String, dynamic> answers,
  }) async {
    state = const IbadahSubmitState(isSubmitting: true);

    try {
      final res = await _apiService.submitLaporanIbadahHarian(
        tanggalLaporan: tanggalLaporan,
        isHaid: isHaid,
        answers: answers,
      );

      final isSuccess = res['isSuccess'] == true;
      state = IbadahSubmitState(
        isSubmitting: false,
        isSuccess: isSuccess,
        errorMessage: isSuccess
            ? null
            : 'Gagal mengirim laporan (${res['statusCode']})',
      );
      return isSuccess;
    } catch (e) {
      state = IbadahSubmitState(
        isSubmitting: false,
        isSuccess: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final ibadahSubmitControllerProvider =
    StateNotifierProvider.autoDispose<
      IbadahSubmitController,
      IbadahSubmitState
    >((ref) {
      final api = ref.watch(lmsApiServiceProvider);
      return IbadahSubmitController(api);
    });
