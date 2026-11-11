import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../dashboard/presentation/dashboard_providers.dart';
import '../../dashboard/presentation/kelas_utils.dart';
import 'detail_materi_page.dart';

class MateriPage extends ConsumerStatefulWidget {
  final int initialTab;
  const MateriPage({super.key, this.initialTab = 0});

  @override
  ConsumerState<MateriPage> createState() => _MateriPageState();
}

class _MateriPageState extends ConsumerState<MateriPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          'Materi Perkuliahan',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1F81FF),
          unselectedLabelColor: const Color(0xFF6B7280),
          indicatorColor: const Color(0xFF1F81FF),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(
              icon: Icon(Icons.school_rounded, size: 20),
              text: 'Kuliah Dosen',
            ),
            Tab(
              icon: Icon(Icons.calendar_today_rounded, size: 20),
              text: 'Kelas Harian',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildKuliahDosenTab(),
          _buildKelasHarianTab(),
        ],
      ),
    );
  }

  /// Tab 1: Daftar Materi Kuliah Dosen (Semester Reguler)
  Widget _buildKuliahDosenTab() {
    final kelasMatkulAsync = ref.watch(kelasMatkulProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(kelasMatkulProvider),
      child: kelasMatkulAsync.when(
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
                  'Gagal memuat kelas matkul dosen: $err',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(kelasMatkulProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (raw) {
          List<dynamic> classes = [];
          if (raw is Map && raw['props'] is Map) {
            final k = raw['props']['kelas'];
            if (k is Map && k['data'] is List) {
              classes = k['data'];
            } else if (k is List) {
              classes = k;
            }
          }

          if (classes.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Text(
                    'Belum ada kelas matkul dosen yang terdaftar',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F81FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
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
                            'Materi Matkul Semester Reguler',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pilih mata kuliah di bawah untuk membuka modul dan materi resmi dari dosen pengampu.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ...classes.map((item) {
                final Map itemMap = (item is Map) ? item : {};
                final matkulMap = itemMap['matkul'] is Map ? itemMap['matkul'] : {};
                final dosenMap = itemMap['dosen'] is Map ? itemMap['dosen'] : {};
                final userDosenMap = dosenMap['user'] is Map ? dosenMap['user'] : {};

                final namaMatkul = matkulMap['nama_matkul']?.toString() ?? 'Mata Kuliah';
                final kodeMatkul = matkulMap['kode_matkul']?.toString() ?? '-';
                final sks = matkulMap['sks']?.toString() ?? '-';
                final namaDosen = userDosenMap['name']?.toString() ?? '-';
                final kodeKelas = itemMap['kode_kelas']?.toString() ?? '';
                final namaKelas = itemMap['nama_kelas']?.toString() ?? 'TRPL';
                final materisCount = itemMap['materis_count']?.toString() ?? '0';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    onTap: kodeKelas.isNotEmpty
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailMateriPage(
                                  kodeKelasHarian: kodeKelas,
                                  namaKelas: namaMatkul,
                                  isMatkulDosen: true,
                                ),
                              ),
                            );
                          }
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  kodeMatkul,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      namaKelas,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Text(
                                      '$sks SKS',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            namaMatkul,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Dosen: $namaDosen',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.menu_book_rounded,
                                    size: 13,
                                    color: Color(0xFF1F81FF),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$materisCount Materi Terunggah',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F81FF),
                                    ),
                                  ),
                                ],
                              ),
                              const Row(
                                children: [
                                  Text(
                                    'Buka Materi',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F81FF),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: Color(0xFF1F81FF),
                                  ),
                                ],
                              ),
                            ],
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
    );
  }

  /// Tab 2: Daftar Materi Kelas Harian (Tahfidz, Diniah, English)
  Widget _buildKelasHarianTab() {
    final kelasAsync = ref.watch(kelasHarianProvider);
    final materiAsync = ref.watch(materiHarianProvider);

    return RefreshIndicator(
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
          final listKelas = KelasUtils.extractClassesList(
            dataKelas,
            dashboardData: ref.watch(dashboardMahasiswaProvider).valueOrNull,
          );

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
                            'Pilih Kelas Harian',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF312E81),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Materi pembinaan asrama, tahfidz Al-Qur\'an, diniyyah, dan bahasa.',
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
              const SizedBox(height: 16),

              if (listKelas.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      SvgPicture.string(
                        '''<svg width="64" height="64" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                          <path d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" stroke="#9CA3AF" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                        </svg>''',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada kelas harian terdaftar',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...listKelas.map((item) {
                  final Map itemMap = (item is Map) ? item : {};
                  final namaKelas =
                      itemMap['nama_kelas_harian']?.toString() ??
                      itemMap['nama_kelas']?.toString() ??
                      'Kelas';
                  final kodeKelas =
                      itemMap['kode_kelas_harian']?.toString() ??
                      itemMap['kode_kelas']?.toString() ??
                      '';
                  final guru =
                      itemMap['guru']?.toString() ??
                      itemMap['dosen']?.toString() ??
                      itemMap['pengajar']?.toString() ??
                      '-';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: InkWell(
                      onTap: kodeKelas.isNotEmpty
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailMateriPage(
                                    kodeKelasHarian: kodeKelas,
                                    namaKelas: namaKelas,
                                    isMatkulDosen: false,
                                  ),
                                ),
                              );
                            }
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                color: Color(0xFF4F46E5),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    namaKelas,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pengajar: $guru',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

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
                                    isMatkulDosen: false,
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
    );
  }
}
