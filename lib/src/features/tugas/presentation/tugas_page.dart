import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../dashboard/presentation/dashboard_providers.dart';
import '../../dashboard/presentation/dashboard_utils.dart';
import '../../dashboard/presentation/kelas_utils.dart';
import '../../dashboard/presentation/widgets/task_item_card.dart';
import 'detail_tugas_page.dart';

class TugasPage extends ConsumerStatefulWidget {
  final int initialTab;
  const TugasPage({super.key, this.initialTab = 0});

  @override
  ConsumerState<TugasPage> createState() => _TugasPageState();
}

class _TugasPageState extends ConsumerState<TugasPage>
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

  List<dynamic> _extractAllTasks(dynamic tugasData, {dynamic kelasData}) {
    return DashboardUtils.extractAllTasks(tugasData, kelasData: kelasData);
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
          'Daftar Tugas',
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
              icon: Icon(Icons.assignment_rounded, size: 20),
              text: 'Kuliah Dosen',
            ),
            Tab(
              icon: Icon(Icons.checklist_rounded, size: 20),
              text: 'Tugas Harian',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildKuliahDosenTab(),
          _buildTugasHarianTab(),
        ],
      ),
    );
  }

  /// Tab 1: Tugas Kuliah Dosen (Semester Reguler)
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
                  'Gagal memuat tugas kuliah dosen: $err',
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
                    'Belum ada kelas matkul dosen terdaftar',
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
                        Icons.assignment_rounded,
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
                            'Tugas Matkul Semester Reguler',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pilih mata kuliah untuk melihat tugas aktif, batas deadline, dan upload tugas.',
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
                final matkulMap =
                    itemMap['matkul'] is Map ? itemMap['matkul'] : {};
                final dosenMap =
                    itemMap['dosen'] is Map ? itemMap['dosen'] : {};
                final userDosenMap =
                    dosenMap['user'] is Map ? dosenMap['user'] : {};

                final namaMatkul =
                    matkulMap['nama_matkul']?.toString() ?? 'Mata Kuliah';
                final kodeMatkul = matkulMap['kode_matkul']?.toString() ?? '-';
                final sks = matkulMap['sks']?.toString() ?? '-';
                final namaDosen = userDosenMap['name']?.toString() ?? '-';
                final kodeKelas = itemMap['kode_kelas']?.toString() ?? '';
                final namaKelas = itemMap['nama_kelas']?.toString() ?? 'TRPL';

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
                                builder: (_) => DetailTugasPage(
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
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.assignment_turned_in_rounded,
                                    size: 13,
                                    color: Color(0xFF1F81FF),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Periksa Tugas & Deadline',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F81FF),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Buka Tugas',
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

  /// Tab 2: Tugas Harian (Tahfidz, Diniah, English)
  Widget _buildTugasHarianTab() {
    final kelasAsync = ref.watch(kelasHarianProvider);
    final tugasAsync = ref.watch(tugasHarianProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(kelasHarianProvider);
        ref.invalidate(tugasHarianProvider);
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
          final listTugas = _extractAllTasks(
            tugasAsync.value,
            kelasData: dataKelas,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECE5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFDCD0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC2410C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment_rounded,
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
                              color: Color(0xFF9A3412),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Klik salah satu kelas harian untuk melihat instruksi dan pengumpulan setoran/tugas.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFC2410C),
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
                          <path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" stroke="#9CA3AF" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
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
                                  builder: (_) => DetailTugasPage(
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
                                color: const Color(0xFFFFECE5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.assignment_outlined,
                                color: Color(0xFFEA580C),
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

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Semua Tugas Harian',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  if (listTugas.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECE5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${listTugas.length} Tugas',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (listTugas.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00D29E), Color(0xFF05B684)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00D29E).withValues(alpha: 0.38),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.2,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Kerja Hebat! Semua Tugas Selesai',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: listTugas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = listTugas[index];
                    final Map itemMap = (item is Map) ? item : {};
                    return TaskItemCard(taskMap: itemMap, index: index);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
