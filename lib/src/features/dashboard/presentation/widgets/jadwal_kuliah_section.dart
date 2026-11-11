import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../utils/date_utils.dart';
import '../../../jadwal_absensi/presentation/absensi_providers.dart';
import '../../../materi/presentation/materi_page.dart';
import '../../../tugas/presentation/tugas_page.dart';
import '../dashboard_providers.dart';

/// Komponen Jadwal Kuliah Hari Ini & Sesi Perkuliahan Mendatang (Semester Reguler)
/// 100% Dinamis dari server LMS (No Hardcode)
class JadwalKuliahSection extends ConsumerStatefulWidget {
  final List<dynamic> listHariIni;
  final List<dynamic> listMendatang;

  const JadwalKuliahSection({
    super.key,
    required this.listHariIni,
    required this.listMendatang,
  });

  @override
  ConsumerState<JadwalKuliahSection> createState() => _JadwalKuliahSectionState();
}

class _JadwalKuliahSectionState extends ConsumerState<JadwalKuliahSection> {
  late DateTime _currentTime;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _currentTime = DateTime.now();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _formatLiveClock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatRelativeDateBadge(dynamic dateInput) {
    if (dateInput == null) return '-';
    DateTime? dt;
    if (dateInput is DateTime) {
      dt = dateInput;
    } else if (dateInput is String) {
      try {
        final parts = dateInput.split('-');
        if (parts.length == 3) {
          dt = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        } else {
          dt = DateTime.tryParse(dateInput);
        }
      } catch (_) {}
    }
    if (dt == null) return AppDateUtils.formatShortPillDate(dateInput);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diffDays = target.difference(today).inDays;
    if (diffDays == 0) return 'Hari Ini';
    if (diffDays == 1) return 'Besok';
    return AppDateUtils.formatShortPillDate(dt);
  }

  void _showPresensiDialog({
    required BuildContext context,
    required Map<String, dynamic> item,
  }) {
    final jadwalId = int.tryParse(item['id']?.toString() ?? '') ?? 0;
    final defaultKode = item['kode_presensi']?.toString() ?? '';
    final matkul =
        item['kelas']?['matkul']?['nama_matkul']?.toString() ?? 'Mata Kuliah';
    final namaKelas = item['kelas']?['nama_kelas']?.toString() ?? '-';
    final ruangan = item['ruangan']?.toString() ?? '-';

    final textController = TextEditingController(text: defaultKode);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            20.w,
            20.h,
            20.w,
            MediaQuery.of(ctx).viewInsets.bottom + 24.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: const Color(0xFF1F81FF),
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Presensi Kuliah',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          '$matkul ($namaKelas)',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF6B7280),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ruang: $ruangan',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    Text(
                      '${item['jam_mulai'] ?? '-'} - ${item['jam_selesai'] ?? '-'} WIB',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F81FF),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Kode Presensi',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              SizedBox(height: 6.h),
              TextField(
                controller: textController,
                autofocus: defaultKode.isEmpty,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Masukkan kode unik presensi',
                  hintStyle: TextStyle(
                    fontSize: 13.sp,
                    letterSpacing: 0,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF9CA3AF),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: Color(0xFF1F81FF), width: 1.5),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 44.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F81FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  onPressed: () async {
                    final kode = textController.text.trim();
                    if (kode.isEmpty) return;
                    Navigator.pop(ctx);

                    final success = await ref
                        .read(presensiSubmitControllerProvider.notifier)
                        .submit(jadwalId: jadwalId, kodeUnik: kode);

                    if (!context.mounted) return;
                    if (success) {
                      ref.invalidate(dashboardMahasiswaProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Presensi berhasil dikirim!'),
                          backgroundColor: Color(0xFF16A34A),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gagal mengirim presensi. Periksa kembali kode.'),
                          backgroundColor: Color(0xFFDC2626),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Kirim Presensi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final listHariIni = widget.listHariIni;
    final listMendatang = widget.listMendatang;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Icon(
                    Icons.school_rounded,
                    color: const Color(0xFF1F81FF),
                    size: 20.sp,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jadwal Kuliah Hari Ini',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Perkuliahan semester reguler',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppDateUtils.formatShortPillDate(_currentTime),
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Icon(
                    Icons.sync_rounded,
                    color: const Color(0xFF1D4ED8),
                    size: 11.sp,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    _formatLiveClock(_currentTime),
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Divider(color: const Color(0xFFF3F4F6), height: 1.h, thickness: 1.h),
          SizedBox(height: 14.h),

          // Daftar Kelas Hari Ini
          if (listHariIni.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    size: 32.sp,
                    color: const Color(0xFF9CA3AF),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Tidak Ada Jadwal Kuliah Matkul Hari Ini',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Semua sesi perkuliahan matkul hari ini telah selesai atau belum terjadwal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: listHariIni.length,
              separatorBuilder: (_, _) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final item = listHariIni[index];
                final itemMap = item is Map<String, dynamic>
                    ? item
                    : (item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{});

                final matkul =
                    itemMap['kelas']?['matkul']?['nama_matkul']?.toString() ??
                        'Mata Kuliah';
                final namaKelas =
                    itemMap['kelas']?['nama_kelas']?.toString() ?? '-';
                final dosenName =
                    itemMap['kelas']?['dosen']?['user']?['name']?.toString() ??
                        itemMap['kelas']?['dosen']?['name']?.toString() ??
                        '-';
                final jamMulai = itemMap['jam_mulai']?.toString() ?? '-';
                final jamSelesai = itemMap['jam_selesai']?.toString() ?? '-';
                final ruangan = itemMap['ruangan']?.toString() ?? '-';
                final sks =
                    itemMap['kelas']?['matkul']?['sks']?.toString() ?? '0';

                final absensis = itemMap['absensis'];
                final String? presensiStatus =
                    (absensis is List && absensis.isNotEmpty && absensis.first is Map)
                        ? absensis.first['status']?.toString()
                        : null;
                final bool isPresent = presensiStatus != null && presensiStatus.isNotEmpty;

                return Container(
                  padding: EdgeInsets.all(13.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul & Tag Kelas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              matkul,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF111827),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Text(
                              namaKelas,
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5.h),

                      // Dosen
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 13.sp,
                            color: const Color(0xFF9CA3AF),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              'Dosen: $dosenName',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                color: const Color(0xFF4B5563),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 7.h),

                      // Jam, Ruangan, SKS
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 4.h,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12.sp,
                                color: const Color(0xFF9CA3AF),
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                '$jamMulai - $jamSelesai WIB',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.meeting_room_outlined,
                                size: 12.sp,
                                color: const Color(0xFF9CA3AF),
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                'Ruang $ruangan',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_stories_outlined,
                                size: 12.sp,
                                color: const Color(0xFF9CA3AF),
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                '$sks SKS',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Action Buttons: Presensi, Materi, Tugas
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 8.w,
                          runSpacing: 6.h,
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (isPresent)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 5.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 12.sp,
                                      color: const Color(0xFF15803D),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      presensiStatus.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF15803D),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              InkWell(
                                onTap: () => _showPresensiDialog(
                                  context: context,
                                  item: itemMap,
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 5.5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1F81FF),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 11.sp,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'Presensi',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MateriPage(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8.r),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 9.w,
                                  vertical: 5.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: const Color(0xFFD1D5DB)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.menu_book_rounded,
                                      size: 11.sp,
                                      color: const Color(0xFF374151),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Materi',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF374151),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TugasPage(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8.r),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 9.w,
                                  vertical: 5.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: const Color(0xFFD1D5DB)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.checklist_rounded,
                                      size: 11.sp,
                                      color: const Color(0xFF374151),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Tugas',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF374151),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          // Sesi Perkuliahan Mendatang
          if (listMendatang.isNotEmpty) ...[
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3.5.w,
                      height: 14.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F81FF),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Sesi Perkuliahan Mendatang',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 7.w,
                    vertical: 2.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '${listMendatang.length} Sesi Terjadwal',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 124.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: listMendatang.length,
                separatorBuilder: (_, _) => SizedBox(width: 12.w),
                itemBuilder: (context, index) {
                  final item = listMendatang[index];
                  final itemMap = item is Map ? item : {};
                  final matkul =
                      itemMap['kelas']?['matkul']?['nama_matkul']?.toString() ??
                          'Mata Kuliah';
                  final namaKelas =
                      itemMap['kelas']?['nama_kelas']?.toString() ?? '-';
                  final jamMulai = itemMap['jam_mulai']?.toString() ?? '-';
                  final ruangan = itemMap['ruangan']?.toString() ?? '-';
                  final tanggal = itemMap['tanggal'];
                  final relativeDate = _formatRelativeDateBadge(tanggal);
                  final isToday = relativeDate == 'Hari Ini';
                  final isTomorrow = relativeDate == 'Besok';

                  return Container(
                    width: 240.w,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.025),
                          blurRadius: 8.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Baris 1: Date Pill + Big Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 2.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? const Color(0xFFEFF6FF)
                                    : (isTomorrow
                                        ? const Color(0xFFF5F3FF)
                                        : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: isToday
                                      ? const Color(0xFFBFDBFE)
                                      : (isTomorrow
                                          ? const Color(0xFFDDD6FE)
                                          : const Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 9.5.sp,
                                    color: isToday
                                        ? const Color(0xFF1D4ED8)
                                        : (isTomorrow
                                            ? const Color(0xFF6D28D9)
                                            : const Color(0xFF475569)),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    relativeDate,
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color: isToday
                                        ? const Color(0xFF1D4ED8)
                                        : (isTomorrow
                                            ? const Color(0xFF6D28D9)
                                            : const Color(0xFF334155)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  jamMulai,
                                  style: TextStyle(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  'WIB',
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Baris 2: Nama Matkul
                        Text(
                          matkul,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),

                        // Baris 3: Kelas & Ruangan Chips
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(5.r),
                              ),
                              child: Text(
                                namaKelas,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(5.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.meeting_room_outlined,
                                    size: 10.sp,
                                    color: const Color(0xFF1D4ED8),
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    'Ruang $ruangan',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
