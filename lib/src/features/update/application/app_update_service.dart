import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/app_update_info.dart';

/// Layanan pengecekan pembaruan versi aplikasi dari GitHub Releases API
class AppUpdateService {
  /// Versi aplikasi saat ini (selaras dengan pubspec.yaml)
  static const String currentVersion = '1.0.0';

  static const String githubRepoOwner = 'allam1768';
  static const String githubRepoName = 'MyIDN_app';
  static const String latestReleaseApiUrl =
      'https://api.github.com/repos/$githubRepoOwner/$githubRepoName/releases/latest';
  static const String releasesWebUrl =
      'https://github.com/$githubRepoOwner/$githubRepoName/releases/latest';

  final Dio _dio;

  AppUpdateService([Dio? dio])
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                headers: {
                  'Accept': 'application/vnd.github.v3+json',
                  'User-Agent': 'MyIDN-App',
                },
              ),
            );

  /// Memeriksa pembaruan versi terbaru dari GitHub Releases
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final response = await _dio.get(latestReleaseApiUrl);
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final rawTag = (data['tag_name'] ?? '').toString();
        final cleanTag = rawTag.replaceAll(RegExp(r'^[vV]'), '').trim();
        final releaseTitle = (data['name'] ?? rawTag).toString();
        final releaseNotes = (data['body'] ??
                'Pembaruan versi terbaru aplikasi MyIDN telah tersedia di GitHub.')
            .toString();
        final htmlUrl = (data['html_url'] ?? releasesWebUrl).toString();

        // Cari tautan langsung berkas APK di dalam array assets
        // Prioritaskan berkas yang memuat nama versi (contoh: MyIDN-v1.0.3.apk) bukan file release generik
        final assets = data['assets'];
        final String downloadUrl = resolveDownloadUrl(
          assets is List ? assets : null,
          cleanTag: cleanTag,
          fallbackUrl: htmlUrl,
        );

        final bool hasUpdate = isNewerVersion(cleanTag, currentVersion);
        final bool isForceUpdate = hasUpdate &&
            checkIsForceUpdate(title: releaseTitle, body: releaseNotes);

        return AppUpdateInfo(
          currentVersion: currentVersion,
          latestVersion: cleanTag.isNotEmpty ? cleanTag : currentVersion,
          hasUpdate: hasUpdate,
          isForceUpdate: isForceUpdate,
          releaseTitle: releaseTitle,
          releaseNotes: releaseNotes,
          downloadUrl: downloadUrl,
          htmlUrl: htmlUrl,
          publishedAt:
              DateTime.tryParse(data['published_at']?.toString() ?? ''),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppUpdateService] Pengecekan pembaruan GitHub: $e');
      }
    }
    return null;
  }

  /// Menentukan URL unduhan APK terbaik dari daftar assets GitHub Release.
  /// Memprioritaskan berkas yang memuat nama versi (contoh: MyIDN-v1.0.3.apk)
  /// dan menghindari berkas generik 'release' jika versi spesifik tersedia.
  static String resolveDownloadUrl(
    List<dynamic>? assets, {
    String cleanTag = '',
    String fallbackUrl = releasesWebUrl,
  }) {
    if (assets == null || assets.isEmpty) return fallbackUrl;

    String? versionedApkUrl;
    String? genericApkUrl;
    final lowerTag = cleanTag.toLowerCase();

    for (final asset in assets) {
      if (asset is! Map) continue;
      final rawName = (asset['name'] ?? '').toString();
      final name = rawName.toLowerCase();
      final browserUrl = (asset['browser_download_url'] ?? '').toString();

      if (name.endsWith('.apk') && browserUrl.isNotEmpty) {
        // Cek apakah berkas memuat indikator versi spesifik
        final bool hasVersionInName = (lowerTag.isNotEmpty && name.contains(lowerTag)) ||
            RegExp(r'v?\d+\.\d+').hasMatch(name);
        final bool isGenericRelease = name.contains('release') && !name.contains(lowerTag);

        if (hasVersionInName && !isGenericRelease) {
          // Pilihan utama: berkas yang secara eksplisit memuat versi
          return browserUrl;
        } else if (hasVersionInName) {
          versionedApkUrl ??= browserUrl;
        } else {
          genericApkUrl ??= browserUrl;
        }
      }
    }

    return versionedApkUrl ?? genericApkUrl ?? fallbackUrl;
  }

  /// Mengecek apakah rilis ini merupakan pembaruan wajib / darurat (Force Update)
  static bool checkIsForceUpdate({
    required String title,
    required String body,
  }) {
    final lowerTitle = title.toLowerCase();
    final lowerBody = body.toLowerCase();
    const forceKeywords = [
      '[urgent]',
      '(urgent)',
      'force update',
      '[force]',
      '(force)',
      '[mandatory]',
      '(mandatory)',
      '[wajib]',
      '(wajib)',
      'wajib update',
      'wajib perbarui',
    ];

    for (final kw in forceKeywords) {
      if (lowerTitle.contains(kw) || lowerBody.contains(kw)) {
        return true;
      }
    }
    return false;
  }

  /// Membandingkan 2 format semver (contoh: "1.0.1" lebih baru daripada "1.0.0")
  static bool isNewerVersion(String latest, String current) {
    if (latest.trim().isEmpty || current.trim().isEmpty) return false;

    // Bersihkan prefix 'v' atau build metadata '+1'
    final cleanL = latest.replaceAll(RegExp(r'^[vV]'), '').split('+').first;
    final cleanC = current.replaceAll(RegExp(r'^[vV]'), '').split('+').first;

    final lParts = cleanL.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final cParts = cleanC.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final l = i < lParts.length ? lParts[i] : 0;
      final c = i < cParts.length ? cParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
}
