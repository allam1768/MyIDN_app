import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/src/features/dashboard/application/daily_briefing_engine.dart';
import 'package:reminder/src/features/update/application/app_update_service.dart';
import 'package:reminder/src/features/update/domain/models/app_update_info.dart';

void main() {
  group('AppUpdateService.isNewerVersion Tests', () {
    test('detects newer patch versions correctly', () {
      expect(AppUpdateService.isNewerVersion('1.0.1', '1.0.0'), isTrue);
      expect(AppUpdateService.isNewerVersion('1.0.10', '1.0.2'), isTrue);
    });

    test('detects newer minor and major versions correctly', () {
      expect(AppUpdateService.isNewerVersion('1.1.0', '1.0.5'), isTrue);
      expect(AppUpdateService.isNewerVersion('2.0.0', '1.9.9'), isTrue);
    });

    test('returns false when latest is equal or older', () {
      expect(AppUpdateService.isNewerVersion('1.0.0', '1.0.0'), isFalse);
      expect(AppUpdateService.isNewerVersion('0.9.9', '1.0.0'), isFalse);
      expect(AppUpdateService.isNewerVersion('1.0.0', '1.0.1'), isFalse);
    });

    test('handles prefixes v/V and build metadata smoothly', () {
      expect(AppUpdateService.isNewerVersion('v1.0.2', '1.0.0'), isTrue);
      expect(AppUpdateService.isNewerVersion('V2.1.0', 'v1.0.0'), isTrue);
      expect(AppUpdateService.isNewerVersion('v1.0.0+2', '1.0.0+1'), isFalse);
      expect(AppUpdateService.isNewerVersion('v1.0.1+5', '1.0.0'), isTrue);
    });

    test('returns false for empty or malformed strings (Fail-Fast)', () {
      expect(AppUpdateService.isNewerVersion('', '1.0.0'), isFalse);
      expect(AppUpdateService.isNewerVersion('1.0.0', ''), isFalse);
      expect(AppUpdateService.isNewerVersion('invalid', '1.0.0'), isFalse);
    });
  });

  group('AppUpdateInfo Model Tests', () {
    test('initializes and holds update state properly', () {
      final info = AppUpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.0.1',
        hasUpdate: true,
        releaseTitle: 'Rilis Perbaikan & Fitur Baru',
        releaseNotes: 'Memperbaiki presensi dan pengingat harian',
        downloadUrl:
            'https://github.com/allam1768/MyIDN_app/releases/download/v1.0.1/app-release.apk',
        htmlUrl: 'https://github.com/allam1768/MyIDN_app/releases/tag/v1.0.1',
        publishedAt: DateTime(2026, 9, 20),
      );

      expect(info.currentVersion, '1.0.0');
      expect(info.latestVersion, '1.0.1');
      expect(info.hasUpdate, isTrue);
      expect(info.downloadUrl, contains('.apk'));
      expect(info.releaseTitle, contains('Rilis'));
    });
  });

  group('DailyBriefingEngine Update Card Integration Tests', () {
    test('includes UPDATE TERSEDIA item when update is available', () {
      const info = AppUpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.0.1',
        hasUpdate: true,
        releaseTitle: 'v1.0.1',
        releaseNotes: 'Catatan rilis',
        downloadUrl: 'https://github.com/...',
        htmlUrl: 'https://github.com/...',
      );

      final items = DailyBriefingEngine.resolveItems(
        listKelas: [],
        listTugas: [],
        nowMinutes: 600,
        isIbadahDone: true,
        isKebaikanDone: true,
        updateInfo: info,
      );

      final hasUpdateBadge = items.any(
        (item) => item.badge == 'UPDATE TERSEDIA',
      );
      expect(hasUpdateBadge, isTrue);
      final updateItem = items.firstWhere(
        (item) => item.badge == 'UPDATE TERSEDIA',
      );
      expect(updateItem.title, contains('v1.0.1'));
    });

    test('does not include UPDATE TERSEDIA item when no update available', () {
      final items = DailyBriefingEngine.resolveItems(
        listKelas: [],
        listTugas: [],
        nowMinutes: 600,
        isIbadahDone: true,
        isKebaikanDone: true,
        updateInfo: null,
      );

      final hasUpdateBadge = items.any(
        (item) => item.badge == 'UPDATE TERSEDIA',
      );
      expect(hasUpdateBadge, isFalse);
    });
  });
}
