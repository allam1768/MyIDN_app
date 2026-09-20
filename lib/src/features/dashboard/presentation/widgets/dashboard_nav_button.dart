import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DashboardNavButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? svgAsset;
  final Color bgColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const DashboardNavButton({
    super.key,
    required this.label,
    this.icon,
    this.svgAsset,
    required this.bgColor,
    this.iconColor,
    required this.onTap,
  }) : assert(
         icon != null || svgAsset != null,
         'Either icon or svgAsset must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50.r,
            height: 50.r,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Center(
              child: svgAsset != null
                  ? SvgPicture.asset(
                      svgAsset!,
                      width: 24.sp,
                      height: 24.sp,
                      colorFilter: iconColor != null
                          ? ColorFilter.mode(iconColor!, BlendMode.srcIn)
                          : null,
                    )
                  : Icon(icon, color: iconColor ?? Colors.black, size: 24.sp),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}
