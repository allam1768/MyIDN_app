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
      expect(info.isForceUpdate, isFalse);
      expect(info.downloadUrl, contains('.apk'));
      expect(info.releaseTitle, contains('Rilis'));
    });
  });

  group('AppUpdateService.checkIsForceUpdate Tests', () {
    test('detects urgent keywords in title or notes correctly', () {
      expect(
        AppUpdateService.checkIsForceUpdate(
          title: 'Rilis v1.0.1 [URGENT]',
          body: 'Perbaikan API',
        ),
        isTrue,
      );
      expect(
        AppUpdateService.checkIsForceUpdate(
          title: 'Rilis v1.0.1',
          body: 'Catatan: [WAJIB] Harap segera update',
        ),
        isTrue,
      );
      expect(
        AppUpdateService.checkIsForceUpdate(
          title: 'Pembaruan (Urgent)',
          body: 'Penting',
        ),
        isTrue,
      );
      expect(
        AppUpdateService.checkIsForceUpdate(
          title: 'MyIDN Update',
          body: 'Wajib update untuk perbaikan bug absensi',
        ),
        isTrue,
      );
      expect(
        AppUpdateService.checkIsForceUpdate(
          title: 'Pembaruan Force Update',
          body: 'Perubahan struktur data',
        ),
        isTrue,
      );
    });

    test('returns false when no urgent keywords are present', () {
      expect(
        AppUpdateService.checkIsForceUpdate(
          title: 'Rilis v1.0.1',
          body: 'Penambahan tema baru dan optimasi performa',
        ),
        isFalse,
      );
    });
  });

  group('DailyBriefingEngine Update Card Integration Tests', () {
    test('includes UPDATE TERSEDIA item when update is regular', () {
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

    test('includes UPDATE WAJIB item when update is force update', () {
      const info = AppUpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.0.1',
        hasUpdate: true,
        isForceUpdate: true,
        releaseTitle: 'v1.0.1 [URGENT]',
        releaseNotes: 'Pembaruan darurat',
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

      final hasUrgentBadge = items.any(
        (item) => item.badge == 'UPDATE WAJIB',
      );
      expect(hasUrgentBadge, isTrue);
      final updateItem = items.firstWhere(
        (item) => item.badge == 'UPDATE WAJIB',
      );
      expect(updateItem.title, contains('Kritis'));
      expect(updateItem.buttonText, 'Pasang Sekarang');
    });

    test('does not include UPDATE TERSEDIA or WAJIB item when no update available', () {
      final items = DailyBriefingEngine.resolveItems(
        listKelas: [],
        listTugas: [],
        nowMinutes: 600,
        isIbadahDone: true,
        isKebaikanDone: true,
        updateInfo: null,
      );

      final hasUpdateBadge = items.any(
        (item) => item.badge == 'UPDATE TERSEDIA' || item.badge == 'UPDATE WAJIB',
      );
      expect(hasUpdateBadge, isFalse);
    });
  });

  group('AppUpdateService.resolveDownloadUrl Tests', () {
    test('prioritizes versioned APK over generic release APK', () {
      final assets = [
        {
          'name': 'MyIDN-release.apk',
          'browser_download_url':
              'https://github.com/allam1768/MyIDN_app/releases/download/v1.0.3/MyIDN-release.apk',
        },
        {
          'name': 'MyIDN-v1.0.3.apk',
          'browser_download_url':
              'https://github.com/allam1768/MyIDN_app/releases/download/v1.0.3/MyIDN-v1.0.3.apk',
        },
      ];

      final url = AppUpdateService.resolveDownloadUrl(
        assets,
        cleanTag: '1.0.3',
      );

      expect(url, contains('MyIDN-v1.0.3.apk'));
      expect(url, isNot(contains('MyIDN-release.apk')));
    });

    test('selects versioned APK regardless of asset order', () {
      final assets = [
        {
          'name': 'MyIDN-v1.0.3.apk',
          'browser_download_url':
              'https://github.com/allam1768/MyIDN_app/releases/download/v1.0.3/MyIDN-v1.0.3.apk',
        },
        {
          'name': 'MyIDN-release.apk',
          'browser_download_url':
              'https://github.com/allam1768/MyIDN_app/releases/download/v1.0.3/MyIDN-release.apk',
        },
      ];

      final url = AppUpdateService.resolveDownloadUrl(
        assets,
        cleanTag: '1.0.3',
      );

      expect(url, contains('MyIDN-v1.0.3.apk'));
    });

    test('falls back to generic APK if no versioned APK exists', () {
      final assets = [
        {
          'name': 'MyIDN-release.apk',
          'browser_download_url':
              'https://github.com/allam1768/MyIDN_app/releases/download/v1.0.3/MyIDN-release.apk',
        },
      ];

      final url = AppUpdateService.resolveDownloadUrl(
        assets,
        cleanTag: '1.0.3',
      );

      expect(url, contains('MyIDN-release.apk'));
    });

    test('falls back to fallbackUrl when no APK exists in assets', () {
      const fallback = 'https://github.com/allam1768/MyIDN_app/releases/tag/v1.0.3';
      final url = AppUpdateService.resolveDownloadUrl(
        [],
        cleanTag: '1.0.3',
        fallbackUrl: fallback,
      );

      expect(url, fallback);
    });
  });
}
