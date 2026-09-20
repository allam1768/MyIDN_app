import 'package:flutter/material.dart';
import '../../ibadah/presentation/laporan_ibadah_page.dart';
import '../../jadwal_absensi/presentation/detail_absensi_page.dart';
import '../../poin_kebaikan/presentation/poin_kebaikan_page.dart';
import '../../tugas/presentation/detail_tugas_page.dart';
import '../../tugas/presentation/tugas_page.dart';
import '../../update/domain/models/app_update_info.dart';
import '../../update/presentation/update_dialog.dart';
import '../domain/models/daily_agenda_item.dart';
import '../presentation/dashboard_providers.dart';
import '../presentation/dashboard_utils.dart';
import '../presentation/kelas_utils.dart';
import 'dashboard_helpers.dart';

/// Engine cerdas pengolah agenda dan rekomendasi harian mahasiswa (SRP).
class DailyBriefingEngine {
  DailyBriefingEngine._();

  /// Menghasilkan daftar rekomendasi kartu agenda harian berdasarkan prioritas:
  /// 1. Kelas sedang berlangsung (Presensi Aktif) jika ada
  /// 2. Notifikasi Pembaruan Aplikasi dari GitHub (jika ada update)
  /// 3. Kelas berikutnya yang akan datang hari ini
  /// 4. Semua tugas pending yang belum dikerjakan
  /// 5. Pengingat Laporan Ibadah jika belum diisi
  /// 6. Pengingat Poin Kebaikan jika belum dicatat
  /// 7. Apresiasi "Semua Selesai" jika seluruh agenda telah tuntas
  static List<DailyAgendaItem> resolveItems({
    required List<dynamic> listKelas,
    required List<dynamic> listTugas,
    required int nowMinutes,
    required bool isIbadahDone,
    required bool isKebaikanDone,
    AppUpdateInfo? updateInfo,
  }) {
    Map? ongoingClass;
    Map? upcomingClass;
    int? shortestWait;

    for (final item in listKelas) {
      if (item is! Map) continue;
      final rawM = item['jam_mulai']?.toString() ?? '';
      final rawS = item['jam_selesai']?.toString() ?? '';
      final startMin = KelasUtils.parseMinutes(rawM);
      final endMin = KelasUtils.parseMinutes(rawS);

      if (startMin == null || endMin == null) continue;

      if (nowMinutes >= startMin && nowMinutes <= endMin) {
        ongoingClass = item;
      } else if (nowMinutes < startMin) {
        final wait = startMin - nowMinutes;
        if (shortestWait == null || wait < shortestWait) {
          shortestWait = wait;
          upcomingClass = item;
        }
      }
    }

    // Filter tugas pending menggunakan DashboardHelpers (DRY)
    final pendingTasks = <Map>[];
    for (final t in listTugas) {
      if (t is! Map) continue;
      if (!DashboardHelpers.isTaskCompleted(t)) {
        pendingTasks.add(t);
      }
    }

    final items = <DailyAgendaItem>[];

    // 1. Kelas sedang berlangsung saat ini (Prioritas Utama Presensi)
    if (ongoingClass != null) {
      final nama = ongoingClass['nama_kelas']?.toString() ?? 'Mata Kuliah';
      final rawS = ongoingClass['jam_selesai']?.toString() ?? '';
      final jamSelesai = rawS.length >= 5 ? rawS.substring(0, 5) : rawS;
      final kode = ongoingClass['kode_kelas_harian']?.toString() ?? '';

      items.add(
        DailyAgendaItem(
          badge: 'PRESENSI AKTIF',
          title: 'Presensi Kelas $nama',
          subtitle: 'Sedang berlangsung • Berakhir pukul $jamSelesai',
          icon: Icons.how_to_reg_outlined,
          buttonText: 'Isi Presensi Sekarang',
          secondaryNotice: 'Segera lakukan presensi kehadiran kuliah',
          gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          buttonTextColor: const Color(0xFF0F172A),
          onAction: (ctx, ref) async {
            if (kode.isNotEmpty) {
              await Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) =>
                      DetailAbsensiPage(kodeKelasHarian: kode, namaKelas: nama),
                ),
              );
              ref.invalidate(kelasHarianProvider);
            }
          },
        ),
      );
    }

    // 2. Pembaruan Aplikasi dari GitHub jika versi baru tersedia
    if (updateInfo != null && updateInfo.hasUpdate) {
      final isUrgent = updateInfo.isForceUpdate;
      items.add(
        DailyAgendaItem(
          badge: isUrgent ? 'UPDATE WAJIB' : 'UPDATE TERSEDIA',
          title: isUrgent
              ? 'Pembaruan Kritis v${updateInfo.latestVersion} Wajib Dipasang! 🚨'
              : 'Versi Baru MyIDN v${updateInfo.latestVersion} Tersedia! 🎉',
          subtitle: isUrgent
              ? 'Versi lama tidak didukung. Wajib perbarui sekarang'
              : 'Tekan untuk melihat catatan rilis & unduh versi terbaru',
          icon: isUrgent
              ? Icons.warning_amber_rounded
              : Icons.rocket_launch_rounded,
          buttonText: isUrgent ? 'Pasang Sekarang' : 'Lihat Pembaruan',
          secondaryNotice: isUrgent
              ? 'Pembaruan darurat sistem MyIDN • Tindakan wajib'
              : 'Versi terpasang: v${updateInfo.currentVersion} • Tap untuk info',
          gradientColors: isUrgent
              ? const [Color(0xFFDC2626), Color(0xFF991B1B)]
              : const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          buttonTextColor: const Color(0xFF0F172A),
          onAction: (ctx, ref) async {
            await UpdateDialog.show(ctx, updateInfo);
          },
        ),
      );
    }

    // 3. Kelas selanjutnya yang akan datang hari ini
    if (upcomingClass != null) {
      final nama = upcomingClass['nama_kelas']?.toString() ?? 'Mata Kuliah';
      final rawM = upcomingClass['jam_mulai']?.toString() ?? '';
      final jamMulai = rawM.length >= 5 ? rawM.substring(0, 5) : rawM;
      final waitStr = shortestWait != null && shortestWait > 0
          ? (shortestWait >= 60
                ? '${shortestWait ~/ 60} jam ${shortestWait % 60} menit lagi'
                : '$shortestWait menit lagi')
          : 'Segera dimulai';
      final kode = upcomingClass['kode_kelas_harian']?.toString() ?? '';

      items.add(
        DailyAgendaItem(
          badge: 'KELAS BERIKUTNYA',
          title: 'Persiapan Kelas $nama',
          subtitle: 'Mulai pukul $jamMulai • $waitStr',
          icon: Icons.school_outlined,
          buttonText: 'Lihat Jadwal Kuliah',
          secondaryNotice: ongoingClass != null
              ? 'Sesi berikutnya setelah kelas ini selesai'
              : 'Siapkan materi dan hadir tepat waktu',
          gradientColors: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          buttonTextColor: const Color(0xFF0F172A),
          onAction: (ctx, ref) async {
            if (kode.isNotEmpty) {
              await Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) =>
                      DetailAbsensiPage(kodeKelasHarian: kode, namaKelas: nama),
                ),
              );
            }
          },
        ),
      );
    }

    // 3. Semua tugas yang masih pending (belum dikerjakan)
    if (pendingTasks.isNotEmpty) {
      for (int i = 0; i < pendingTasks.length; i++) {
        final task = pendingTasks[i];
        final rawJudul =
            task['judul']?.toString() ??
            task['nama_tugas']?.toString() ??
            task['title']?.toString() ??
            task['name']?.toString() ??
            'Tugas Kuliah';
        final judul = rawJudul.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        final deadline = DashboardUtils.findDeadline(task);
        final subtitle = deadline != null && deadline.isNotEmpty
            ? 'Deadline $deadline'
            : 'Segera kumpulkan sebelum batas waktu';
        final kodeKelas = task['kode_kelas_harian']?.toString() ?? '';
        final namaKelas = task['nama_kelas']?.toString() ?? '';

        final fullSubtitle = namaKelas.isNotEmpty
            ? '$namaKelas • $subtitle'
            : subtitle;

        final remainingRatio = DashboardUtils.calculateRemainingRatio(deadline);
        final isUrgent = remainingRatio < 0.25;

        items.add(
          DailyAgendaItem(
            badge: pendingTasks.length > 1
                ? 'TUGAS PENDING (${i + 1}/${pendingTasks.length})'
                : 'TUGAS PENDING',
            title: judul.toLowerCase().startsWith('selesaikan')
                ? judul
                : 'Selesaikan $judul',
            subtitle: fullSubtitle,
            icon: Icons.assignment_outlined,
            svgAsset: 'assets/icon/tugas.svg',
            buttonText: 'Kerjakan Sekarang',
            secondaryNotice:
                'Tugas ${i + 1} dari ${pendingTasks.length} belum dikumpulkan',
            remainingRatio: remainingRatio,
            gradientColors: isUrgent
                ? const [Color(0xFFF43F5E), Color(0xFFE11D48)]
                : const [Color(0xFFF97316), Color(0xFFEA580C)],
            buttonTextColor: const Color(0xFF0F172A),
            onAction: (ctx, ref) async {
              if (kodeKelas.isNotEmpty) {
                await Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => DetailTugasPage(
                      kodeKelasHarian: kodeKelas,
                      namaKelas: namaKelas.isNotEmpty ? namaKelas : judul,
                    ),
                  ),
                );
                ref.invalidate(tugasHarianProvider);
              } else {
                await Navigator.push(
                  ctx,
                  MaterialPageRoute(builder: (_) => const TugasPage()),
                );
                ref.invalidate(tugasHarianProvider);
              }
            },
          ),
        );
      }
    }

    // 4. Laporan Ibadah Harian belum diisi
    if (!isIbadahDone) {
      items.add(
        DailyAgendaItem(
          badge: "MUTABA'AH IBADAH",
          title: 'Laporan Ibadah Belum Diisi',
          subtitle: 'Catat evaluasi sholat & ibadah harianmu hari ini',
          icon: Icons.mosque_outlined,
          svgAsset: 'assets/icon/ibadah.svg',
          buttonText: 'Isi Laporan Ibadah',
          secondaryNotice: 'Pengingat malam otomatis aktif pukul 22:00',
          gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
          buttonTextColor: const Color(0xFF0F172A),
          onAction: (ctx, ref) async {
            await Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const LaporanIbadahPage()),
            );
            ref.invalidate(ibadahHarianProvider);
          },
        ),
      );
    }

    // 5. Laporan Poin Kebaikan belum dicatat
    if (!isKebaikanDone) {
      items.add(
        DailyAgendaItem(
          badge: 'POIN KEBAIKAN',
          title: 'Poin Kebaikan Belum Dicatat',
          subtitle: 'Laporkan amalan positif & aksi kebaikanmu hari ini',
          icon: Icons.volunteer_activism_outlined,
          svgAsset: 'assets/icon/kebaikan.svg',
          buttonText: 'Catat Poin Kebaikan',
          secondaryNotice: 'Tingkatkan poin kebaikan santri setiap hari',
          gradientColors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          buttonTextColor: const Color(0xFF0F172A),
          onAction: (ctx, ref) async {
            await Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const PoinKebaikanPage()),
            );
            ref.invalidate(poinKebaikanStatusProvider);
          },
        ),
      );
    }

    // 6. Jika semua agenda telah selesai
    if (items.isEmpty) {
      items.add(
        DailyAgendaItem(
          badge: 'SEMUA TUNTAS',
          title: 'Semua Agenda Hari Ini Selesai!',
          subtitle: 'Kerja bagus! Kelas, tugas, ibadah & kebaikan telah tuntas',
          icon: Icons.check_circle_outline_rounded,
          buttonText: 'Lihat Mutaba\'ah Ibadah',
          secondaryNotice: 'Pertahankan kedisiplinan dan istirahat yang cukup',
          gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
          buttonTextColor: const Color(0xFF0F172A),
          onAction: (ctx, ref) async {
            await Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const LaporanIbadahPage()),
            );
          },
        ),
      );
    }

    return items;
  }
}
