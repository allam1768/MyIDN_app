import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/src/constants/lms_endpoints.dart';

void main() {
  test('App Endpoints Configuration smoke test', () {
    expect(LmsEndpoints.baseUrl, 'https://lms.politeknikidn.id');
    expect(
      LmsEndpoints.submitTugasHarian,
      '/my/mhs/harian/tugas_harian/sendTugas',
    );
  });
}
