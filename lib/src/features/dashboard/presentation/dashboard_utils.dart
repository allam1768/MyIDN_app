import '../application/dashboard_helpers.dart';
import '../domain/models/user_profile_model.dart';
import 'kelas_utils.dart';

/// Kumpulan utilitas pemrosesan data dashboard (Profil, Tugas, Deadline)
class DashboardUtils {
  DashboardUtils._();

  /// Ekstraksi nama mahasiswa dari payload LMS
  static String extractUserName(
    dynamic dashboardData,
    dynamic kelasData, [
    dynamic extraData,
  ]) {
    for (final src in [dashboardData, kelasData, extraData]) {
      if (src is Map && src['props'] is Map) {
        final props = src['props'];
        final user =
            props['auth']?['user'] ??
            props['user'] ??
            props['mahasiswa'] ??
            props['profile'];
        if (user is Map) {
          final name =
              user['name'] ??
              user['nama'] ??
              user['nama_lengkap'] ??
              user['nama_mahasiswa'];
          if (name != null && name.toString().trim().isNotEmpty) {
            return name.toString().trim();
          }
        }
      }
    }
    return 'Mahasiswa';
  }

  /// Memeriksa apakah pengguna saat ini adalah akun Allam Permata Putra (Creator / Authorized).
  /// Mendukung evaluasi dari parameter name, dashboardData, kelasData, maupun extraData (misal payload absensi).
  static bool isAllamPermataPutra({
    String? name,
    dynamic dashboardData,
    dynamic kelasData,
    dynamic extraData,
  }) {
    // 1. Cek dari parameter name jika diberikan secara eksplisit
    if (name != null && name.trim().isNotEmpty) {
      final n = name.toLowerCase().trim();
      if (n.contains('allam permata putra') ||
          (n.contains('allam') && n.contains('putra'))) {
        return true;
      }
    }

    // 2. Cek nama ter-ekstrak dari berbagai sumber data
    final extractedName = extractUserName(
      dashboardData,
      kelasData,
      extraData,
    ).toLowerCase().trim();
    if (extractedName.contains('allam permata putra') ||
        (extractedName.contains('allam') && extractedName.contains('putra'))) {
      return true;
    }

    // 3. Pengecekan mendalam terhadap username dan raw property lainnya
    for (final src in [dashboardData, kelasData, extraData]) {
      if (src is Map && src['props'] is Map) {
        final props = src['props'];
        final user =
            props['auth']?['user'] ??
            props['user'] ??
            props['mahasiswa'] ??
            props['profile'];
        if (user is Map) {
          final username = (user['username'] ?? '')
              .toString()
              .toLowerCase()
              .trim();
          final rawName =
              (user['name'] ??
                      user['nama'] ??
                      user['nama_lengkap'] ??
                      user['nama_mahasiswa'] ??
                      '')
                  .toString()
                  .toLowerCase()
                  .trim();
          if (username.contains('allam permata putra') ||
              rawName.contains('allam permata putra') ||
              (username.contains('allam') && username.contains('putra')) ||
              (rawName.contains('allam') && rawName.contains('putra'))) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Ekstraksi NIM mahasiswa dari payload LMS
  static String extractUserNim(dynamic dashboardData, dynamic kelasData) {
    for (final src in [dashboardData, kelasData]) {
      if (src is Map && src['props'] is Map) {
        final props = src['props'];
        final user =
            props['auth']?['user'] ??
            props['user'] ??
            props['mahasiswa'] ??
            props['profile'];
        if (user is Map) {
          final mhs =
              user['mahasiswa'] ?? props['auth']?['mhs'] ?? props['mhs'];
          if (mhs is Map && mhs['nim'] != null) {
            return mhs['nim'].toString().trim();
          }
          final nim = user['nim'] ?? user['username'] ?? user['nomor_induk'];
          if (nim != null && nim.toString().trim().isNotEmpty) {
            return nim.toString().trim();
          }
        }
      }
    }
    return '';
  }

  /// Ekstraksi UUID mahasiswa dari payload LMS (digunakan untuk Laporan SKL)
  static String? extractUserUuid(dynamic dashboardData) {
    if (dashboardData == null) return null;
    if (dashboardData is Map && dashboardData['props'] is Map) {
      final props = dashboardData['props'];
      final user =
          props['auth']?['user'] ??
          props['user'] ??
          props['mahasiswa'] ??
          props['profile'];
      if (user is Map) {
        final mhs = user['mahasiswa'] ?? props['auth']?['mhs'] ?? props['mhs'];
        if (mhs is Map) {
          final uuid = mhs['uuid'] ?? mhs['id'];
          if (uuid != null && uuid.toString().trim().isNotEmpty) {
            return uuid.toString().trim();
          }
        }
        final uuid = user['uuid'] ?? user['mahasiswa_uuid'];
        if (uuid != null && uuid.toString().trim().isNotEmpty) {
          return uuid.toString().trim();
        }
      }
      final directUuid = props['uuid'] ?? props['mahasiswa_uuid'];
      if (directUuid != null && directUuid.toString().trim().isNotEmpty) {
        return directUuid.toString().trim();
      }
    }
    return null;
  }

  /// Ekstraksi profil terstruktur ke dalam UserProfileModel (SoC & Type Safety)
  static UserProfileModel extractUserProfile(
    dynamic dashboardData,
    dynamic kelasData,
  ) {
    final raw = extractFullUserProfile(dashboardData, kelasData);
    final name = extractUserName(dashboardData, kelasData);
    final nim = extractUserNim(dashboardData, kelasData);

    return UserProfileModel(
      name: name,
      nim: nim,
      username: raw['username'] ?? (nim.isNotEmpty ? nim : '-'),
      email: raw['email'] ?? '-',
      prodi:
          raw['prodi'] ??
          raw['mhs_prodi'] ??
          raw['mhs_program_studi'] ??
          raw['jurusan'] ??
          raw['inferred_prodi'] ??
          '-',
      semester:
          raw['semester'] ??
          raw['mhs_semester'] ??
          raw['inferred_semester'] ??
          '-',
      kelas:
          raw['kelas'] ??
          raw['mhs_kelas'] ??
          raw['mhs_nama_kelas'] ??
          raw['inferred_kelas'] ??
          '-',
      angkatan:
          raw['angkatan'] ??
          raw['mhs_angkatan'] ??
          raw['mhs_tahun_masuk'] ??
          raw['inferred_angkatan'] ??
          '-',
      status: raw['mhs_status'] ?? raw['status'] ?? 'Aktif',
      rawProperties: raw,
    );
  }

  /// Ekstraksi seluruh field profil mentah untuk fleksibilitas
  static Map<String, dynamic> extractFullUserProfile(
    dynamic dashboardData,
    dynamic kelasData,
  ) {
    final Map<String, dynamic> profile = {};

    // 1. Ambil field langsung dari props auth / user
    for (final src in [dashboardData, kelasData]) {
      if (src is Map && src['props'] is Map) {
        final props = src['props'];
        final user =
            props['auth']?['user'] ??
            props['user'] ??
            props['mahasiswa'] ??
            props['profile'];
        if (user is Map) {
          for (final entry in user.entries) {
            if (entry.value != null &&
                entry.value is! Map &&
                entry.value is! List) {
              profile[entry.key.toString()] ??= entry.value.toString();
            }
          }
          final mhs =
              user['mahasiswa'] ??
              props['auth']?['mhs'] ??
              props['mhs'] ??
              props['mahasiswa'];
          if (mhs is Map) {
            for (final entry in mhs.entries) {
              if (entry.value != null &&
                  entry.value is! Map &&
                  entry.value is! List) {
                profile['mhs_${entry.key}'] ??= entry.value.toString();
              }
            }
          }
        }

        // Cek root level props
        for (final k in [
          'semester',
          'prodi',
          'jurusan',
          'angkatan',
          'tahun_akademik',
          'tahun_ajaran',
        ]) {
          if (props[k] != null && props[k] is! Map && props[k] is! List) {
            profile[k] ??= props[k].toString();
          }
        }
      }
    }

    // 2. Deteksi cerdas Program Studi, Semester, dan Kelas dari jadwal kelas
    final listKelas = KelasUtils.extractClassesList(kelasData);
    String detectedProdi = '';
    String detectedSemester = '';
    String detectedKelas = '';

    for (final k in listKelas) {
      if (k is Map) {
        final p = k['prodi'] ?? k['jurusan'] ?? k['program_studi'];
        if (p != null && p.toString().trim().isNotEmpty) {
          detectedProdi = p.toString().trim();
        }
        final s = k['semester'] ?? k['smt'];
        if (s != null && s.toString().trim().isNotEmpty) {
          detectedSemester = s.toString().trim();
        }
        final kl = k['kelas'] ?? k['nama_kelas_induk'] ?? k['rombel'];
        if (kl != null && kl.toString().trim().isNotEmpty) {
          detectedKelas = kl.toString().trim();
        }

        final namaKelas = (k['nama_kelas'] ?? '').toString().toLowerCase();

        // Deteksi Program Studi jika belum ada
        if (detectedProdi.isEmpty) {
          if (namaKelas.contains('trpl')) {
            detectedProdi = 'Teknologi Rekayasa Perangkat Lunak (TRPL)';
          } else if (namaKelas.contains('trkj')) {
            detectedProdi = 'Teknologi Rekayasa Komputer Jaringan (TRKJ)';
          } else if (namaKelas.contains('trmg')) {
            detectedProdi = 'Teknologi Rekayasa Multimedia Game (TRMG)';
          }
        }

        // Deteksi Semester jika belum ada
        if (detectedSemester.isEmpty) {
          final smtMatch = RegExp(
            r'(?:semester|smt|sem)\s*([0-9ivx]+)',
            caseSensitive: false,
          ).firstMatch(namaKelas);
          if (smtMatch != null) {
            detectedSemester = 'Semester ${smtMatch.group(1)}';
          }
        }
      }
    }

    if (detectedProdi.isNotEmpty &&
        profile['prodi'] == null &&
        profile['mhs_prodi'] == null) {
      profile['inferred_prodi'] = detectedProdi;
    }
    if (detectedSemester.isNotEmpty &&
        profile['semester'] == null &&
        profile['mhs_semester'] == null) {
      profile['inferred_semester'] = detectedSemester;
    }
    if (detectedKelas.isNotEmpty &&
        profile['kelas'] == null &&
        profile['mhs_kelas'] == null) {
      profile['inferred_kelas'] = detectedKelas;
    }

    // 3. Deteksi Angkatan dari NIM (Politeknik IDN: 2 digit awal = tahun masuk)
    final nim = extractUserNim(dashboardData, kelasData);
    if (nim.length >= 2 &&
        profile['angkatan'] == null &&
        profile['mhs_angkatan'] == null) {
      final prefix = nim.substring(0, 2);
      final yearNum = int.tryParse(prefix);
      if (yearNum != null && yearNum >= 20 && yearNum <= 35) {
        final fullYear = 2000 + yearNum;
        final angkatanKe = fullYear - 2021;
        profile['inferred_angkatan'] = '20$prefix (Angkatan $angkatanKe)';
      }
    }

    return profile;
  }

  /// Ekstraksi seluruh tugas dari berbagai kemungkinan payload
  static List<dynamic> extractAllTasks(
    dynamic tugasData, {
    dynamic dashboardData,
    dynamic kelasData,
  }) {
    final List<dynamic> rawCandidates = [];

    void extractFromSource(dynamic src) {
      if (src == null) return;

      if (src is List && src.isNotEmpty) {
        rawCandidates.addAll(src);
        return;
      }

      if (src is Map) {
        final Map root = (src['props'] is Map) ? src['props'] : src;

        const candidateKeys = [
          'all_tugas',
          'tugas_harian',
          'tugas',
          'tugases',
          'tugass',
          'tugas_list',
          'daftar_tugas',
          'tugas_harians',
          'assignments',
          'assignment',
          'tugas_aktif',
          'tugas_terdekat',
          'data',
        ];

        for (final key in candidateKeys) {
          final val = root[key];
          if (val is List && val.isNotEmpty) {
            rawCandidates.addAll(val);
            break;
          } else if (val is Map &&
              val['data'] is List &&
              (val['data'] as List).isNotEmpty) {
            rawCandidates.addAll(val['data']);
            break;
          }
        }

        // Cek jika tugas berada di dalam list kelas
        if (rawCandidates.isEmpty) {
          dynamic classes =
              root['kelas_harian'] ??
              root['kelases'] ??
              root['kelas']?['data'] ??
              root['kelas'];
          if (classes is Map && classes['data'] is List) {
            classes = classes['data'];
          }
          if (classes is List) {
            for (final c in classes) {
              if (c is Map) {
                final cTugas =
                    c['tugas'] ??
                    c['tugass'] ??
                    c['tugases'] ??
                    c['tugas_harian'] ??
                    c['daftar_tugas'];
                if (cTugas is List && cTugas.isNotEmpty) {
                  for (final t in cTugas) {
                    if (t is Map) {
                      final m = Map<String, dynamic>.from(t);
                      m['nama_kelas'] ??= c['nama_kelas'];
                      m['kode_kelas_harian'] ??= c['kode_kelas_harian'];
                      rawCandidates.add(m);
                    }
                  }
                } else if (cTugas is Map &&
                    cTugas['data'] is List &&
                    (cTugas['data'] as List).isNotEmpty) {
                  for (final t in cTugas['data']) {
                    if (t is Map) {
                      final m = Map<String, dynamic>.from(t);
                      m['nama_kelas'] ??= c['nama_kelas'];
                      m['kode_kelas_harian'] ??= c['kode_kelas_harian'];
                      rawCandidates.add(m);
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    // 1. Ekstrak dari tugasData (sumber utama)
    extractFromSource(tugasData);

    // 2. Fallback: coba ekstrak dari dashboardData jika belum ada
    if (rawCandidates.isEmpty && dashboardData != null) {
      extractFromSource(dashboardData);
    }

    // 3. Fallback: coba ekstrak dari kelasData jika belum ada
    if (rawCandidates.isEmpty && kelasData != null) {
      extractFromSource(kelasData);
    }

    // Flatten & normalisasi item
    final List<dynamic> finalResult = [];
    final Set<String> seenIds = {};

    for (final item in rawCandidates) {
      if (item is! Map) continue;

      if (item['tugas'] is List && (item['tugas'] as List).isNotEmpty) {
        for (final t in item['tugas']) {
          if (t is Map) {
            final m = Map<String, dynamic>.from(t);
            m['nama_kelas'] ??= item['nama_kelas'];
            m['kode_kelas_harian'] ??= item['kode_kelas_harian'];
            _addNormalizedTask(m, finalResult, seenIds);
          }
        }
      } else if (item['tugass'] is List &&
          (item['tugass'] as List).isNotEmpty) {
        for (final t in item['tugass']) {
          if (t is Map) {
            final m = Map<String, dynamic>.from(t);
            m['nama_kelas'] ??= item['nama_kelas'];
            m['kode_kelas_harian'] ??= item['kode_kelas_harian'];
            _addNormalizedTask(m, finalResult, seenIds);
          }
        }
      } else if (item['tugases'] is List &&
          (item['tugases'] as List).isNotEmpty) {
        for (final t in item['tugases']) {
          if (t is Map) {
            final m = Map<String, dynamic>.from(t);
            m['nama_kelas'] ??= item['nama_kelas'];
            m['kode_kelas_harian'] ??= item['kode_kelas_harian'];
            _addNormalizedTask(m, finalResult, seenIds);
          }
        }
      } else {
        final m = Map<String, dynamic>.from(item);
        _addNormalizedTask(m, finalResult, seenIds);
      }
    }

    sortTasksByNewest(finalResult);

    return finalResult;
  }

  /// Mengurutkan daftar tugas agar tugas paling baru berada di paling atas
  static void sortTasksByNewest(List<dynamic> tasks) {
    tasks.sort((a, b) {
      if (a is! Map || b is! Map) return 0;

      DateTime? parseDateTime(dynamic val) {
        if (val == null) return null;
        final str = val.toString().trim();
        if (str.isEmpty) return null;
        return DateTime.tryParse(str);
      }

      // 1. Bandingkan tanggal pembuatan / tanggal mulai diberikan
      final rawDateA =
          a['created_at'] ??
          a['tanggal_mulai'] ??
          a['tgl_mulai'] ??
          a['updated_at'];
      final rawDateB =
          b['created_at'] ??
          b['tanggal_mulai'] ??
          b['tgl_mulai'] ??
          b['updated_at'];

      final dtA = parseDateTime(rawDateA);
      final dtB = parseDateTime(rawDateB);

      if (dtA != null && dtB != null && !dtA.isAtSameMomentAs(dtB)) {
        return dtB.compareTo(dtA); // Descending (terbaru di paling atas)
      }

      // 2. Bandingkan ID tugas (auto-increment di database)
      int? parseId(dynamic val) {
        if (val == null) return null;
        if (val is int) return val;
        final match = RegExp(r'\d+').firstMatch(val.toString());
        if (match != null) {
          return int.tryParse(match.group(0)!);
        }
        return null;
      }

      final idA = parseId(a['id'] ?? a['tugas_harian_id']);
      final idB = parseId(b['id'] ?? b['tugas_harian_id']);

      if (idA != null && idB != null && idA != idB) {
        return idB.compareTo(idA); // Descending
      }

      // 3. Fallback: bandingkan deadline
      final deadA = parseDateTime(findDeadline(a));
      final deadB = parseDateTime(findDeadline(b));
      if (deadA != null && deadB != null && !deadA.isAtSameMomentAs(deadB)) {
        return deadB.compareTo(deadA);
      }

      return 0;
    });
  }

  static void _addNormalizedTask(
    Map<String, dynamic> m,
    List<dynamic> result,
    Set<String> seen,
  ) {
    final rawJudul =
        m['judul'] ?? m['nama_tugas'] ?? m['title'] ?? m['name'] ?? 'Tugas';
    m['judul'] = rawJudul.toString().replaceAll(RegExp(r'<[^>]*>'), '').trim();

    if (m['deskripsi'] != null) {
      m['deskripsi'] = m['deskripsi']
          .toString()
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();
    }

    m['nama_kelas'] =
        m['nama_kelas'] ??
        (m['kelas'] is Map
            ? m['kelas']['nama_kelas'] ?? m['kelas']['nama']
            : m['kelas']) ??
        m['mata_kuliah'] ??
        m['matkul'] ??
        '';

    m['kode_kelas_harian'] =
        m['kode_kelas_harian'] ??
        m['kode_kelas'] ??
        (m['kelas'] is Map ? m['kelas']['kode_kelas_harian'] : null) ??
        '';

    final deadline = findDeadline(m);
    if (deadline != null && deadline.isNotEmpty) {
      m['deadline'] = deadline;
    }

    final dynamic rawSubmissions =
        m['pengumpulan_tugas_harians'] ??
        m['pengumpulan_tugas'] ??
        m['pengumpulan'] ??
        m['submissions'] ??
        m['submission'];
    final bool hasSubmissions =
        (rawSubmissions is List && rawSubmissions.isNotEmpty) ||
        (rawSubmissions is Map && rawSubmissions.isNotEmpty);

    if (hasSubmissions) {
      m['status'] = 'Terkirim';
    } else if (m['status'] == null || m['status'].toString().trim().isEmpty) {
      m['status'] = 'Pending';
    }

    final key =
        (m['id'] ?? '${m['judul']}_${m['kode_kelas_harian']}_${m['deadline']}')
            .toString();
    if (!seen.contains(key)) {
      seen.add(key);
      result.add(m);
    }
  }

  /// Mengecek apakah suatu tugas sudah selesai dikerjakan (Didelegasikan ke DashboardHelpers - DRY)
  static bool isTaskCompleted(dynamic task) =>
      DashboardHelpers.isTaskCompleted(task);

  /// Memfilter hanya tugas-tugas yang belum selesai (pending)
  static List<dynamic> filterPendingTasks(List<dynamic> tasks) {
    return tasks.where((t) => !isTaskCompleted(t)).toList();
  }

  /// Menghitung rasio sisa waktu deadline tugas (0.05 s/d 1.0)
  static double calculateRemainingRatio(dynamic deadlineVal) {
    if (deadlineVal == null) return 0.5;
    final str = deadlineVal.toString().trim().toLowerCase();
    if (str.isEmpty) return 0.5;

    // 1. Parse format DateTime standar (ISO / YYYY-MM-DD)
    final dt = DateTime.tryParse(deadlineVal.toString());
    if (dt != null) {
      final diff = dt.difference(DateTime.now());
      if (diff.isNegative) return 0.05; // Lewat deadline
      final totalMinutes = diff.inMinutes;
      const maxWindowMinutes = 5 * 24 * 60; // 5 hari
      return (totalMinutes / maxWindowMinutes).clamp(0.08, 1.0);
    }

    // 2. Deteksi teks waktu relatif
    if (str.contains('menit')) {
      return 0.08;
    }
    if (str.contains('jam')) {
      final match = RegExp(r'(\d+)').firstMatch(str);
      final hours = match != null ? int.tryParse(match.group(1)!) ?? 2 : 2;
      return (hours / 24).clamp(0.12, 0.40);
    }
    if (str.contains('hari ini')) {
      return 0.25;
    }
    if (str.contains('besok')) {
      return 0.55;
    }
    if (str.contains('hari')) {
      final match = RegExp(r'(\d+)').firstMatch(str);
      final days = match != null ? int.tryParse(match.group(1)!) ?? 3 : 3;
      return (days / 5).clamp(0.40, 1.0);
    }
    if (str.contains('minggu') || str.contains('bulan')) {
      return 1.0;
    }

    return 0.5;
  }

  /// Ekstraksi deadline dari berbagai kemungkinan key
  static String? findDeadline(Map itemMap) {
    const keys = [
      'deadline',
      'tanggal_selesai',
      'due_date',
      'batas_waktu',
      'batas_pengumpulan',
      'tanggal_deadline',
      'tgl_selesai',
      'tgl_deadline',
      'waktu_selesai',
      'waktu_deadline',
      'waktu_tutup',
      'end_date',
      'end_at',
      'due_at',
      'expired_at',
      'sampai',
      'tgl_tutup',
    ];
    for (final k in keys) {
      final val = itemMap[k];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    if (itemMap['tugas'] is Map) {
      return findDeadline(itemMap['tugas'] as Map);
    }
    if (itemMap['assignment'] is Map) {
      return findDeadline(itemMap['assignment'] as Map);
    }
    return null;
  }
}
