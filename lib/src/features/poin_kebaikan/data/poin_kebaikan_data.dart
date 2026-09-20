// Generated data for Google Form Poin Kebaikan
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KebaikanItem {
  final String id;
  final String label;
  final String value;

  const KebaikanItem({
    required this.id,
    required this.label,
    required this.value,
  });
}

class KebaikanCategory {
  final String key;
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final List<KebaikanItem> items;

  const KebaikanCategory({
    required this.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.items,
  });
}

class PoinKebaikanConfig {
  static const String formUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLSeYVaIo7C9bxx14Ea9rbSaj7PTsu88-fgJOV9YqJsDeyDDlGg/formResponse';

  static const String entryAngkatan = 'entry.797821628';
  static const String entryProdi = 'entry.1755450003';
  static const String entryNama = 'entry.1060416800';
  static const String entryJanji = 'entry.808834917';
  static const String entrySaran = 'entry.267775390';

  static const String janjiValue = 'Ya, saya berjanji.';
  static const String defaultAngkatan = 'Angkatan 5 (2026)';

  static const List<String> prodiList = [
    'TRPL (Programmer)',
    'TRMG (Designer)',
    'TRKJ (Engineer)',
  ];

  static const List<String> namaList = [
    'Abdul Azhim',
    'Abdurrahman Hasanul Azzam',
    'Abid Shafaa Ayyuasy',
    'Abu Devis Jalaluddin Rumi',
    'Adama Qorie Alee Abidzhar',
    'Ahmad Habib Arroyyan',
    'Ahmadin Umair Pasomal Rambe',
    'Akbar Barokah',
    'Allam Permata Putra',
    'Amir Qowwiyul Amin',
    'Andi Allianz Surya Negara',
    'Asvi War Raikhan',
    'Azam Muda Kafilaya',
    'Bintang Athaya Ashil An Nur',
    'Daffa Lukmanul Hakim',
    'Dzulfathan',
    'Ekuivalen Muhammad Firdaus',
    'Fakhriza Aksan Wajdi Zulkarnain',
    'Fatih Ar Razak',
    'Fauzan Achmad Rizky',
    'Hammam Fauzul Adzim Bin Hudaa',
    'Hamzah Nur Abdul Aziz',
    'Hanif Faiza',
    'Hibban Ismail',
    'Hudzaifah Abduljabbar',
    'Ibnu Zaidan Riziq',
    'Ihsan Fawwas Zaidan',
    'Ilman Fayyaz',
    'Marcelo Kausar',
    'Maulana Ahmad Khairunnas',
    'Muh. Faiz',
    'Muhamad Afif Lathiful Khuluqi',
    'Muhammad Azhar Habibillah',
    'Muhammad Daffa',
    'Muhammad Daud',
    'Muhammad Dzakiy',
    'Muhammad Faqihul Ahkam',
    'Muhammad Isa Dawud',
    'Muhammad Maulana Arya Chandra',
    'Muhammad Nabil Rizkiarda',
    'Muhammad Navid Athallah',
    'Muhammad Tsaqif Arhab',
    'Muhammad Tsaurie',
    'Muhammad Zia Zulfa',
    'Naufarros Ghulamuzaky',
    'Rafi Abdillah',
    'Rafi Albani Syafarel',
    'Rayyandra Abinaya Fabian Ahmadi',
    'Rofiq Shafia Zahir',
    'Ryo Akmal Prastowo',
    'Sayid Muhammad Ghalib',
    'Septian Ghozi Mustofa',
    'Wan Ashraff Devaldo',
    'Yasir Shalih',
  ];

  static const List<KebaikanCategory> categories = [
    KebaikanCategory(
      key: 'A - AKADEMIK',
      title: 'Akademik',
      icon: Icons.school_rounded,
      color: Color(0xFF4F46E5),
      bgColor: Color(0xFFEEF2FF),
      items: [
        KebaikanItem(
          id: '1471332530',
          label: 'A1-Mengingatkan mengerjakan tugas',
          value: 'Ya',
        ),
        KebaikanItem(
          id: '1819169229',
          label: 'A2-Membimbing teman mengerjakan tugas',
          value: 'Ya',
        ),
        KebaikanItem(
          id: '1274287699',
          label:
              'A3-Membantu teman yang kesulitan saat belajar teori ataupun praktik',
          value: 'Ya',
        ),
        KebaikanItem(
          id: '810511448',
          label: 'A4-Mengajarkan materi yang sudah dipelajari kepada teman',
          value: 'Ya',
        ),
      ],
    ),
    KebaikanCategory(
      key: 'B - IBADAH',
      title: 'Ibadah',
      icon: Icons.mosque_rounded,
      color: Color(0xFF0D9488),
      bgColor: Color(0xFFF0FDFA),
      items: [
        KebaikanItem(
          id: '1200147495',
          label:
              'B1-Melakukan Adzan dan Iqomah di masjid pada shalat berjamaah',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1291629774',
          label: 'B2-Menjadi Imam Sholat Wajib 1 waktu sholat',
          value: 'YA',
        ),
        KebaikanItem(
          id: '502571954',
          label: 'B3-Menjadi Khotib Jumatan',
          value: 'YA',
        ),
      ],
    ),
    KebaikanCategory(
      key: 'C - KEBERSIHAN',
      title: 'Kebersihan',
      icon: Icons.cleaning_services_rounded,
      color: Color(0xFF16A34A),
      bgColor: Color(0xFFF0FDF4),
      items: [
        KebaikanItem(
          id: '1347479728',
          label: 'C1-Membuang sampah di jalan ke tempat sampah',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1532047304',
          label: 'C2-Menyapu tempat makan',
          value: 'YA',
        ),
        KebaikanItem(id: '778190216', label: 'C3-Menyapu kelas', value: 'YA'),
        KebaikanItem(id: '1870969367', label: 'C4-Menyapu asrama', value: 'YA'),
        KebaikanItem(
          id: '2096473594',
          label: 'C5-Menyikat 1 ember kamar mandi',
          value: 'YA',
        ),
        KebaikanItem(
          id: '2036617351',
          label: 'C6-Membuang sampah dari tong sampah ke pembuangan akhir',
          value: 'YA',
        ),
        KebaikanItem(id: '2124587081', label: 'C7-Menyapu masjid', value: 'YA'),
        KebaikanItem(
          id: '1099044340',
          label: 'C8-Mengepel tempat makan',
          value: 'YA',
        ),
        KebaikanItem(
          id: '412165360',
          label: 'C9-Mengelap 1 meja dan kursi di tempat makan',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1815776845',
          label: 'C10-Mencabut rumput dengan sarung tangan 20 menit',
          value: 'YA',
        ),
        KebaikanItem(id: '992204047', label: 'C11-Mencuci Gorden', value: 'YA'),
        KebaikanItem(id: '708873702', label: 'C12-Mengepel kelas', value: 'YA'),
        KebaikanItem(
          id: '1996992300',
          label: 'C13-Mengepel asrama',
          value: 'YA',
        ),
        KebaikanItem(
          id: '828251601',
          label: 'C14-Memotong rumput dengan parang 20 menit',
          value: 'YA',
        ),
        KebaikanItem(
          id: '84375873',
          label: 'C15-Menyapu jalan dari daun, pasir, atau rumput 15 menit',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1020210542',
          label: 'C16-Membersihkan dapur umum',
          value: 'YA',
        ),
        KebaikanItem(
          id: '427768064',
          label: 'C17-Menyikat dan membersihkan 1 tong sampah',
          value: 'YA',
        ),
        KebaikanItem(
          id: '339551508',
          label: 'C18-Mengepel masjid',
          value: 'YA',
        ),
        KebaikanItem(
          id: '2045662533',
          label: 'C19-Menyikat lantai dan dinding 1 kamar mandi',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1933106547',
          label: 'C20-Memotong rumput dengan mesin di 15 menit',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1548087773',
          label:
              'C21-Membersihkan ruang meeting outdoor, lantai, meja, kursi, buang sampah.',
          value: 'YA',
        ),
        KebaikanItem(
          id: '520154632',
          label: 'C22-Menyikat dan membersihkan semua wastafel di tempat makan',
          value: 'YA',
        ),
        KebaikanItem(
          id: '364953744',
          label: 'C23-Menyikat area tempat wudhu',
          value: 'YA',
        ),
      ],
    ),
    KebaikanCategory(
      key: 'D - LINGKUNGAN',
      title: 'Lingkungan',
      icon: Icons.eco_rounded,
      color: Color(0xFF0284C7),
      bgColor: Color(0xFFF0F9FF),
      items: [
        KebaikanItem(
          id: '141364244',
          label: 'D1-Menyingkirkan batu atau barang yang mengganggu di jalan',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1311695704',
          label: 'D2-Mematikan lampu masjid saat terang',
          value: 'YA',
        ),
        KebaikanItem(
          id: '2099862091',
          label: 'D3-Mematikan kipas masjid saat malam',
          value: 'YA',
        ),
        KebaikanItem(
          id: '171304787',
          label: 'D4-Menyalakan lampu jalan saat malam',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1797027225',
          label: 'D5-Menyalakan lampu masjid saat malam',
          value: 'YA',
        ),
        KebaikanItem(
          id: '193753939',
          label: 'D6-Menyalakan lampu toilet saat malam',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1966545634',
          label: 'D7-Mematikan lampu WC baik yang di dalam atau diluar',
          value: 'YA',
        ),
        KebaikanItem(
          id: '395463027',
          label: 'D8-Mematikan Kipas kelas',
          value: 'YA',
        ),
        KebaikanItem(
          id: '551611652',
          label: 'D9-Mematikan TV kelas',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1267246738',
          label: 'D10-Mematikan Kipas di Asrama',
          value: 'YA',
        ),
        KebaikanItem(
          id: '754889421',
          label: 'D11-Merapikan Kursi di kelas',
          value: 'YA',
        ),
        KebaikanItem(
          id: '466418206',
          label: 'D12-Mengambil baju yang jatuh di area jemuran',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1333815443',
          label: 'D13-Menutup keran WC yang airnya sudah luber',
          value: 'YA',
        ),
        KebaikanItem(
          id: '57266648',
          label: 'D14-Merapikan Kabel Terminal di Kelas',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1642586824',
          label: 'D15-Merapikan Sandal di Asrama',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1911151022',
          label: 'D16-Merapikan Al-Quran di rak masjid',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1866356506',
          label: 'D17-Melaporkan kerusakan fasilitas kampus ke pihak sarpras',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1424729911',
          label: 'D18-Menyiram tanaman 15 menit',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1648222154',
          label: 'D19-Merawat atau merapikan tanaman 15 menit',
          value: 'YA',
        ),
        KebaikanItem(
          id: '960105375',
          label: 'D20-Merapikan Sandal di Masjid',
          value: 'YA',
        ),
        KebaikanItem(
          id: '2093373811',
          label: 'D21-Membersihkan langit-langit kelas',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1938313922',
          label: 'D22-Membersihkan 1 kipas angin di lingkungan kampus',
          value: 'YA',
        ),
        KebaikanItem(
          id: '747428402',
          label: 'D23-Membersihkan langit-langit masjid',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1486153653',
          label: 'D24-Menanam pohon, tanaman hias, atau tanaman buah dan sayur',
          value: 'YA',
        ),
        KebaikanItem(
          id: '599391212',
          label: 'D25-Membuang bangkai atau sampah yang berbau menyengat',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1927365359',
          label: 'D26-Ronda malam jaga kampus 1 malam dari jam 22:00 - 03:30',
          value: 'YA',
        ),
      ],
    ),
    KebaikanCategory(
      key: 'E - PELAYANAN',
      title: 'Pelayanan',
      icon: Icons.handshake_rounded,
      color: Color(0xFFD97706),
      bgColor: Color(0xFFFFFBEB),
      items: [
        KebaikanItem(
          id: '1647389561',
          label: 'E1-Nitip belikan makanan atau minuman untuk teman',
          value: 'YA',
        ),
        KebaikanItem(
          id: '2086415178',
          label:
              'E2-Antar jemput teman dari kos atau kontrakan terdekat ke kampus',
          value: 'YA',
        ),
        KebaikanItem(
          id: '2137024128',
          label: 'E3-Nitip belikan makanan atau minuman untuk staff kampus',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1559520442',
          label: 'E4-Mengantarkan 1 air galon dari sarpras ke kantor',
          value: 'YA',
        ),
        KebaikanItem(
          id: '514603078',
          label:
              'E5-Menerima dan melayani tamu dengan 5S, dan mengantarnya ke pihak kampus yang berwenang',
          value: 'YA',
        ),
        KebaikanItem(
          id: '530865278',
          label: 'E6-Mengantar teman membeli kebutuhan di asrama kampus',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1683000813',
          label: 'E7-Meminjamkan Kendaraan untuk teman',
          value: 'YA',
        ),
        KebaikanItem(
          id: '99429675',
          label: 'E8-Meminjamkan Kendaraan untuk staff kampus',
          value: 'YA',
        ),
        KebaikanItem(
          id: '447250709',
          label: 'E9-Mengantar dosen, asisten dosen, atau staff kampus',
          value: 'YA',
        ),
        KebaikanItem(
          id: '2053030720',
          label:
              'E10-Mengantar teman dari asrama kampus ke transportasi umum terdekat',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1257834495',
          label:
              'E11-Menjemput teman yang sedang perjalanan menuju asrama kampus dari transportasi umum',
          value: 'YA',
        ),
      ],
    ),
    KebaikanCategory(
      key: 'F - SOSIAL',
      title: 'Sosial',
      icon: Icons.people_alt_rounded,
      color: Color(0xFFE11D48),
      bgColor: Color(0xFFFFF1F2),
      items: [
        KebaikanItem(
          id: '1806723241',
          label: 'F1-Meminjamkan alat mandi kepada teman',
          value: 'YA',
        ),
        KebaikanItem(
          id: '143915327',
          label: 'F2-Meminjamkan pakaian kepada teman',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1192034598',
          label: 'F3-Meminjamkan alat tulis atau belajar kepada teman',
          value: 'YA',
        ),
        KebaikanItem(
          id: '510721769',
          label: 'F4-Menjenguk teman yang sakit di asrama',
          value: 'YA',
        ),
        KebaikanItem(
          id: '64961846',
          label: 'F5-Mendengarkan curhatan dari teman yang sedang kesulitan',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1989743704',
          label:
              'F6-Membangunkan teman-teman di asrama untuk sholat shubuh berjamaah',
          value: 'YA',
        ),
        KebaikanItem(
          id: '103896401',
          label: 'F7-Mengajak teman sholat tahajud',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1955244124',
          label: 'F8-Mengajak teman sholat dhuha hingga benar-benar sholat',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1452721431',
          label: 'F9-Mengantarkan makan untuk teman yang sakit',
          value: 'YA',
        ),
        KebaikanItem(
          id: '284282774',
          label: 'F10-Memberikan obat untuk teman yang sakit',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1316848067',
          label: 'F11-Menjenguk teman yang sakit di kos',
          value: 'YA',
        ),
        KebaikanItem(
          id: '287076259',
          label: 'F12-Mengangkat Air Galon dari sarpras ke Asrama',
          value: 'YA',
        ),
        KebaikanItem(
          id: '640617688',
          label: 'F13-Membantu membawa kebutuhan acara ketika ada kegiatan',
          value: 'YA',
        ),
        KebaikanItem(
          id: '1047137429',
          label: 'F14-Melaksanakan sholat tahajud berjamaah',
          value: 'YA',
        ),
        KebaikanItem(
          id: '718212531',
          label: 'F15-Mengantar teman yang sakit ke Puskesmas atau ke RS',
          value: 'YA',
        ),
      ],
    ),
  ];

  static const String _keyLastSubmitDate = 'last_kebaikan_submit_date';

  static String getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  static Future<bool> isDoneToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keyLastSubmitDate);
    return lastDate == getTodayDateString();
  }

  static Future<void> markDoneToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSubmitDate, getTodayDateString());
  }
}
