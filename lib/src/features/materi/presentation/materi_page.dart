import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../dashboard/presentation/dashboard_providers.dart';
import '../../dashboard/presentation/kelas_utils.dart';
import 'detail_materi_page.dart';

class MateriPage extends ConsumerWidget {
  const MateriPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kelasAsync = ref.watch(kelasHarianProvider);
    final materiAsync = ref.watch(materiHarianProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF111827),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Materi Kuliah',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(kelasHarianProvider);
          ref.invalidate(materiHarianProvider);
        },
        child: kelasAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
                    'Gagal memuat jadwal kelas: $err',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(kelasHarianProvider),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
          data: (dataKelas) {
            final listKelas = KelasUtils.extractClassesList(dataKelas);

            // Ekstraksi materi umum jika ada
            List<dynamic> listMateriUmum = [];
            final rawMateri = materiAsync.value;
            if (rawMateri is Map && rawMateri['props'] is Map) {
              final m =
                  rawMateri['props']['materi_harian'] ??
                  rawMateri['props']['materi'];
              if (m is List) listMateriUmum = m;
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E7FF)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pilih Kelas untuk Buka Materi',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF312E81),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Klik salah satu kelas di bawah untuk melihat dokumen, presentasi, dan materi ajar.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4338CA),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section Title
                if (listKelas.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada kelas aktif hari ini',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...listKelas.map((item) {
                    final Map itemMap = (item is Map) ? item : {};
                    final namaKelas =
                        itemMap['nama_kelas']?.toString() ?? 'Mata Kuliah';
                    final kodeKelas =
                        itemMap['kode_kelas_harian']?.toString() ?? '';
                    final dosenName = KelasUtils.extractDosenName(
                      itemMap['dosen'],
                      itemMap['nama_dosen'],
                    );
                    final iconInfo = KelasUtils.getMapelIcon(namaKelas);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: kodeKelas.isNotEmpty
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DetailMateriPage(
                                        kodeKelasHarian: kodeKelas,
                                        namaKelas: namaKelas,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: iconInfo.bg,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: iconInfo.svgAsset != null
                                        ? SvgPicture.asset(
                                            iconInfo.svgAsset!,
                                            width: 24,
                                            height: 24,
                                            colorFilter: ColorFilter.mode(
                                              iconInfo.color,
                                              BlendMode.srcIn,
                                            ),
                                          )
                                        : Icon(
                                            iconInfo.icon,
                                            color: iconInfo.color,
                                            size: 26,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        namaKelas,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF111827),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.person_outline_rounded,
                                            size: 13,
                                            color: Color(0xFF6B7280),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              dosenName,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF4B5563),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Materi',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4F46E5),
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 11,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                // Jika ada materi umum dari API
                if (listMateriUmum.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Materi Lainnya',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...listMateriUmum.map((item) {
                    final Map itemMap = (item is Map) ? item : {};
                    final namaKelas =
                        itemMap['nama_kelas']?.toString() ?? 'Mata Kuliah';
                    final judulMateri =
                        itemMap['judul']?.toString() ??
                        itemMap['topik']?.toString() ??
                        'Materi';
                    final kodeKelas =
                        itemMap['kode_kelas_harian']?.toString() ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.file_present_rounded,
                          color: Color(0xFF4F46E5),
                        ),
                        title: Text(
                          judulMateri,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          namaKelas,
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: kodeKelas.isNotEmpty
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailMateriPage(
                                      kodeKelasHarian: kodeKelas,
                                      namaKelas: namaKelas,
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),
                    );
                  }),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
