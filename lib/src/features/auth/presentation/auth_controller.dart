import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/lms_api_service.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final LmsApiService _apiService;

  AuthController(this._apiService) : super(const AuthState());

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final isValid = await _apiService.validateSessionWithServer();
      if (isValid) {
        state = state.copyWith(isLoading: false, isAuthenticated: true);
      } else {
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
    }
  }

  Future<void> login({required String nim, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final success = await _apiService.login(nim, password);

      if (success) {
        state = state.copyWith(isLoading: false, isAuthenticated: true);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'NIM atau password salah.',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('DioException caught: ${e.type} | ${e.message}');
      }
      String message;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Koneksi timeout. Silakan periksa jaringan Anda.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Gagal terhubung ke server LMS. Periksa internet / VPN.';
      } else if (e.response?.statusCode == 419) {
        message = 'Sesi CSRF kadaluarsa. Silakan coba lagi.';
      } else if (e.response?.statusCode == 422) {
        message = 'Format NIM atau password tidak sesuai.';
      } else {
        message =
            'Gagal terhubung ke LMS (${e.response?.statusCode ?? "Koneksi Bermasalah"}).';
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Terjadi kesalahan sistem: $e',
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _apiService.logout();
    state = const AuthState(isAuthenticated: false);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final apiService = ref.watch(lmsApiServiceProvider);
    return AuthController(apiService);
  },
);
