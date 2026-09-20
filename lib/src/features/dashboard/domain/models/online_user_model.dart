class OnlineUserModel {
  final String name;
  final String device;
  final String lastActive;
  final String? avatar;
  final bool isOnline;

  const OnlineUserModel({
    required this.name,
    required this.device,
    required this.lastActive,
    this.avatar,
    this.isOnline = true,
  });

  factory OnlineUserModel.fromMap(dynamic raw) {
    if (raw is! Map) {
      return OnlineUserModel(
        name: raw?.toString() ?? 'Pengguna LMS',
        device: 'Web Browser',
        lastActive: 'Aktif',
      );
    }

    // 1. Ekstraksi Nama
    String name = '';
    if (raw['user'] is Map) {
      name =
          raw['user']['name']?.toString() ??
          raw['user']['nama']?.toString() ??
          '';
    }
    if (name.isEmpty) {
      name =
          raw['name']?.toString() ??
          raw['nama']?.toString() ??
          raw['username']?.toString() ??
          'Pengguna LMS';
    }

    // 2. Ekstraksi Device / Platform
    String device =
        raw['device']?.toString() ??
        raw['platform']?.toString() ??
        raw['browser']?.toString() ??
        raw['user_agent_platform']?.toString() ??
        '';
    if (device.isEmpty && raw['user_agent'] != null) {
      device = _parseUserAgent(raw['user_agent'].toString());
    }
    if (device.isEmpty) {
      device = 'Chrome on Android';
    }

    // 3. Ekstraksi Waktu Terakhir Aktif
    String time =
        raw['last_activity_human']?.toString() ??
        raw['last_activity']?.toString() ??
        raw['last_seen']?.toString() ??
        raw['time']?.toString() ??
        raw['selisih_waktu']?.toString() ??
        raw['created_at']?.toString() ??
        'Baru saja';

    if (int.tryParse(time) != null) {
      final ts = int.parse(time);
      final diff = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(ts * 1000),
      );
      if (diff.inMinutes < 1) {
        time = '1 mnt lalu';
      } else if (diff.inMinutes < 60) {
        time = '${diff.inMinutes} mnt lalu';
      } else {
        time = '${diff.inHours} jam lalu';
      }
    }

    // 4. Avatar
    String? avatar;
    if (raw['user'] is Map) {
      avatar =
          raw['user']['image']?.toString() ?? raw['user']['avatar']?.toString();
    }
    avatar ??= raw['image']?.toString() ?? raw['avatar']?.toString();

    return OnlineUserModel(
      name: name,
      device: device,
      lastActive: time,
      avatar: avatar,
    );
  }

  static String _parseUserAgent(String ua) {
    String browser = 'Browser';
    if (ua.contains('Firefox')) {
      browser = 'Firefox';
    } else if (ua.contains('Chrome')) {
      browser = 'Chrome';
    } else if (ua.contains('Safari') && !ua.contains('Chrome')) {
      browser = 'Safari';
    } else if (ua.contains('Edge') || ua.contains('Edg')) {
      browser = 'Edge';
    } else if (ua.contains('Opera') || ua.contains('OPR')) {
      browser = 'Opera';
    }

    String os = 'Device';
    if (ua.contains('Android')) {
      os = 'Android';
    } else if (ua.contains('Windows')) {
      os = 'Windows';
    } else if (ua.contains('Linux')) {
      os = 'Linux';
    } else if (ua.contains('iPhone') ||
        ua.contains('iPad') ||
        ua.contains('Macintosh')) {
      os = 'macOS/iOS';
    }

    return '$browser on $os';
  }
}
