/// Model data informasi pembaruan versi aplikasi dari GitHub Releases
class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool hasUpdate;
  final String releaseTitle;
  final String releaseNotes;
  final String downloadUrl;
  final String htmlUrl;
  final DateTime? publishedAt;
  final bool isForceUpdate;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.hasUpdate,
    required this.releaseTitle,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.htmlUrl,
    this.publishedAt,
    this.isForceUpdate = false,
  });

  @override
  String toString() =>
      'AppUpdateInfo(current: $currentVersion, latest: $latestVersion, hasUpdate: $hasUpdate, isForceUpdate: $isForceUpdate)';
}
