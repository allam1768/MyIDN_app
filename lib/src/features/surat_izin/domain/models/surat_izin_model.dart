import 'dart:typed_data';

/// Pilihan jenis keterangan izin sesuai formulir resmi Politeknik IDN
enum JenisIzin {
  sakitDiRumah('Sakit di Rumah'),
  sakitDiRs('Sakit di RS'),
  lainnya('Lainnya');

  final String label;
  const JenisIzin(this.label);
}

/// Model data permohonan izin tidak masuk kelas
class SuratIzinModel {
  final String namaLengkap;
  final String nim;
  final String jurusanKelas;
  final DateTime mulaiIzin;
  final DateTime akhirIzin;
  final String noHp;
  final JenisIzin jenisIzin;
  final String keterangan;
  final String namaMatkul;
  final String namaMentor;
  final Uint8List? tandaTanganBytes;
  final Uint8List? suratDokterBytes;

  const SuratIzinModel({
    required this.namaLengkap,
    required this.nim,
    required this.jurusanKelas,
    required this.mulaiIzin,
    required this.akhirIzin,
    required this.noHp,
    required this.jenisIzin,
    required this.keterangan,
    this.namaMatkul = '',
    required this.namaMentor,
    this.tandaTanganBytes,
    this.suratDokterBytes,
  });

  /// Menghitung durasi hari izin (inklusif)
  int get durasiHari {
    final start = DateTime(mulaiIzin.year, mulaiIzin.month, mulaiIzin.day);
    final end = DateTime(akhirIzin.year, akhirIzin.month, akhirIzin.day);
    final diff = end.difference(start).inDays;
    return (diff >= 0 ? diff : 0) + 1;
  }

  /// Menampilkan tanggal dengan format Indonesia (contoh: "Jumat, 29 Mei 2026")
  String formatTanggal(DateTime date) {
    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final namaHari = hari[date.weekday - 1];
    final namaBulan = bulan[date.month - 1];
    return '$namaHari, ${date.day} $namaBulan ${date.year}';
  }

  /// Format teks lama izin sesuai docx (contoh: "1 Hari (Jumat, 29 Mei 2026)")
  String get lamaIzinFormatted {
    final days = durasiHari;
    if (days == 1) {
      return '1 Hari (${formatTanggal(mulaiIzin)})';
    } else {
      return '$days Hari (${formatTanggal(mulaiIzin)} s.d. ${formatTanggal(akhirIzin)})';
    }
  }

  String get mulaiIzinFormatted => formatTanggal(mulaiIzin);
  String get akhirIzinFormatted => formatTanggal(akhirIzin);

  bool get isSakit =>
      jenisIzin == JenisIzin.sakitDiRumah || jenisIzin == JenisIzin.sakitDiRs;

  /// Pesan WhatsApp pengantar formal untuk Asdos/Mentor
  String generateWhatsAppMessage() {
    final sapaan = namaMentor.isNotEmpty ? namaMentor : 'Bapak/Ibu/Kakak';
    final matkulInfo = namaMatkul.isNotEmpty
        ? ' untuk mata kuliah $namaMatkul'
        : '';

    return '''Assalamu'alaikum Warahmatullahi Wabarakatuh,
Yth. $sapaan,

Perkenalkan saya:
Nama: $namaLengkap
NIM: $nim
Jurusan/Kelas: $jurusanKelas

Bermaksud mengajukan permohonan izin tidak mengikuti kelas$matkulInfo pada:
Tanggal: $lamaIzinFormatted
Alasan: ${jenisIzin.label} ($keterangan)

Bersama dengan pesan ini, saya lampirkan surat izin resmi bertanda tangan (dan surat dokter jika ada). Mohon izin dan arahannya jika ada tugas atau materi pengganti yang perlu saya pelajari.

Terima kasih atas perhatian dan kebijaksanaan $sapaan.
Wassalamu'alaikum Warahmatullahi Wabarakatuh.''';
  }
}
