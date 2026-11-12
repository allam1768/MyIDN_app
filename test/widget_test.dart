import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/src/constants/lms_endpoints.dart';

void main() {
  test('App Endpoints Configuration smoke test', () {
    expect(LmsEndpoints.baseUrl, 'https://lms.politeknikidn.id');
    expect(
      LmsEndpoints.submitTugasHarian,
      '/my/mhs/harian/tugas_harian/sendTugas',
    );
    expect(LmsEndpoints.kelasMatkul, '/my/mhs/kelas');
    expect(LmsEndpoints.materiMatkul, '/my/mhs/materi');
    expect(
      LmsEndpoints.detailMateriMatkul('IDN207'),
      '/my/mhs/materi/class/IDN207/materi',
    );
    expect(LmsEndpoints.tugasMatkul, '/my/mhs/tugas');
    expect(
      LmsEndpoints.detailTugasMatkul('IDN207'),
      '/my/mhs/tugas/class/IDN207/tugas',
    );
    expect(LmsEndpoints.absensiMatkul, '/my/mhs/absensi');
    expect(
      LmsEndpoints.detailAbsensiMatkul('IDN207'),
      '/my/mhs/absensi/class/IDN207/presence',
    );
    expect(
      LmsEndpoints.submitPresensiMatkul,
      '/my/mhs/absensi/doPresence',
    );
  });
}
