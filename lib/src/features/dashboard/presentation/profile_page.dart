import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_page.dart';
import 'dashboard_providers.dart';
import 'dashboard_utils.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  void _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dCtx) => Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Badge Berpendar Halus
              SizedBox(height: 18.h),

              // Judul Dialog
              Text(
                'Konfirmasi Keluar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 8.h),

              // Pesan Konfirmasi
              Text(
                'Apakah kamu yakin ingin keluar dari akun LMS ini? Sesi login kamu akan diakhiri dan kamu perlu masuk kembali.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
              SizedBox(height: 24.h),

              // Tombol Aksi
              Row(
                children: 
                  // Tombol Batal
                  Expanded(
                    child: Material(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () => Navigator.pop(dCtx, false),
                        child: Container(
                          height: 44.h,
                          alignment: Alignment.center,
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),

                  // Tombol Keluar
                  Expanded(
                    child: Material(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(12.r),
                      elevation: 2,
                      shadowColor: const Color(
                        0xFFEF4444,
                      ).withValues(alpha: 0.35),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(dCtx, true);
                        },
                        child: Container(
                          height: 44.h,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: 15.sp,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Keluar',
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
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
    );

    if (confirm == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardMahasiswaProvider);
    final kelasAsync = ref.watch(kelasHarianProvider);

    final dashboardData = dashboardAsync.valueOrNull;
    final kelasData = kelasAsync.valueOrNull;

    // Ekstraksi profil terstruktur ke dalam UserProfileModel (SoC & Type Safety)
    final profile = DashboardUtils.extractUserProfile(dashboardData, kelasData);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        title: Text(
          'Profil Saya',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111827),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18.sp),
          color: const Color(0xFF111827),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardMahasiswaProvider);
          ref.invalidate(kelasHarianProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 1. HERO PROFILE CARD
              // ==========================================
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8.r,
                      offset: Offset(0, 3.h),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar dengan gradient ring
                    Container(
                      width: 70.r,
                      height: 70.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1F81FF), Color(0xFF0057BF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.white, width: 2.5.w),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1F81FF,
                            ).withValues(alpha: 0.25),
                            blurRadius: 10.r,
                            offset: Offset(0, 3.h),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          profile.name.isNotEmpty
                              ? profile.name[0].toUpperCase()
                              : 'M',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 26.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // Nama Lengkap
                    Text(
                      profile.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 6.h),

                    // NIM Badge dengan tombol copy
                    if (profile.nim.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: profile.nim));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'NIM ${profile.nim} berhasil disalin',
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F6FF),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'NIM: ${profile.nim}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F81FF),
                                ),
                              ),
                              SizedBox(width: 5.w),
                              Icon(
                                Icons.copy_rounded,
                                size: 12.sp,
                                color: const Color(0xFF1F81FF),
                              ),
                            ],
                          ),
                        ),
                      ),

                    SizedBox(height: 8.h),

                    // Status Chip
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5.r,
                            height: 5.r,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            profile.status,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // ==========================================
              // 2. DATA AKADEMIK
              // ==========================================
              Padding(
                padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
                child: Text(
                  'Data Akademik',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              _buildSectionCard([
                _buildInfoTile(
                  icon: Icons.badge_outlined,
                  label: 'Nomor Induk Mahasiswa (NIM)',
                  value: profile.nim.isNotEmpty ? profile.nim : '-',
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.school_outlined,
                  label: 'Program Studi',
                  value: profile.prodi,
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Semester / Kelas',
                  value: profile.semesterKelasDisplay,
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.history_edu_rounded,
                  label: 'Tahun Angkatan',
                  value: profile.angkatan,
                ),
              ]),

              SizedBox(height: 16.h),

              // ==========================================
              // 3. DATA AKUN & KONTAK
              // ==========================================
              Padding(
                padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
                child: Text(
                  'Data Akun & Kontak',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              _buildSectionCard([
                _buildInfoTile(
                  icon: Icons.alternate_email_rounded,
                  label: 'Username',
                  value: profile.username,
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  value: profile.email,
                ),
              ]),
              SizedBox(height: 20.h),
              // ==========================================
              // 5. TOMBOL LOGOUT
              // ==========================================
              Material(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14.r),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showLogoutDialog(context, ref);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 48.h,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: const Color(0xFFFECACA),
                        width: 1.w,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: const Color(0xFFDC2626),
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Keluar dari Akun',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFDC2626),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1.h,
      thickness: 0.8.h,
      color: const Color(0xFFF3F4F6),
      indent: 48.w,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final bool isUnset = value.trim().isEmpty || value == '-';
    final String displayValue = isUnset ? 'Belum diatur di LMS' : value;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 16.sp, color: const Color(0xFF6B7280)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isUnset
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF1F2937),
                    fontWeight: isUnset ? FontWeight.w400 : FontWeight.w600,
                    fontStyle: isUnset ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
