import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/date_utils.dart';
import '../../dashboard/presentation/dashboard_providers.dart';
import 'input_ibadah_page.dart';

class LaporanIbadahPage extends ConsumerWidget {
  const LaporanIbadahPage({super.key});

  String _formatDateIndo(String dateStr) =>
      AppDateUtils.formatDateIndo(dateStr);

  Future<void> _openInputPage(
    BuildContext context,
    WidgetRef ref, {
    String? tanggal,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InputIbadahPage(initialTanggal: tanggal),
      ),
    );

    if (result == true) {
      ref.invalidate(ibadahHarianProvider);
    }
  }

  Future<void> _pickDateAndOpen(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      helpText: 'Pilih Tanggal Laporan Ibadah',
    );

    if (picked != null && context.mounted) {
      final dateStr =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      _openInputPage(context, ref, tanggal: dateStr);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ibadahAsync = ref.watch(ibadahHarianProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF111827),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Laporan Ibadah Harian',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openInputPage(context, ref),
        backgroundColor: const Color(0xFF0D9488),
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: const Text(
          'Isi Laporan Ibadah',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF0D9488),
        onRefresh: () async => ref.invalidate(ibadahHarianProvider),
        child: ibadahAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF0D9488),
              strokeWidth: 2,
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Gagal memuat data laporan: $err',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(ibadahHarianProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (raw) {
            List<dynamic> listStatuses = [];
            if (raw is Map && raw['props'] is Map) {
              final props = raw['props'];
              if (props['laporanStatuses'] is List) {
                listStatuses = props['laporanStatuses'];
              }
            }

            final todayItem = listStatuses.isNotEmpty && listStatuses[0] is Map
                ? listStatuses[0] as Map
                : null;
            final todayStatus =
                todayItem?['status']?.toString() ?? 'Belum Mengisi';
            final isTodayDone = todayStatus.toLowerCase().contains('terkirim');
            final todayTanggal =
                todayItem?['tanggal']?.toString() ??
                "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                // 1. Card Status Hari Ini & Tombol Aksi Cepat
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isTodayDone
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isTodayDone
                          ? const Color(0xFFBBF7D0)
                          : const Color(0xFFFDE68A),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isTodayDone
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isTodayDone
                                  ? Icons.check_circle_rounded
                                  : Icons.pending_actions_rounded,
                              color: isTodayDone
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFD97706),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Status Hari Ini',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDateIndo(todayTanggal),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isTodayDone
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFD97706),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isTodayDone ? 'Terkirim' : 'Belum Mengisi',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isTodayDone
                            ? 'Alhamdulillah, kamu sudah mengisi laporan ibadah untuk hari ini. Kamu tetap bisa mengubah data jika diperlukan.'
                            : 'Jangan lupa untuk mengisi laporan ibadah harianmu agar presensi dan poin ibadah tercatat.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openInputPage(
                            context,
                            ref,
                            tanggal: todayTanggal,
                          ),
                          icon: Icon(
                            isTodayDone
                                ? Icons.edit_note_rounded
                                : Icons.post_add_rounded,
                            size: 18,
                          ),
                          label: Text(
                            isTodayDone
                                ? 'Ubah Laporan Hari Ini'
                                : 'Isi Laporan Hari Ini Sekarang',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isTodayDone
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Header Section Riwayat Pengisian
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Pengisian',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Ketuk tanggal untuk melihat / mengisi laporan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pickDateAndOpen(context, ref),
                      icon: const Icon(
                        Icons.date_range_rounded,
                        size: 15,
                        color: Color(0xFF0D9488),
                      ),
                      label: const Text(
                        'Pilih Tanggal',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0D9488),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0D9488)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 3. List Riwayat Data Sebelumnya
                if (listStatuses.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_late_outlined,
                          size: 56,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum Ada Riwayat Laporan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Data riwayat laporan ibadah kamu akan muncul di sini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...listStatuses.map((item) {
                    final Map m = item is Map ? item : {};
                    final tgl = m['tanggal']?.toString() ?? '-';
                    final st = m['status']?.toString() ?? '-';
                    final diisiPada = m['diisi_pada']?.toString();
                    final isDone = st.toLowerCase().contains('terkirim');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDone
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFFFED7AA),
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x05000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => _openInputPage(context, ref, tanggal: tgl),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? const Color(0xFFF0FDF4)
                                      : const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isDone
                                      ? Icons.check_circle_rounded
                                      : Icons.schedule_rounded,
                                  color: isDone
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFEA580C),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDateIndo(tgl),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text(
                                          isDone ? 'Terkirim' : 'Belum Mengisi',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDone
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFFEA580C),
                                          ),
                                        ),
                                        if (diisiPada != null &&
                                            diisiPada.isNotEmpty) ...[
                                          const Text(
                                            ' • ',
                                            style: TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            diisiPada,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? const Color(0xFFF1F5F9)
                                      : const Color(0xFF0D9488),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isDone ? 'Ubah' : 'Isi',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDone
                                            ? const Color(0xFF475569)
                                            : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: isDone
                                          ? const Color(0xFF475569)
                                          : Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}
