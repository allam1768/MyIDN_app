import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  // Channel IDs
  static const String _classChannelId = 'channel_jadwal_kelas';
  static const String _classChannelName = 'Pengingat Jadwal Kelas';
  static const String _classChannelDesc =
      'Notifikasi pengingat sebelum jadwal kelas kuliah dimulai';

  static const String _nightlyChannelId = 'channel_pengingat_malam';
  static const String _nightlyChannelName = 'Pengingat Laporan Harian';
  static const String _nightlyChannelDesc =
      'Pengingat jam 10 malam untuk Laporan Ibadah & Poin Kebaikan';

  // Notification IDs
  static const int nightlyReminderId = 9999;
  static const int testNotificationId = 8888;
  static const int classBaseId = 1000;

  /// Inisialisasi plugin notifikasi dan timezone
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Inisialisasi timezone database
      try {
        tz.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {
        // Fallback jika zona tidak ditemukan
      }

      // 2. Setting platform
      const androidSettings = AndroidInitializationSettings('ic_notification');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint(
            '[NotificationService] Notifikasi diklik: ${details.payload}',
          );
        },
      );

      // 3. Buat notification channels di Android
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            _classChannelId,
            _classChannelName,
            description: _classChannelDesc,
            importance: Importance.high,
          ),
        );

        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            _nightlyChannelId,
            _nightlyChannelName,
            description: _nightlyChannelDesc,
            importance: Importance.high,
          ),
        );
      }

      _isInitialized = true;
      debugPrint('[NotificationService] Inisialisasi berhasil.');
    } catch (e) {
      debugPrint('[NotificationService] Gagal inisialisasi notifikasi: $e');
    }
  }

  static bool _permissionRequested = false;

  /// Meminta izin notifikasi sekali secara aman setelah antarmuka aktif
  static Future<bool> requestPermissionOnce() async {
    if (_permissionRequested) return true;
    _permissionRequested = true;
    return await requestPermission();
  }

  /// Meminta izin notifikasi (Android 13+ dan iOS)
  static Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await androidImpl?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosImpl = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// Menjadwalkan pengingat semua kelas untuk hari ini (15 menit sebelum jam mulai)
  static Future<void> scheduleClassesForToday(List<dynamic> classes) async {
    await init();

    // Batalkan pengingat kelas lama (id 1000 - 1050)
    for (int i = 0; i < 50; i++) {
      await _plugin.cancel(id: classBaseId + i);
    }

    if (classes.isEmpty) return;

    final now = tz.TZDateTime.now(tz.local);
    int scheduledCount = 0;

    for (int i = 0; i < classes.length; i++) {
      final item = classes[i];
      if (item is! Map) continue;

      final namaKelas = (item['nama_kelas'] ?? item['nama'] ?? 'Mata Kuliah')
          .toString();
      final jamMulai = (item['jam_mulai'] ?? '').toString();
      final ruangan = (item['ruang'] ?? item['ruangan'] ?? '').toString();
      final dosen = (item['dosen']?['name'] ?? item['nama_dosen'] ?? '')
          .toString();

      if (jamMulai.isEmpty || !jamMulai.contains(':')) continue;

      final timeParts = jamMulai.split(':');
      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (hour == null || minute == null) continue;

      final classTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Pengingat 15 menit sebelum kelas
      var reminderTime = classTime.subtract(const Duration(minutes: 15));

      // Jika waktu 15 menit sebelum sudah lewat tetapi kelas belum mulai, ingatkan segera
      if (reminderTime.isBefore(now) && classTime.isAfter(now)) {
        reminderTime = now.add(const Duration(seconds: 5));
      }

      // Jangan jadwalkan jika kelas sudah lewat hari ini
      if (reminderTime.isBefore(now)) continue;

      final notifId = classBaseId + i;
      final bodyText = StringBuffer('Dimulai pukul $jamMulai WIB');
      if (ruangan.isNotEmpty) bodyText.write(' di $ruangan');
      if (dosen.isNotEmpty) bodyText.write(' ($dosen)');
      bodyText.write('. Jangan sampai terlambat!');

      const androidDetails = AndroidNotificationDetails(
        _classChannelId,
        _classChannelName,
        channelDescription: _classChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
        color: Color(0xFF1F81FF),
      );
      const notifDetails = NotificationDetails(android: androidDetails);

      await _plugin.zonedSchedule(
        id: notifId,
        title: 'Pengingat Kelas: $namaKelas',
        body: bodyText.toString(),
        scheduledDate: reminderTime,
        notificationDetails: notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      scheduledCount++;
      debugPrint(
        '[NotificationService] Jadwal kelas "$namaKelas" diset pada $reminderTime',
      );
    }

    debugPrint(
      '[NotificationService] Berhasil menjadwalkan $scheduledCount kelas.',
    );
  }

  /// Menjadwalkan / memperbarui pengingat jam 22:00 untuk Laporan Ibadah & Poin Kebaikan
  static Future<void> syncNightlyReminder({
    required bool isIbadahDone,
    required bool isKebaikanDone,
  }) async {
    await init();

    final now = tz.TZDateTime.now(tz.local);
    final targetTonight = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      22,
      0,
    );

    // Jika kedua laporan hari ini sudah diisi
    if (isIbadahDone && isKebaikanDone) {
      if (now.isBefore(targetTonight)) {
        // Batalkan pengingat malam ini karena user sudah patuh
        await _plugin.cancel(id: nightlyReminderId);
        debugPrint(
          '[NotificationService] Kedua laporan hari ini sudah diisi. Pengingat malam dibatalkan.',
        );
      }
      return;
    }

    // Tentukan pesan berdasarkan apa yang belum diisi
    String title;
    String body;

    if (!isIbadahDone && !isKebaikanDone) {
      title = 'Pengingat Laporan Harian (22:00)';
      body =
          'Kamu belum mengisi Laporan Ibadah dan Poin Kebaikan hari ini. Yuk isi sekarang!';
    } else if (!isIbadahDone) {
      title = 'Pengingat Laporan Ibadah (22:00)';
      body =
          'Kamu belum mengisi Laporan Ibadah Harian hari ini. Jangan lupa diisi ya!';
    } else {
      title = 'Pengingat Poin Kebaikan (22:00)';
      body =
          'Kamu belum mengisi formulir Poin Kebaikan hari ini. Luangkan 1 menit untuk isi yuk!';
    }

    // Jika waktu 22:00 malam ini sudah lewat, jadwalkan untuk besok jam 22:00
    DateTime scheduledTime = targetTonight;
    if (now.isAfter(targetTonight)) {
      scheduledTime = targetTonight.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _nightlyChannelId,
      _nightlyChannelName,
      channelDescription: _nightlyChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      color: Color(0xFF1F81FF),
    );
    const notifDetails = NotificationDetails(android: androidDetails);

    final tzSchedule = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      id: nightlyReminderId,
      title: title,
      body: body,
      scheduledDate: tzSchedule,
      notificationDetails: notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint(
      '[NotificationService] Pengingat laporan malam dijadwalkan pada: $tzSchedule',
    );
  }

  /// Helper untuk memicu notifikasi uji coba secara instan
  static Future<void> showImmediateTestNotification({
    String title = 'Tes Notifikasi LMS',
    String body = 'Notifikasi lokal berjalan dengan baik!',
  }) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      _nightlyChannelId,
      _nightlyChannelName,
      channelDescription: _nightlyChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      color: Color(0xFF1F81FF),
    );
    const notifDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: testNotificationId,
      title: title,
      body: body,
      notificationDetails: notifDetails,
    );
  }
}
