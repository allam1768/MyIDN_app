import 'dart:convert';
import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/lms_endpoints.dart';

class LmsApiService {
  static String get baseUrl => LmsEndpoints.baseUrl;

  // Standard User-Agent Chrome Mobile (Android)
  static const String customUserAgent =
      'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  late final Dio _dio;
  late CookieJar _cookieJar;
  bool _isInitialized = false;
  String? _inertiaVersion;

  LmsApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: LmsEndpoints.baseUrl,
        followRedirects: false,
        validateStatus: (status) => status != null && status < 500,
        headers: {
          'User-Agent': customUserAgent,
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ),
    );

    // Bypass SSL handshake error khusus domain LMS Politeknik IDN / Mode Debug
    if (_dio.httpClientAdapter is IOHttpClientAdapter) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) =>
                host.contains('politeknikidn.id') || kDebugMode;
        return client;
      };
    }
  }

  /// Inisialisasi CookieJar Permanen (Disimpan di storage HP)
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final cookiePath = "${appDocDir.path}/.cookies/";
      _cookieJar = PersistCookieJar(storage: FileStorage(cookiePath));
    } catch (_) {
      _cookieJar = CookieJar();
    }
    _dio.interceptors.add(CookieManager(_cookieJar));
    _isInitialized = true;
  }

  /// Memeriksa apakah user sudah punya cookie sesi aktif
  Future<bool> hasActiveSession() async {
    await init();
    final cookies = await _cookieJar.loadForRequest(Uri.parse(baseUrl));
    for (final c in cookies) {
      if ((c.name.contains('session') ||
              c.name == 'laravel_session' ||
              c.name == 'lms_politeknik_idn_session') &&
          c.value.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  /// Logout resmi ke server LMS agar sesi di backend di-terminate
  Future<void> logout() async {
    await init();
    try {
      final headers = await _getAuthorizedInertiaHeaders();

      await _dio.post(
        LmsEndpoints.logout,
        data: {},
        options: Options(
          headers: headers,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
    } catch (e) {
      debugPrint('Logout server error: $e');
    } finally {
      // Selalu bersihkan cookie lokal & reset state
      await clearSession();
    }
  }

  /// Reset cookies / logout lokal
  Future<void> clearSession() async {
    await init();
    await _cookieJar.deleteAll();
    _inertiaVersion = null;
  }

  /// Memeriksa apakah sesi masih valid dan aktif di server LMS
  Future<bool> validateSessionWithServer() async {
    await init();
    if (!await hasActiveSession()) return false;

    try {
      final response = await _dio.get(
        LmsEndpoints.dashboard,
        options: Options(
          headers: _getInertiaHeaders(),
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // Jika server me-redirect ke login (302) atau status 401/419
      if (response.statusCode == 302) {
        final loc = response.headers.value('location') ?? '';
        if (loc.contains('signin') || loc.contains('login')) {
          await clearSession();
          return false;
        }
      }

      if (response.statusCode == 401 || response.statusCode == 419) {
        await clearSession();
        return false;
      }

      if (response.statusCode == 200) {
        final body = response.data.toString();
        // Bila server mengembalikan form signin padahal status 200
        if (body.contains('name="username"') &&
            body.contains('name="password"')) {
          await clearSession();
          return false;
        }
        return true;
      }
    } catch (_) {
      // Jika terjadi error koneksi saat validasi, tetap anggap ada sesi agar tidak ter-logout saat offline fluktuatif
      return true;
    }
    return false;
  }

  /// Ambil CSRF Cookie & Token dari /signin
  Future<String?> _fetchCsrfToken() async {
    await init();
    final response = await _dio.get(LmsEndpoints.login);

    // Extract Inertia version dari HTML response jika ada
    final bodyStr = response.data.toString();
    final versionMatch =
        RegExp(
          r'&quot;version&quot;:&quot;([^&]+)&quot;',
        ).firstMatch(bodyStr) ??
        RegExp(r'"version":"([^"]+)"').firstMatch(bodyStr);
    if (versionMatch != null) {
      _inertiaVersion = versionMatch.group(1);
    }

    // Ambil XSRF-TOKEN cookie yang tersimpan di CookieJar
    final cookies = await _cookieJar.loadForRequest(Uri.parse(baseUrl));
    for (final c in cookies) {
      if (c.name == 'XSRF-TOKEN') {
        return Uri.decodeComponent(c.value);
      }
    }
    return null;
  }

  /// Login Mahasiswa ke LMS
  Future<bool> login(String nim, String password) async {
    await init();

    // Hancurkan sesi lama di server BE jika masih ada, agar tidak meninggalkan sesi duplikat
    if (await hasActiveSession()) {
      try {
        await logout();
      } catch (_) {}
    }

    // Bersihkan sesi lokal lama sebelum fresh login agar server mencatat sesi & User-Agent baru
    await _cookieJar.deleteAll();

    // Step 1: Ambil CSRF Cookie & Token dari /signin
    final csrfToken = await _fetchCsrfToken();

    final Map<String, dynamic> headers = {'X-Requested-With': 'XMLHttpRequest'};
    if (csrfToken != null) {
      headers['X-XSRF-TOKEN'] = csrfToken;
    }
    if (_inertiaVersion != null) {
      headers['X-Inertia-Version'] = _inertiaVersion!;
    }

    final postData = {'email': nim, 'username': nim, 'password': password};

    // Step 2: POST credentials menggunakan form-url-encoded sesuai form Laravel
    final postRes = await _dio.post(
      LmsEndpoints.login,
      data: postData,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
        headers: headers,
      ),
    );

    // Status 302: Redirect dari Laravel (ke dashboard)
    if (postRes.statusCode == 302) {
      final location = postRes.headers.value('location') ?? '';
      if (location.contains('dashboard') ||
          (!location.endsWith('/signin') && !location.contains('/signin?'))) {
        return true;
      }
      return false;
    }

    if (postRes.statusCode == 200) {
      final body = postRes.data.toString();
      if (body.contains('dashboard') && !body.contains('name="username"')) {
        return true;
      }
      if (postRes.data is Map) {
        return true;
      }
    }

    return false;
  }

  Map<String, String> _getInertiaHeaders() {
    final headers = {
      'X-Requested-With': 'XMLHttpRequest',
      'X-Inertia': 'true',
      'Accept': 'application/json, text/plain, */*',
    };
    if (_inertiaVersion != null) {
      headers['X-Inertia-Version'] = _inertiaVersion!;
    }
    return headers;
  }

  /// Header Inertia yang sudah dilengkapi token CSRF dari cookie sesi aktif
  Future<Map<String, String>> _getAuthorizedInertiaHeaders() async {
    final headers = _getInertiaHeaders();
    final cookies = await _cookieJar.loadForRequest(Uri.parse(baseUrl));
    for (final c in cookies) {
      if (c.name == 'XSRF-TOKEN') {
        headers['X-XSRF-TOKEN'] = Uri.decodeComponent(c.value);
        break;
      }
    }
    return headers;
  }

  String _unescapeHtml(String input) {
    return input
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  dynamic _extractInertiaData(dynamic rawData) {
    if (rawData is Map) {
      if (rawData['version'] != null) {
        _inertiaVersion = rawData['version'].toString();
      }
      return rawData;
    }
    if (rawData is String) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map && decoded['version'] != null) {
          _inertiaVersion = decoded['version'].toString();
        }
        return decoded;
      } catch (_) {}

      final match = RegExp(r'data-page="([^"]+)"').firstMatch(rawData);
      if (match != null) {
        try {
          final unescaped = _unescapeHtml(match.group(1)!);
          final decoded = jsonDecode(unescaped);
          if (decoded is Map && decoded['version'] != null) {
            _inertiaVersion = decoded['version'].toString();
          }
          return decoded;
        } catch (_) {}
      }
    }
    return rawData;
  }

  Future<dynamic> _safeInertiaGet(String path, String label) async {
    await init();
    final response = await _dio.get(
      path,
      options: Options(
        headers: _getInertiaHeaders(),
        followRedirects: true,
        maxRedirects: 5,
      ),
    );

    if (response.statusCode == 409) {
      final htmlRes = await _dio.get(
        path,
        options: Options(followRedirects: true, maxRedirects: 5),
      );
      return _extractInertiaData(htmlRes.data);
    }

    return _extractInertiaData(response.data);
  }

  /// Mengambil data Kelas Harian Mahasiswa
  Future<dynamic> getKelasHarian() =>
      _safeInertiaGet(LmsEndpoints.kelasHarian, 'KELAS HARIAN');

  /// Mengambil data Tugas Harian Mahasiswa
  Future<dynamic> getTugasHarian() =>
      _safeInertiaGet(LmsEndpoints.tugasHarian, 'TUGAS HARIAN');

  /// Mengambil data Absensi Harian Mahasiswa
  Future<dynamic> getAbsensiHarian() =>
      _safeInertiaGet(LmsEndpoints.absensiHarian, 'ABSENSI HARIAN');

  /// Mengambil data Materi Harian Mahasiswa
  Future<dynamic> getMateriHarian() =>
      _safeInertiaGet(LmsEndpoints.materiHarian, 'MATERI HARIAN');

  /// Mengambil detail materi dari kelas tertentu (misal: KH159)
  Future<dynamic> getDetailMateriHarian(String kodeKelasHarian) =>
      _safeInertiaGet(
        LmsEndpoints.detailMateri(kodeKelasHarian),
        'DETAIL MATERI ($kodeKelasHarian)',
      );

  /// Mengambil detail tugas dari kelas tertentu (misal: KH159)
  Future<dynamic> getDetailTugasHarian(String kodeKelasHarian) =>
      _safeInertiaGet(
        LmsEndpoints.detailTugas(kodeKelasHarian),
        'DETAIL TUGAS ($kodeKelasHarian)',
      );

  /// Mengirim / mengumpulkan tugas harian mahasiswa
  Future<Map<String, dynamic>> submitTugasHarian({
    required dynamic tugasHarianId,
    required String kodeKelasHarian,
    required String linkTugas,
    String? kendala,
  }) async {
    await init();
    final headers = await _getAuthorizedInertiaHeaders();

    final postData = {
      'tugas_harian_id': tugasHarianId,
      'kode_kelas_harian': kodeKelasHarian,
      'link_tugas': linkTugas,
      'kendala': kendala ?? '',
    };

    final response = await _dio.post(
      LmsEndpoints.submitTugasHarian,
      data: postData,
      options: Options(headers: headers, followRedirects: true),
    );

    return {
      'statusCode': response.statusCode,
      'data': response.data,
      'isSuccess':
          response.statusCode == 200 ||
          response.statusCode == 302 ||
          response.statusCode == 303,
    };
  }

  /// Mengambil data Laporan Ibadah Harian Mahasiswa
  Future<dynamic> getLaporanIbadahHarian() => _safeInertiaGet(
    LmsEndpoints.laporanIbadahHarian,
    'LAPORAN IBADAH HARIAN',
  );

  /// Mengambil data form pertanyaan laporan ibadah
  Future<dynamic> getFormIbadahHarian({String? tanggal}) {
    final query = tanggal != null ? '?tanggal=$tanggal' : '';
    return _safeInertiaGet(
      '${LmsEndpoints.laporanIbadahHarian}/new$query',
      'FORM IBADAH',
    );
  }

  /// Mengirim laporan ibadah harian
  Future<Map<String, dynamic>> submitLaporanIbadahHarian({
    required String tanggalLaporan,
    required bool isHaid,
    required Map<String, dynamic> answers,
  }) async {
    await init();
    final headers = await _getAuthorizedInertiaHeaders();

    final postData = {
      'tanggal_laporan': tanggalLaporan,
      'is_haid': isHaid,
      'answers': answers,
    };

    final response = await _dio.post(
      LmsEndpoints.laporanIbadahHarian,
      data: postData,
      options: Options(headers: headers, followRedirects: true),
    );

    return {
      'statusCode': response.statusCode,
      'data': response.data,
      'isSuccess':
          response.statusCode == 200 ||
          response.statusCode == 302 ||
          response.statusCode == 303,
    };
  }

  /// Mengambil data Dashboard Mahasiswa (Jadwal Hari Ini, Users Online, dll)
  Future<dynamic> getDashboardMahasiswa() =>
      _safeInertiaGet(LmsEndpoints.dashboard, 'DASHBOARD MAHASISWA');

  /// Mengambil daftar jadwal absensi bulanan untuk kelas tertentu
  Future<dynamic> getListJadwalAbsensi(
    String kodeKelasHarian, {
    String? monthParam,
  }) {
    String month = monthParam ?? '';
    if (month.isEmpty) {
      final now = DateTime.now();
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      final mName = months[now.month - 1];
      month = '${now.year}-$mName';
    }
    return _safeInertiaGet(
      LmsEndpoints.listJadwalAbsensi(kodeKelasHarian, month),
      'LIST JADWAL ABSENSI ($kodeKelasHarian)',
    );
  }

  /// Melakukan presensi absensi dengan kode presensi (kode_unik) dan jadwal_id
  Future<Map<String, dynamic>> submitPresensi({
    required String kodeUnik,
    required int jadwalId,
  }) async {
    await init();
    final headers = await _getAuthorizedInertiaHeaders();

    final postData = {'kode_unik': kodeUnik, 'jadwal_id': jadwalId};

    final response = await _dio.post(
      LmsEndpoints.submitPresensi,
      data: postData,
      options: Options(headers: headers, followRedirects: true),
    );

    return {
      'statusCode': response.statusCode,
      'data': response.data,
      'isSuccess':
          response.statusCode == 200 ||
          response.statusCode == 302 ||
          response.statusCode == 303,
    };
  }

  /// Ambil info status sesi (headers & token aman)
  Future<Map<String, String>> getDebugSessionInfo() async {
    await init();
    final cookies = await _cookieJar.loadForRequest(Uri.parse(baseUrl));
    String xsrfToken = '-';
    String sessionCookie = '-';
    for (final c in cookies) {
      if (c.name == 'XSRF-TOKEN') xsrfToken = Uri.decodeComponent(c.value);
      if (c.name == 'laravel_session' || c.name.contains('session')) {
        sessionCookie = c.value;
      }
    }

    final headers = _getInertiaHeaders();

    final debugInfo = {
      'XSRF-TOKEN': xsrfToken,
      'laravel_session (Cookie)': sessionCookie,
      'X-Requested-With': headers['X-Requested-With'] ?? '-',
      'X-Inertia': headers['X-Inertia'] ?? '-',
      'Accept': headers['Accept'] ?? '-',
      'X-Inertia-Version': headers['X-Inertia-Version'] ?? 'Default / Active',
    };
    return debugInfo;
  }

  /// Mengambil data laporan SKL (Standar Kompetensi Lulusan) mahasiswa berdasarkan UUID
  Future<dynamic> getLaporanSkl(String mahasiswaUuid) async {
    await init();
    final cleanUuid = mahasiswaUuid.trim();
    final endpoint = LmsEndpoints.laporanSkl(cleanUuid);

    // 1. Coba request via Inertia JSON terlebih dahulu
    try {
      final headers = await _getAuthorizedInertiaHeaders();
      final response = await _dio.get(
        endpoint,
        options: Options(headers: headers, responseType: ResponseType.plain),
      );
      if (response.data != null) {
        return _extractInertiaData(response.data);
      }
    } catch (e) {
      debugPrint('[LmsApiService] Inertia getLaporanSkl fallback ke HTML: $e');
    }

    // 2. Fallback: Ambil via GET standar (Blade HTML report)
    final stdHeaders = await _getAuthorizedInertiaHeaders();
    stdHeaders.remove('X-Inertia');
    stdHeaders['Accept'] =
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';

    final htmlResponse = await _dio.get(
      endpoint,
      options: Options(headers: stdHeaders, responseType: ResponseType.plain),
    );
    return htmlResponse.data;
  }

  /// Mengambil rincian detail submisi SKL mahasiswa
  Future<dynamic> getDetailSklMahasiswa(String mahasiswaUuid) async {
    await init();
    final endpoint = LmsEndpoints.detailSklMahasiswa(mahasiswaUuid.trim());
    final headers = await _getAuthorizedInertiaHeaders();
    final response = await _dio.get(
      endpoint,
      options: Options(headers: headers),
    );
    return _extractInertiaData(response.data);
  }
}

final lmsApiServiceProvider = Provider<LmsApiService>((ref) {
  return LmsApiService();
});
