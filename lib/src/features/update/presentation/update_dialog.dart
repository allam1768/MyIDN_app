import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/models/app_update_info.dart';

/// Modal dialog modern untuk notifikasi pembaruan aplikasi MyIDN
class UpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  static bool _isShowing = false;

  /// Menampilkan dialog pembaruan.
  /// Jika [info.isForceUpdate] bernilai true, dialog tidak dapat ditutup (un-dismissable).
  static Future<void> show(BuildContext context, AppUpdateInfo info) async {
    if (_isShowing) return;
    _isShowing = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: !info.isForceUpdate,
        builder: (ctx) => UpdateDialog(updateInfo: info),
      );
    } finally {
      _isShowing = false;
    }
  }

  Future<void> _launchDownload(BuildContext context) async {
    final uri = Uri.parse(updateInfo.downloadUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Fallback jika direct download gagal, buka halaman releases
      final fallbackUri = Uri.parse(updateInfo.htmlUrl);
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUrgent = updateInfo.isForceUpdate;

    final Color primaryColor = isUrgent
        ? const Color(0xFFDC2626)
        : const Color(0xFF1F81FF);
    final List<Color> iconGradient = isUrgent
        ? const [Color(0xFFEF4444), Color(0xFFB91C1C)]
        : const [Color(0xFF8B5CF6), Color(0xFF6D28D9)];
    final Color iconShadowColor = isUrgent
        ? const Color(0xFFEF4444).withValues(alpha: 0.4)
        : const Color(0xFF8B5CF6).withValues(alpha: 0.35);

    return PopScope(
      canPop: !isUrgent,
      child: Dialog(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Badge Berpendar
              Container(
                width: 56.r,
                height: 56.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: iconGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconShadowColor,
                      blurRadius: 14.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Icon(
                  isUrgent
                      ? Icons.warning_amber_rounded
                      : Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 28.sp,
                ),
              ),
              SizedBox(height: 16.h),

              // Judul Modal
              Text(
                isUrgent
                    ? 'Pembaruan Wajib Tersedia! 🚨'
                    : 'Versi Baru Tersedia! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 6.h),

              // Version Comparison Pill (v1.0.0 -> v1.0.1)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'v${updateInfo.currentVersion}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14.sp,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    Text(
                      'v${updateInfo.latestVersion}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: isUrgent
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF6D28D9),
                      ),
                    ),
                  ],
                ),
              ),

              // Peringatan Khusus Jika Update Wajib
              if (isUrgent) ...[
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_clock_rounded,
                        size: 14.sp,
                        color: const Color(0xFFDC2626),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'Pembaruan ini bersifat wajib untuk melanjutkan akses.',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 14.h),

              // Box Changelog / Catatan Rilis
              Container(
                width: double.infinity,
                constraints: BoxConstraints(maxHeight: 140.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apa yang baru:',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        updateInfo.releaseNotes.trim(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Tombol Aksi: Jika Wajib -> Single Button Full Width. Jika Biasa -> Ada Nanti Saja
              if (!isUrgent)
                Row(
                  children: [
                    // Batal / Nanti Saja
                    Expanded(
                      flex: 1,
                      child: Material(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12.r),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 44.h,
                            alignment: Alignment.center,
                            child: Text(
                              'Nanti Saja',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),

                    // Unduh & Pasang APK
                    Expanded(
                      flex: 2,
                      child: Material(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12.r),
                        elevation: 2,
                        shadowColor: primaryColor.withValues(alpha: 0.35),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12.r),
                          onTap: () {
                            Navigator.pop(context);
                            _launchDownload(context);
                          },
                          child: Container(
                            height: 44.h,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.download_rounded,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'Update Sekarang',
                                  style: TextStyle(
                                    fontSize: 13.sp,
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
                )
              else
                // Tombol Penuh Update Wajib (Un-dismissable)
                Material(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12.r),
                  elevation: 2,
                  shadowColor: primaryColor.withValues(alpha: 0.35),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: () {
                      // Tidak menutup dialog agar pengguna tidak bisa mengakses aplikasi lama
                      _launchDownload(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Mengunduh rilis terbaru... Pasang berkas APK untuk melanjutkan.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 46.h,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.download_rounded,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Unduh & Pasang Pembaruan Sekarang',
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
