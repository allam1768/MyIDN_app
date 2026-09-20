/// Kumpulan endpoint resmi LMS Politeknik IDN
/// Disentralisasi agar aman, mudah dipelihara, dan tidak tercecer di sembarang file.
class LmsEndpoints {
  LmsEndpoints._();

  static const String baseUrl = 'https://lms.politeknikidn.id';

  // Auth
  static const String login = '/signin';
  static const String logout = '/signout';

  // Mahasiswa Core
  static const String dashboard = '/my/dashboard';
  static const String kelasHarian = '/my/mhs/harian/kelas_harian';
  static const String tugasHarian = '/my/mhs/harian/tugas_harian';
  static const String absensiHarian = '/my/mhs/harian/absensi_harian';
  static const String materiHarian = '/my/mhs/harian/materi_harian';

  // Materi Detail
  static String detailMateri(String kodeKelas) =>
      '/my/mhs/harian/materi_harian/class/$kodeKelas/materi';

  // Tugas Detail & Pengumpulan
  static String detailTugas(String kodeKelas) =>
      '/my/mhs/harian/tugas_harian/class/$kodeKelas/tugas';
  static const String submitTugasHarian =
      '/my/mhs/harian/tugas_harian/sendTugas';

  // Ibadah Harian
  static const String laporanIbadahHarian = '/my/mhs/laporan-ibadah-harian';
  static const String formIbadahHarian =
      '/my/mhs/laporan-ibadah-harian/input_laporan_ibadah';

  // Absensi Detail & Presensi
  static String listJadwalAbsensi(String kodeKelas, String monthParam) =>
      '/my/mhs/harian/absensi_harian/$kodeKelas/$monthParam/listJadwal';
  static const String submitPresensi =
      '/my/mhs/harian/absensi_harian/doPresence';

  // Laporan SKL (Standar Kompetensi Lulusan)
  static String laporanSkl(String mahasiswaUuid) =>
      '/my/laporan/skl/$mahasiswaUuid';
  static String detailSklMahasiswa(String mahasiswaUuid) =>
      '/my/laporan/skl/$mahasiswaUuid/detail';
  static String sklChartData(String mahasiswaUuid) =>
      '/my/laporan/skl/$mahasiswaUuid/chart';
}
