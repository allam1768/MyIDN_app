import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common_widgets/async_value_widget.dart';
import '../../../common_widgets/kelas_header_card.dart';
import '../../../common_widgets/raw_json_card.dart';
import '../../dashboard/presentation/dashboard_providers.dart';
import '../../dashboard/presentation/dashboard_utils.dart';
import '../../surat_izin/presentation/surat_izin_form_page.dart';
import 'absensi_providers.dart';

class DetailAbsensiPage extends ConsumerStatefulWidget {
  final String kodeKelasHarian;
  final String namaKelas;
  final String? monthParam;

  const DetailAbsensiPage({
    super.key,
    required this.kodeKelasHarian,
    required this.namaKelas,
    this.monthParam,
  });

  @override
  ConsumerState<DetailAbsensiPage> createState() => _DetailAbsensiPageState();
}

class _DetailAbsensiPageState extends ConsumerState<DetailAbsensiPage> {
  final TextEditingController _todayKodeController = TextEditingController();

  ({String kodeKelas, String? monthParam}) get _providerParam =>
      (kodeKelas: widget.kodeKelasHarian, monthParam: widget.monthParam);

  @override
  void dispose() {
    _todayKodeController.dispose();
    super.dispose();
  }

  Future<void> _doPresensi({
    required int jadwalId,
    required String kodeUnik,
  }) async {
    if (kodeUnik.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap masukkan kode presensi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await ref
        .read(presensiSubmitControllerProvider.notifier)
        .submit(jadwalId: jadwalId, kodeUnik: kodeUnik.trim());

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presensi berhasil dikirim! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      _todayKodeController.clear();
      // Auto-refresh jadwal via Riverpod invalidation!
      ref.invalidate(listJadwalAbsensiProvider(_providerParam));
    } else {
      final errorMsg =
          ref.read(presensiSubmitControllerProvider).errorMessage ??
          'Gagal presensi';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  void _showPresensiDialog({
    required BuildContext context,
    required int jadwalId,
    required String tanggal,
    String? autoKode,
  }) {
    final bool hasAutoKode = autoKode != null && autoKode.trim().isNotEmpty;
    final controller = TextEditingController(
      text: hasAutoKode ? autoKode.trim() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Presensi Tanggal $tanggal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan kode presensi dari dosen:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hasAutoKode
                    ? 'Kode Presensi (misal: $autoKode)'
                    : 'Masukkan Kode Presensi',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.key),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _doPresensi(jadwalId: jadwalId, kodeUnik: controller.text);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jadwalAsync = ref.watch(listJadwalAbsensiProvider(_providerParam));
    final submitState = ref.watch(presensiSubmitControllerProvider);
    final dashboardData = ref.watch(dashboardMahasiswaProvider).valueOrNull;
    final kelasData = ref.watch(kelasHarianProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.namaKelas),
        actions: [
          IconButton(
            tooltip: 'Ajukan Surat Izin',
            icon: const Icon(Icons.note_alt_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SuratIzinFormPage(initialMatkul: widget.namaKelas),
                ),
              );
            },
          ),
        ],
      ),
      body: AsyncValueWidget<dynamic>(
        value: jadwalAsync,
        onRetry: () =>
            ref.invalidate(listJadwalAbsensiProvider(_providerParam)),
        data: (jadwalData) {
          List<dynamic> listJadwal = [];
          String monthLabel = '-';
          Map kelasInfo = {};

          if (jadwalData is Map && jadwalData['props'] is Map) {
            final props = jadwalData['props'];
            if (props['jadwal'] is List) {
              listJadwal = props['jadwal'];
            }
            monthLabel = props['month']?.toString() ?? '-';
            if (props['kelasHarian'] is Map) {
              kelasInfo = props['kelasHarian'];
            }
          }

          // Cek otorisasi khusus: Kode presensi hanya ditampilkan jika akun adalah Allam Permata Putra
          final bool isAllam = DashboardUtils.isAllamPermataPutra(
            dashboardData: dashboardData,
            kelasData: kelasData,
            extraData: jadwalData,
          );

          final now = DateTime.now();
          final todayStr =
              "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

          Map? todayJadwal;
          for (final j in listJadwal) {
            if (j is Map && j['tanggal'] == todayStr) {
              todayJadwal = j;
              break;
            }
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(listJadwalAbsensiProvider(_providerParam)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card Info Kelas & Bulan
                  KelasHeaderCard(
                    namaKelas: widget.namaKelas,
                    kodeKelasHarian: widget.kodeKelasHarian,
                    subtitle: 'Jadwal Bulan $monthLabel',
                    primaryColor: Colors.blue,
                    icon: Icons.calendar_month_rounded,
                  ),
                  if (kelasInfo['jam_mulai'] != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.access_time, size: 16),
                          label: Text(
                            '${kelasInfo['jam_mulai']} - ${kelasInfo['jam_selesai'] ?? ''}',
                          ),
                          backgroundColor: Colors.blue.shade50,
                        ),
                        if (kelasInfo['kode_enroll'] != null)
                          Chip(
                            avatar: const Icon(Icons.key, size: 16),
                            label: Text('Enroll: ${kelasInfo['kode_enroll']}'),
                            backgroundColor: Colors.grey.shade100,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Featured Card: Presensi Hari Ini
                  if (todayJadwal != null)
                    _buildTodayPresensiCard(
                      todayJadwal,
                      isSubmitting: submitState.isSubmitting,
                      isAllam: isAllam,
                    )
                  else
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.grey),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tidak ada jadwal presensi untuk hari ini.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  Text(
                    '📋 Riwayat Jadwal Bulan $monthLabel (${listJadwal.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // List Seluruh Jadwal Bulan Ini
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listJadwal.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = listJadwal[index];
                      final Map itemMap = item is Map ? item : {};
                      final tanggal = itemMap['tanggal']?.toString() ?? '-';
                      final waktuIsi =
                          itemMap['waktu_isi_absen']?.toString() ?? '-';
                      final kodeUnik = itemMap['kode_unik']?.toString() ?? '';
                      final List absenUser =
                          (itemMap['absensi_harians'] is List)
                          ? itemMap['absensi_harians']
                          : [];
                      final isHadir = absenUser.isNotEmpty;
                      final isToday = tanggal == todayStr;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isToday ? Colors.blue.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isToday
                                ? Colors.blue.shade300
                                : Colors.grey.shade200,
                            width: isToday ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isHadir
                                      ? Icons.check_circle_rounded
                                      : (isToday
                                            ? Icons.pending_rounded
                                            : Icons.cancel_outlined),
                                  color: isHadir
                                      ? Colors.green
                                      : (isToday ? Colors.blue : Colors.grey),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          tanggal,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isToday
                                                ? Colors.blue.shade900
                                                : Colors.black87,
                                          ),
                                        ),
                                        if (isToday) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade700,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'HARI INI',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isAllam
                                          ? 'Batas: $waktuIsi Menit | Kode: ${kodeUnik.isNotEmpty ? kodeUnik : "-"}'
                                          : 'Batas: $waktuIsi Menit',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (isHadir)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'HADIR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              )
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: Colors.orange.shade800,
                                      side: BorderSide(
                                        color: Colors.orange.shade300,
                                      ),
                                    ),
                                    onPressed: () {
                                      DateTime? parsedDate;
                                      try {
                                        parsedDate = DateTime.tryParse(tanggal);
                                      } catch (_) {}

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SuratIzinFormPage(
                                            initialMatkul: widget.namaKelas,
                                            initialTanggal: parsedDate,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Izin',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      backgroundColor: isToday
                                          ? Colors.blue
                                          : Colors.grey.shade200,
                                      foregroundColor: isToday
                                          ? Colors.white
                                          : Colors.black87,
                                      elevation: isToday ? 1 : 0,
                                    ),
                                    onPressed: () {
                                      _showPresensiDialog(
                                        context: context,
                                        jadwalId: itemMap['id'] as int? ?? 0,
                                        tanggal: tanggal,
                                        autoKode: isAllam ? kodeUnik : null,
                                      );
                                    },
                                    child: const Text(
                                      'Isi Kode',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  if (kDebugMode && isAllam) ...[
                    const SizedBox(height: 20),
                    RawJsonCard(
                      title: 'Raw JSON Jadwal Absensi',
                      icon: Icons.code_rounded,
                      color: Colors.indigo,
                      data: jadwalData,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodayPresensiCard(
    Map todayJadwal, {
    required bool isSubmitting,
    required bool isAllam,
  }) {
    final jadwalId = todayJadwal['id'] as int? ?? 0;
    final tanggal = todayJadwal['tanggal']?.toString() ?? '-';
    final kodeUnik = todayJadwal['kode_unik']?.toString() ?? '';
    final waktuIsi = todayJadwal['waktu_isi_absen']?.toString() ?? '10';
    final List absensiList = (todayJadwal['absensi_harians'] is List)
        ? todayJadwal['absensi_harians']
        : [];
    final bool isAlreadyHadir = absensiList.isNotEmpty;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAlreadyHadir
                ? Colors.green.shade300
                : Colors.blue.shade400,
            width: 1.5,
          ),
          color: isAlreadyHadir ? Colors.green.shade50 : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isAlreadyHadir
                          ? Icons.verified_rounded
                          : Icons.pending_actions_rounded,
                      color: isAlreadyHadir ? Colors.green : Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Presensi Hari Ini ($tanggal)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAlreadyHadir
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isAlreadyHadir ? 'SUDAH HADIR' : 'BELUM PRESENSI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isAlreadyHadir
                          ? Colors.green.shade800
                          : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isAlreadyHadir)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kamu sudah mengisi presensi untuk sesi ini. Kehadiran tercatat Hadir.',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                'Batas waktu pengisian: $waktuIsi menit sejak kelas dimulai.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _todayKodeController,
                      decoration: InputDecoration(
                        hintText: isAllam && kodeUnik.isNotEmpty
                            ? 'Kode Presensi (cth: $kodeUnik)'
                            : 'Masukkan Kode Presensi',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.key, size: 18),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () => _doPresensi(
                            jadwalId: jadwalId,
                            kodeUnik: _todayKodeController.text,
                          ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Kirim',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
              if (isAllam && kodeUnik.isNotEmpty) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    _todayKodeController.text = kodeUnik;
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Auto-fill kode presensi dari server ($kodeUnik)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
