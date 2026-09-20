import 'package:flutter_test/flutter_test.dart';
import 'package:reminder/src/constants/lms_endpoints.dart';
import 'package:reminder/src/features/dashboard/presentation/dashboard_utils.dart';
import 'package:reminder/src/features/tugas/presentation/tugas_providers.dart';
import 'package:reminder/src/services/lms_api_service.dart';

class MockLmsApiService extends LmsApiService {
  bool submitCalled = false;
  Map<String, dynamic>? lastPayload;
  bool shouldSucceed = true;
  int statusCode = 200;
  Map<String, dynamic>? responseData;

  @override
  Future<Map<String, dynamic>> submitTugasHarian({
    required dynamic tugasHarianId,
    required String kodeKelasHarian,
    required String linkTugas,
    String? kendala,
  }) async {
    submitCalled = true;
    lastPayload = {
      'tugas_harian_id': tugasHarianId,
      'kode_kelas_harian': kodeKelasHarian,
      'link_tugas': linkTugas,
      'kendala': kendala,
    };
    return {
      'statusCode': statusCode,
      'isSuccess': shouldSucceed,
      'data': responseData ?? {'message': shouldSucceed ? 'OK' : 'Error'},
    };
  }
}

void main() {
  group('Tugas Harian Submission Tests', () {
    test('LmsEndpoints has correct submitTugasHarian endpoint', () {
      expect(
        LmsEndpoints.submitTugasHarian,
        '/my/mhs/harian/tugas_harian/sendTugas',
      );
    });

    test('TugasSubmitController submits successfully', () async {
      final mockApi = MockLmsApiService()..shouldSucceed = true;
      final controller = TugasSubmitController(mockApi);

      expect(controller.state.isSubmitting, false);

      final result = await controller.submit(
        tugasHarianId: 123,
        kodeKelasHarian: 'KH159',
        linkTugas: 'https://github.com/example/repo',
        kendala: 'Tidak ada kendala',
      );

      expect(result, true);
      expect(mockApi.submitCalled, true);
      expect(mockApi.lastPayload?['tugas_harian_id'], 123);
      expect(mockApi.lastPayload?['kode_kelas_harian'], 'KH159');
      expect(
        mockApi.lastPayload?['link_tugas'],
        'https://github.com/example/repo',
      );
      expect(mockApi.lastPayload?['kendala'], 'Tidak ada kendala');
      expect(controller.state.isSubmitting, false);
      expect(controller.state.isSuccess, true);
      expect(controller.state.errorMessage, isNull);
    });

    test('TugasSubmitController handles submission error gracefully', () async {
      final mockApi = MockLmsApiService()
        ..shouldSucceed = false
        ..statusCode = 422
        ..responseData = {
          'props': {
            'errors': {'link_tugas': 'Link tugas tidak valid'},
          },
        };
      final controller = TugasSubmitController(mockApi);

      final result = await controller.submit(
        tugasHarianId: 123,
        kodeKelasHarian: 'KH159',
        linkTugas: 'invalid-url',
      );

      expect(result, false);
      expect(controller.state.isSubmitting, false);
      expect(controller.state.isSuccess, false);
      expect(controller.state.errorMessage, 'Link tugas tidak valid');
    });

    test('DashboardUtils.sortTasksByNewest sorts newest tasks first', () {
      final tasks = [
        {'id': 10, 'judul': 'Tugas Lama', 'created_at': '2026-09-01 08:00:00'},
        {'id': 25, 'judul': 'Tugas Baru', 'created_at': '2026-09-14 10:00:00'},
        {
          'id': 15,
          'judul': 'Tugas Sedang',
          'created_at': '2026-09-10 12:00:00',
        },
      ];

      // Panggil sort
      DashboardUtils.sortTasksByNewest(tasks);

      expect(tasks[0]['judul'], 'Tugas Baru');
      expect(tasks[1]['judul'], 'Tugas Sedang');
      expect(tasks[2]['judul'], 'Tugas Lama');
    });

    test(
      'DashboardUtils.sortTasksByNewest falls back to ID if date missing',
      () {
        final tasks = [
          {'id': 101, 'judul': 'Tugas ID 101'},
          {'id': 205, 'judul': 'Tugas ID 205'},
          {'id': 150, 'judul': 'Tugas ID 150'},
        ];

        DashboardUtils.sortTasksByNewest(tasks);

        expect(tasks[0]['id'], 205);
        expect(tasks[1]['id'], 150);
        expect(tasks[2]['id'], 101);
      },
    );

    test(
      'DashboardUtils.isTaskCompleted detects submitted or done tasks correctly',
      () {
        final pendingTask = {'id': 1, 'status': 'Pending'};
        final doneTask1 = {'id': 2, 'status': 'Terkirim'};
        final doneTask2 = {'id': 3, 'status': 'Selesai'};
        final submittedTask = {
          'id': 4,
          'status': 'Pending',
          'pengumpulan_tugas_harians': [
            {'id': 10, 'link_tugas': 'https://github.com/repo'},
          ],
        };

        expect(DashboardUtils.isTaskCompleted(pendingTask), false);
        expect(DashboardUtils.isTaskCompleted(doneTask1), true);
        expect(DashboardUtils.isTaskCompleted(doneTask2), true);
        expect(DashboardUtils.isTaskCompleted(submittedTask), true);
      },
    );

    test(
      'DashboardUtils.filterPendingTasks filters out completed tasks for Dashboard',
      () {
        final allTasks = [
          {'id': 1, 'judul': 'Tugas Pending 1', 'status': 'Pending'},
          {'id': 2, 'judul': 'Tugas Selesai', 'status': 'Terkirim'},
          {
            'id': 3,
            'judul': 'Tugas Sudah Dikumpul',
            'status': 'Pending',
            'pengumpulan_tugas_harians': [
              {'id': 101},
            ],
          },
          {'id': 4, 'judul': 'Tugas Pending 2', 'status': ''},
        ];

        final pendingOnly = DashboardUtils.filterPendingTasks(allTasks);

        expect(pendingOnly.length, 2);
        expect(pendingOnly.map((t) => t['id']).toList(), [1, 4]);
      },
    );
  });
}
