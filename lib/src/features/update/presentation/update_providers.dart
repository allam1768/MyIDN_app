import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/app_update_service.dart';
import '../domain/models/app_update_info.dart';

/// Provider instance singleton AppUpdateService
final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService();
});

/// Provider pengecekan update otomatis di background (Auto-cached & deklaratif)
final appUpdateInfoProvider = FutureProvider<AppUpdateInfo?>((ref) async {
  final service = ref.watch(appUpdateServiceProvider);
  return service.checkForUpdate();
});
