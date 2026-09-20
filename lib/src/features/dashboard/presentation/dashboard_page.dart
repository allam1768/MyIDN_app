import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../services/notification_service.dart';
import '../../ibadah/presentation/laporan_ibadah_page.dart';
import '../../license/presentation/admin_keygen_page.dart';
import '../../materi/presentation/materi_page.dart';
import '../../poin_kebaikan/data/poin_kebaikan_data.dart';
import '../../poin_kebaikan/presentation/poin_kebaikan_page.dart';
import '../../tugas/presentation/tugas_page.dart';
import '../../surat_izin/presentation/surat_izin_form_page.dart';
import '../../update/presentation/update_dialog.dart';
import '../../update/presentation/update_providers.dart';
import '../application/dashboard_helpers.dart';
import 'dashboard_providers.dart';
import 'dashboard_utils.dart';
import 'kelas_utils.dart';
import 'pengguna_aktif_page.dart';
import 'profile_page.dart';
import 'widgets/class_schedule_card.dart';
import 'widgets/daily_briefing_card.dart';
import 'widgets/dashboard_nav_button.dart';
import 'widgets/task_item_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  void _refreshAll(WidgetRef ref) {
    ref.invalidate(kelasHarianProvider);
    ref.invalidate(tugasHarianProvider);
    ref.invalidate(materiHarianProvider);
    ref.invalidate(dashboardMahasiswaProvider);
    ref.invalidate(ibadahHarianProvider);
    ref.invalidate(poinKebaikanStatusProvider);
    ref.invalidate(appUpdateInfoProvider);
  }

  static Future<void> _syncNightlyReminder(WidgetRef ref) async {
    final ibadahData = ref.read(ibadahHarianProvider).valueOrNull;
    final isIbadahDone = DashboardHelpers.isIbadahDone(ibadahData);
    final isKebaikanDone = await PoinKebaikanConfig.isDoneToday();

    await NotificationService.syncNightlyReminder(
      isIbadahDone: isIbadahDone,
      isKebaikanDone: isKebaikanDone,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sinkronkan notifikasi jadwal kelas hari ini secara otomatis
    ref.listen(kelasHarianProvider, (prev, next) {
      next.whenData((data) {
        final classes = KelasUtils.extractClassesList(data);
        NotificationService.scheduleClassesForToday(classes);
      });
    });

    // Sinkronkan pengingat malam 22:00 untuk laporan ibadah & kebaikan
    ref.listen(ibadahHarianProvider, (prev, next) {
      next.whenData((_) {
        _syncNightlyReminder(ref);
      });
    });

    // Pantau pembaruan darurat/wajib (Force Update) dari GitHub
    ref.listen(appUpdateInfoProvider, (prev, next) {
      next.whenData((info) {
        if (info != null && info.hasUpdate && info.isForceUpdate) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              UpdateDialog.show(context, info);
            }
          });
        }
      });
    });

    final updateInfo = ref.watch(appUpdateInfoProvider).valueOrNull;
    if (updateInfo != null && updateInfo.hasUpdate && updateInfo.isForceUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          UpdateDialog.show(context, updateInfo);
        }
      });
    }

    final dashboardAsync = ref.watch(dashboardMahasiswaProvider);
    final kelasAsync = ref.watch(kelasHarianProvider);
    final tugasAsync = ref.watch(tugasHarianProvider);
    final ibadahAsync = ref.watch(ibadahHarianProvider);
    final poinKebaikanAsync = ref.watch(poinKebaikanStatusProvider);

    final dashboardData = dashboardAsync.valueOrNull;
    final kelasData = kelasAsync.valueOrNull;
    final tugasData = tugasAsync.valueOrNull;
    final ibadahData = ibadahAsync.valueOrNull;

    // Status penyelesaian ibadah & poin kebaikan hari ini (DRY via DashboardHelpers)
    final bool isIbadahDone = DashboardHelpers.isIbadahDone(ibadahData);
    final bool isKebaikanDone = poinKebaikanAsync.valueOrNull ?? false;

    // Ekstraksi data
    final userName = DashboardUtils.extractUserName(dashboardData, kelasData);
    final userProfile = DashboardUtils.extractUserProfile(
      dashboardData,
      kelasData,
    );
    final listKelas = KelasUtils.extractClassesList(kelasData);
    final listTugas = DashboardUtils.extractAllTasks(
      tugasData,
      dashboardData: dashboardData,
      kelasData: kelasData,
    );
    final pendingTugas = DashboardUtils.filterPendingTasks(listTugas);

    // Cek otorisasi khusus Creator (Hanya Allam Permata Putra yang bisa melihat menu Key Studio)
    final isCreator = DashboardUtils.isAllamPermataPutra(
      name: userProfile.name,
      dashboardData: dashboardData,
      kelasData: kelasData,
    );

    // Waktu saat ini untuk status jadwal
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56.h),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Brand LMS
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32.r,
                        height: 32.r,
                        padding: EdgeInsets.all(5.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F81FF),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icon/idn_ic.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          'LMS Digital Learning',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Menu Khusus Creator: Hanya Allam Permata Putra yang dapat melihat dan membuka menu ini
                    if (isCreator) ...[
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10.r),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminKeygenPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 9.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.4),
                                width: 1.w,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4338CA,
                                  ).withValues(alpha: 0.22),
                                  blurRadius: 6.r,
                                  offset: Offset(0, 2.h),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.vpn_key_rounded,
                                  color: const Color(0xFFFBBF24),
                                  size: 13.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'Key Studio',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],

                    // Avatar User Profil Real
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfilePage(),
                          ),
                        );
                      },
                      child: Container(
                        width: 36.r,
                        height: 36.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1F81FF), Color(0xFF0057BF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.white, width: 2.w),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'M',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshAll(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Daily Briefing Focus Card (Status Terkini & Alert Tugas)

              // Greeting Mahasiswa
              Text(
                'Halo, $userName!',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Siap untuk belajar hari ini?',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 14.h),

              DailyBriefingCard(
                key: const ValueKey('daily_briefing_card'),
                listKelas: listKelas,
                listTugas: listTugas,
                nowMinutes: nowMinutes,
                isIbadahDone: isIbadahDone,
                isKebaikanDone: isKebaikanDone,
              ),
              SizedBox(height: 16.h),

              // 5 Tombol Navigasi Utama
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DashboardNavButton(
                    label: 'Pengguna',
                    svgAsset: 'assets/icon/pengguna.svg',
                    bgColor: const Color(0xFFF0FDF4),
                    iconColor: const Color(0xFF16A34A),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PenggunaAktifPage(),
                        ),
                      );
                    },
                  ),
                  DashboardNavButton(
                    label: 'Materi',
                    svgAsset: 'assets/icon/materi.svg',
                    bgColor: const Color(0xFFEEF2FF),
                    iconColor: const Color(0xFF4F46E5),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MateriPage()),
                      );
                    },
                  ),
                  DashboardNavButton(
                    label: 'Tugas',
                    svgAsset: 'assets/icon/tugas.svg',
                    bgColor: const Color(0xFFFFECE5),
                    iconColor: const Color(0xFFC2410C),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TugasPage()),
                      );
                    },
                  ),
                  DashboardNavButton(
                    label: 'Kebaikan',
                    svgAsset: 'assets/icon/kebaikan.svg',
                    bgColor: const Color(0xFFFFF1F2),
                    iconColor: const Color(0xFFE11D48),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PoinKebaikanPage(initialUserName: userName),
                        ),
                      );
                      _syncNightlyReminder(ref);
                    },
                  ),
                  DashboardNavButton(
                    label: 'Ibadah',
                    svgAsset: 'assets/icon/ibadah.svg',
                    bgColor: const Color(0xFFF0FDFA),
                    iconColor: const Color(0xFF0D9488),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LaporanIbadahPage(),
                        ),
                      );
                      _syncNightlyReminder(ref);
                    },
                  ),
                  DashboardNavButton(
                    label: 'Izin',
                    svgAsset: 'assets/icon/izin.svg',
                    bgColor: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SuratIzinFormPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 22.h),

              // Jadwal Hari Ini
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Jadwal Hari Ini',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F1FF),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '${listKelas.length} Kelas',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F81FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              if (kelasAsync.isLoading && listKelas.isEmpty)
                Padding(
                  padding: EdgeInsets.all(20.r),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (listKelas.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 20.h,
                    horizontal: 16.w,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        size: 32.sp,
                        color: const Color(0xFF9CA3AF),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Tidak ada jadwal kelas hari ini',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: listKelas.length,
                  separatorBuilder: (_, _) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final item = listKelas[index];
                    final itemMap = item is Map ? item : {};
                    final namaKelas =
                        itemMap['nama_kelas']?.toString() ?? 'Mata Kuliah';
                    final rawM = itemMap['jam_mulai']?.toString() ?? '08:00';
                    final jamMulai = rawM.length >= 5
                        ? rawM.substring(0, 5)
                        : rawM;
                    final rawS = itemMap['jam_selesai']?.toString() ?? '10:00';
                    final jamSelesai = rawS.length >= 5
                        ? rawS.substring(0, 5)
                        : rawS;
                    final kodeKelas =
                        itemMap['kode_kelas_harian']?.toString() ?? '';
                    final dosenName = KelasUtils.extractDosenName(
                      itemMap['dosen'],
                      itemMap['nama_dosen'],
                    );

                    return ClassScheduleCard(
                      namaKelas: namaKelas,
                      jamMulai: jamMulai,
                      jamSelesai: jamSelesai,
                      kodeKelas: kodeKelas,
                      dosenName: dosenName,
                      nowMinutes: nowMinutes,
                    );
                  },
                ),
              SizedBox(height: 22.h),

              // Daftar Tugas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Daftar Tugas',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      if (pendingTugas.isNotEmpty) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            '${pendingTugas.length} Pending',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F81FF),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TugasPage()),
                      );
                    },
                    child: Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F81FF),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              if (tugasAsync.isLoading && listTugas.isEmpty)
                Padding(
                  padding: EdgeInsets.all(20.r),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (tugasAsync.hasError && listTugas.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 16.h,
                    horizontal: 16.w,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: const Color(0xFFDC2626),
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Gagal memuat tugas harian.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF991B1B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(tugasHarianProvider),
                        child: Text(
                          'Coba Lagi',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (pendingTugas.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 28.h,
                    horizontal: 16.w,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Squircle Ikon Hijau Emerald dengan Checkmark Melingkar
                      Text(
                        'Kerja Hebat! Semua Tugas Selesai',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingTugas.length,
                  separatorBuilder: (_, _) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final item = pendingTugas[index];
                    final Map itemMap = (item is Map) ? item : {};
                    return TaskItemCard(taskMap: itemMap, index: index);
                  },
                ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
