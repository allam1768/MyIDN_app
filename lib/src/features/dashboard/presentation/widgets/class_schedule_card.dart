import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../jadwal_absensi/presentation/detail_absensi_page.dart';
import '../kelas_utils.dart';

class ClassScheduleCard extends StatelessWidget {
  final String namaKelas;
  final String jamMulai;
  final String jamSelesai;
  final String kodeKelas;
  final String dosenName;
  final int nowMinutes;

  const ClassScheduleCard({
    super.key,
    required this.namaKelas,
    required this.jamMulai,
    required this.jamSelesai,
    required this.kodeKelas,
    required this.dosenName,
    required this.nowMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final iconInfo = KelasUtils.getMapelIcon(namaKelas);
    final startMin = KelasUtils.parseMinutes(jamMulai);
    final endMin = KelasUtils.parseMinutes(jamSelesai);

    final bool isPast = endMin != null && nowMinutes > endMin;
    final bool isLive =
        startMin != null &&
        endMin != null &&
        nowMinutes >= startMin &&
        nowMinutes <= endMin;

    final String badgeText;
    final Color badgeBg;
    final Color badgeTextColor;

    if (isLive) {
      badgeText = 'Sekarang';
      badgeBg = const Color(0xFFF0F6FF);
      badgeTextColor = const Color(0xFF1F81FF);
    } else if (isPast) {
      badgeText = 'Selesai';
      badgeBg = const Color(0xFFE5E7EB);
      badgeTextColor = const Color(0xFF6B7280);
    } else {
      badgeText = 'Akan Datang';
      badgeBg = const Color(0xFFF0F6FF);
      badgeTextColor = const Color(0xFF1F81FF);
    }

    final cardBg = isPast ? const Color(0xFFF3F4F6) : Colors.white;
    final iconBg = isPast ? const Color(0xFFE5E7EB) : iconInfo.bg;
    final iconColor = isPast ? const Color(0xFF9CA3AF) : iconInfo.color;
    final titleColor = isPast
        ? const Color(0xFF6B7280)
        : const Color(0xFF111827);
    final timeColor = isPast
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF1F81FF);
    final dosenColor = isPast
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF374151);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.w),
        boxShadow: isPast
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6.r,
                  offset: Offset(0, 2.h),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: kodeKelas.isNotEmpty
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailAbsensiPage(
                        kodeKelasHarian: kodeKelas,
                        namaKelas: namaKelas,
                      ),
                    ),
                  );
                }
              : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: iconInfo.svgAsset != null
                            ? SvgPicture.asset(
                                iconInfo.svgAsset!,
                                width: 20.sp,
                                height: 20.sp,
                                colorFilter: ColorFilter.mode(
                                  iconColor,
                                  BlendMode.srcIn,
                                ),
                              )
                            : Icon(
                                iconInfo.icon,
                                color: iconColor,
                                size: 20.sp,
                              ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            namaKelas,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            '$jamMulai - $jamSelesai',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: timeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Divider(
                  height: 1.h,
                  thickness: 0.8.h,
                  color: const Color(0xFFE5E7EB),
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        dosenName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: dosenColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: badgeTextColor,
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
    );
  }
}
