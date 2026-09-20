import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../tugas/presentation/detail_tugas_page.dart';
import '../../../tugas/presentation/tugas_page.dart';
import '../../application/dashboard_helpers.dart';
import '../dashboard_utils.dart';

class TaskItemCard extends StatelessWidget {
  final Map taskMap;
  final int index;

  const TaskItemCard({super.key, required this.taskMap, required this.index});

  @override
  Widget build(BuildContext context) {
    final judul =
        taskMap['judul']?.toString() ??
        taskMap['nama_tugas']?.toString() ??
        taskMap['title']?.toString() ??
        taskMap['name']?.toString() ??
        'Tugas ${index + 1}';
    final matkul =
        taskMap['nama_kelas']?.toString() ??
        (taskMap['kelas'] is Map
            ? taskMap['kelas']['nama_kelas']?.toString() ??
                  taskMap['kelas']['nama']?.toString()
            : taskMap['kelas']?.toString()) ??
        taskMap['mata_kuliah']?.toString() ??
        taskMap['matkul']?.toString() ??
        '';
    final deadline = DashboardUtils.findDeadline(taskMap) ?? 'Segera';
    final status = taskMap['status']?.toString() ?? 'Pending';
    final kodeKelas =
        taskMap['kode_kelas_harian']?.toString() ??
        taskMap['kode_kelas']?.toString() ??
        (taskMap['kelas'] is Map
            ? taskMap['kelas']['kode_kelas_harian']?.toString()
            : null) ??
        '';

    // Evaluasi status selesai terpusat via DashboardHelpers (DRY)
    final isSelesai = DashboardHelpers.isTaskCompleted(taskMap);

    // Semakin dekat deadline -> rasio semakin sedikit. Semakin jauh -> semakin penuh (1.0).
    final double progress = isSelesai
        ? 1.0
        : DashboardUtils.calculateRemainingRatio(deadline);

    final Color progressColor = isSelesai
        ? Colors.green.shade600
        : (progress <= 0.25
              ? Colors.red.shade600
              : (progress <= 0.55
                    ? Colors.orange.shade600
                    : const Color(0xFF1F81FF)));

    return GestureDetector(
      onTap: () {
        if (kodeKelas.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailTugasPage(
                kodeKelasHarian: kodeKelas,
                namaKelas: matkul.isNotEmpty ? matkul : judul,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TugasPage()),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: isSelesai
                    ? Colors.green.shade50
                    : const Color(0xFFE8F1FF),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: Icon(
                  isSelesai
                      ? Icons.check_circle_outline_rounded
                      : Icons.assignment_outlined,
                  color: isSelesai
                      ? Colors.green.shade700
                      : const Color(0xFF1F81FF),
                  size: 20.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          judul,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        deadline,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: isSelesai
                              ? Colors.green.shade700
                              : Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                  if (matkul.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      matkul,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  SizedBox(height: 6.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5.h,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    isSelesai ? 'Selesai' : status,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelesai
                          ? Colors.green.shade700
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
