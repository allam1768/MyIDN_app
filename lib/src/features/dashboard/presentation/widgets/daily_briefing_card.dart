import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../update/presentation/update_providers.dart';
import '../../application/daily_briefing_engine.dart';
import '../../application/dashboard_helpers.dart';
import '../../domain/models/daily_agenda_item.dart';
import '../dashboard_providers.dart';

/// Widget Carousel Kartu Fokus Harian (Daily Briefing)
/// Berperan murni sebagai Presentation Layer (SRP). Logika kalkulasi agenda berada di DailyBriefingEngine.
class DailyBriefingCard extends ConsumerStatefulWidget {
  final List<dynamic> listKelas;
  final List<dynamic> listTugas;
  final int nowMinutes;
  final bool? isIbadahDone;
  final bool? isKebaikanDone;

  const DailyBriefingCard({
    super.key,
    required this.listKelas,
    required this.listTugas,
    required this.nowMinutes,
    this.isIbadahDone,
    this.isKebaikanDone,
  });

  @override
  ConsumerState<DailyBriefingCard> createState() => _DailyBriefingCardState();
}

class _DailyBriefingCardState extends ConsumerState<DailyBriefingCard> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Viewport fraction 1.0 agar lebar kartu sejajar sempurna dengan grid dashboard
    _pageController = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Evaluasi status ibadah terpusat via DashboardHelpers (DRY)
    bool isIbadahDone = widget.isIbadahDone ?? false;
    if (widget.isIbadahDone == null) {
      final ibadahData = ref.watch(ibadahHarianProvider).valueOrNull;
      isIbadahDone = DashboardHelpers.isIbadahDone(ibadahData);
    }

    // Evaluasi status poin kebaikan
    final bool isKebaikanDone =
        widget.isKebaikanDone ??
        (ref.watch(poinKebaikanStatusProvider).valueOrNull ?? false);

    // Cek ketersediaan info pembaruan aplikasi dari GitHub
    final updateInfo = ref.watch(appUpdateInfoProvider).valueOrNull;

    // Delegasi perhitungan agenda ke DailyBriefingEngine (SoC)
    final items = DailyBriefingEngine.resolveItems(
      listKelas: widget.listKelas,
      listTugas: widget.listTugas,
      nowMinutes: widget.nowMinutes,
      isIbadahDone: isIbadahDone,
      isKebaikanDone: isKebaikanDone,
      updateInfo: updateInfo,
    );

    if (_currentIndex >= items.length) {
      _currentIndex = items.isEmpty ? 0 : items.length - 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carousel Slider Card dengan Animasi Halus
        SizedBox(
          height: 172.h,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: items.length,
            onPageChanged: (idx) {
              setState(() {
                _currentIndex = idx;
              });
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double diff = 0.0;
                  try {
                    if (_pageController.hasClients &&
                        _pageController.positions.length == 1 &&
                        _pageController.position.haveDimensions &&
                        _pageController.page != null) {
                      diff = (_pageController.page! - index).abs();
                    } else {
                      diff = (_currentIndex - index).abs().toDouble();
                    }
                  } catch (_) {
                    diff = (_currentIndex - index).abs().toDouble();
                  }

                  // Interpolasi scale & opacity saat digeser
                  final double scale = (1.0 - (diff * 0.05)).clamp(0.94, 1.0);
                  final double opacity = (1.0 - (diff * 0.18)).clamp(0.82, 1.0);

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(opacity: opacity, child: child),
                  );
                },
                child: _buildCardItem(context, items[index]),
              );
            },
          ),
        ),

        // Indikator Titik Geser Dinamis di Bawah
        if (items.length > 1) ...[
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(items.length, (idx) {
              final isActive = idx == _currentIndex;
              return GestureDetector(
                onTap: () {
                  if (_pageController.hasClients &&
                      _pageController.positions.length == 1) {
                    _pageController.animateToPage(
                      idx,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  width: isActive ? 8.w : 5.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildCardItem(BuildContext context, DailyAgendaItem item) {
    final bool isUpdate = item.badge == 'UPDATE TERSEDIA';
    final Color cardColor = isUpdate
        ? const Color(0xFF7C3AED)
        : const Color(0xFF1D4ED8);
    final Color shadowColor = isUpdate
        ? const Color(0xFF7C3AED).withValues(alpha: 0.35)
        : const Color(0xFF1D4ED8).withValues(alpha: 0.25);
    final Color actionTextColor = isUpdate
        ? const Color(0xFF6D28D9)
        : const Color(0xFF1D4ED8);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 16.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Header: Frosted Pill Badge & Glass Icon / Progress
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.badge != null && item.badge!.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 1.w,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.badge!,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Wadah Ikon Kaca & Cincin Progres
                  SizedBox(
                    width: 34.r,
                    height: 34.r,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (item.remainingRatio != null)
                          CircularProgressIndicator(
                            value: item.remainingRatio!,
                            strokeWidth: 2.w,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        Container(
                          width: 28.r,
                          height: 28.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1.w,
                            ),
                          ),
                          child: Center(
                            child: item.svgAsset != null
                                ? SvgPicture.asset(
                                    item.svgAsset!,
                                    width: 15.sp,
                                    height: 15.sp,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  )
                                : Icon(
                                    item.icon,
                                    color: Colors.white,
                                    size: 15.sp,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 2. Konten Utama: Judul, Subtitle & Notice
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.25,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  if (item.secondaryNotice != null) ...[
                    SizedBox(height: 5.h),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 12.sp,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        SizedBox(width: 5.w),
                        Expanded(
                          child: Text(
                            item.secondaryNotice!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              // 3. Tombol Aksi Terapung Putih Bersih (Tactile Floating Pill)
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: () => item.onAction(context, ref),
                  child: Container(
                    width: double.infinity,
                    height: 38.h,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.buttonText,
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w700,
                            color: actionTextColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14.sp,
                          color: actionTextColor,
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
