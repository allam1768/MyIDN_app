import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../common_widgets/async_value_widget.dart';
import '../../../common_widgets/kelas_header_card.dart';
import '../../../constants/lms_endpoints.dart';
import '../../dashboard/presentation/dashboard_providers.dart';
import '../../dashboard/presentation/dashboard_utils.dart';
import 'tugas_providers.dart';

class DetailTugasPage extends ConsumerWidget {
  final String kodeKelasHarian;
  final String namaKelas;

  const DetailTugasPage({
    super.key,
    required this.kodeKelasHarian,
    required this.namaKelas,
  });

  Future<void> _openFileUrl(BuildContext context, String urlString) async {
    final Uri? uri = Uri.tryParse(urlString);
    if (uri != null) {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tidak dapat membuka link: $urlString')),
          );
        }
      }
    }
  }

  String _cleanHtmlTags(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  List<String> _extractUrlsFromItem(dynamic item, String rawDesc) {
    final List<String> extractedUrls = [];

    if (item is Map) {
      final candidateKeys = [
        'file',
        'link_tugas',
        'url',
        'link',
        'file_url',
        'file_path',
        'path',
        'attachment',
        'pengumpulan_file',
        'link_pengumpulan',
      ];

      for (final key in candidateKeys) {
        final val = item[key];
        if (val != null && val.toString().trim().isNotEmpty) {
          String u = val.toString().trim();
          if (u.startsWith('/')) u = '${LmsEndpoints.baseUrl}$u';
          if (!extractedUrls.contains(u)) {
            extractedUrls.add(u);
          }
        }
      }
    }

    final hrefMatches = RegExp(
      '(?:href|src)=["\']([^"\']+)["\']',
      caseSensitive: false,
    ).allMatches(rawDesc);
    for (final m in hrefMatches) {
      String? u = m.group(1);
      if (u != null &&
          u.isNotEmpty &&
          !u.startsWith('#') &&
          !u.startsWith('javascript:')) {
        if (u.startsWith('/')) u = '${LmsEndpoints.baseUrl}$u';
        if (!extractedUrls.contains(u)) {
          extractedUrls.add(u);
        }
      }
    }

    final plainUrlMatches = RegExp(r'https?://[^\s<"]+').allMatches(rawDesc);
    for (final m in plainUrlMatches) {
      final u = m.group(0);
      if (u != null && !extractedUrls.contains(u)) {
        extractedUrls.add(u);
      }
    }

    return extractedUrls;
  }

  String? _extractDeadline(Map itemMap) {
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
      return _extractDeadline(itemMap['tugas'] as Map);
    }
    if (itemMap['assignment'] is Map) {
      return _extractDeadline(itemMap['assignment'] as Map);
    }
    return null;
  }

  void _showSubmitModal({
    required BuildContext context,
    required dynamic taskId,
    required String judul,
    String? initialLink,
    String? initialKendala,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmitTugasBottomSheet(
        taskId: taskId,
        kodeKelasHarian: kodeKelasHarian,
        judul: judul,
        initialLink: initialLink,
        initialKendala: initialKendala,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tugasAsync = ref.watch(detailTugasProvider(kodeKelasHarian));

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text('Tugas - $namaKelas')),
      body: AsyncValueWidget<dynamic>(
        value: tugasAsync,
        onRetry: () => ref.invalidate(detailTugasProvider(kodeKelasHarian)),
        data: (detailData) {
          List<dynamic> tugasList = [];
          String semester = '-';
          String tahun = '-';

          if (detailData is Map && detailData['props'] is Map) {
            final props = detailData['props'];
            if (props['kelas'] is Map) {
              final k = props['kelas'];
              tahun = k['tahun']?.toString() ?? tahun;
              semester = k['semester']?.toString() ?? semester;
            }
            if (props['filters'] is Map) {
              tahun = props['filters']['tahun']?.toString() ?? tahun;
              semester = props['filters']['semester']?.toString() ?? semester;
            }

            final rawTugas =
                props['tugas'] ??
                props['tugass'] ??
                props['tugas_harian'] ??
                props['tugas_harians'] ??
                props['daftar_tugas'] ??
                props['data'];

            if (rawTugas is List) {
              tugasList = List.from(rawTugas);
            } else if (rawTugas is Map && rawTugas['data'] is List) {
              tugasList = List.from(rawTugas['data']);
            }

            // Urutkan tugas terbaru di posisi paling atas
            DashboardUtils.sortTasksByNewest(tugasList);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(detailTugasProvider(kodeKelasHarian));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KelasHeaderCard(
                    namaKelas: namaKelas,
                    kodeKelasHarian: kodeKelasHarian,
                    subtitle: 'Tahun: $tahun | Sem: $semester',
                    primaryColor: const Color(0xFF1F81FF),
                    icon: Icons.assignment_rounded,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '📝 Daftar Tugas (${tugasList.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (tugasList.isEmpty)
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.task_alt_rounded,
                                size: 48,
                                color: Colors.green,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Belum ada tugas untuk kelas ini.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Semua tugas telah selesai atau belum ditambahkan oleh dosen.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tugasList.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = tugasList[index];
                        final Map itemMap = (item is Map) ? item : {};
                        final taskId =
                            itemMap['id'] ??
                            itemMap['tugas_harian_id'] ??
                            index + 1;

                        final judul =
                            itemMap['judul']?.toString() ??
                            itemMap['nama_tugas']?.toString() ??
                            itemMap['title']?.toString() ??
                            'Tugas ${index + 1}';
                        final rawDeskripsi =
                            itemMap['deskripsi']?.toString() ??
                            itemMap['keterangan']?.toString() ??
                            itemMap['instruksi']?.toString() ??
                            '';
                        final deskripsi = _cleanHtmlTags(rawDeskripsi);
                        final deadline = _extractDeadline(itemMap);
                        final tanggalMulai =
                            itemMap['tanggal_mulai']?.toString() ??
                            itemMap['created_at']?.toString();

                        // Ekstraksi riwayat pengumpulan tugas mahasiswa
                        final dynamic rawSubmissions =
                            itemMap['pengumpulan_tugas_harians'] ??
                            itemMap['pengumpulan_tugas'] ??
                            itemMap['pengumpulan'] ??
                            itemMap['submissions'] ??
                            itemMap['submission'];

                        List<dynamic> submissionsList = [];
                        if (rawSubmissions is List) {
                          submissionsList = rawSubmissions;
                        } else if (rawSubmissions is Map) {
                          submissionsList = [rawSubmissions];
                        }

                        final bool hasSubmitted = submissionsList.isNotEmpty;
                        final Map? lastSubmission =
                            hasSubmitted && submissionsList.first is Map
                            ? (submissionsList.first as Map)
                            : null;

                        final String submittedLink =
                            lastSubmission?['link_tugas']?.toString() ??
                            itemMap['link_pengumpulan']?.toString() ??
                            '';
                        final String submittedKendala =
                            lastSubmission?['kendala']?.toString() ?? '';
                        final String? submissionDate =
                            lastSubmission?['created_at']?.toString() ??
                            lastSubmission?['tanggal_pengumpulan']?.toString();

                        final nilai =
                            lastSubmission?['nilai']?.toString() ??
                            itemMap['nilai']?.toString() ??
                            itemMap['score']?.toString();

                        final feedback =
                            lastSubmission?['feedback']?.toString() ??
                            itemMap['feedback']?.toString() ??
                            itemMap['catatan_dosen']?.toString();

                        // Cek apakah batas deadline sudah lewat
                        bool isDeadlinePassed = false;
                        if (deadline != null && deadline.isNotEmpty) {
                          final dt = DateTime.tryParse(deadline);
                          if (dt != null && dt.isBefore(DateTime.now())) {
                            isDeadlinePassed = true;
                          }
                        }

                        final rawStatus =
                            itemMap['status']?.toString() ??
                            itemMap['status_pengumpulan']?.toString() ??
                            '';

                        String displayStatus = rawStatus;
                        if (displayStatus.isEmpty) {
                          if (hasSubmitted) {
                            displayStatus = 'Terkirim';
                          } else if (isDeadlinePassed) {
                            displayStatus = 'Batas Waktu Habis';
                          } else {
                            displayStatus = 'Belum Mengumpulkan';
                          }
                        }

                        final isSelesai =
                            hasSubmitted ||
                            displayStatus.toLowerCase().contains('selesai') ||
                            displayStatus.toLowerCase().contains('terkirim') ||
                            displayStatus.toLowerCase().contains('sudah');

                        final urls = _extractUrlsFromItem(
                          itemMap,
                          rawDeskripsi,
                        );

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF1F81FF,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'TIDN$taskId',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1F81FF),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            judul,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelesai
                                            ? Colors.green.shade50
                                            : isDeadlinePassed
                                            ? Colors.red.shade50
                                            : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSelesai
                                              ? Colors.green.shade300
                                              : isDeadlinePassed
                                              ? Colors.red.shade300
                                              : Colors.orange.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isSelesai
                                                ? Icons.check_circle_rounded
                                                : isDeadlinePassed
                                                ? Icons.warning_amber_rounded
                                                : Icons.pending_actions_rounded,
                                            size: 13,
                                            color: isSelesai
                                                ? Colors.green.shade800
                                                : isDeadlinePassed
                                                ? Colors.red.shade800
                                                : Colors.orange.shade800,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            displayStatus,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isSelesai
                                                  ? Colors.green.shade800
                                                  : isDeadlinePassed
                                                  ? Colors.red.shade800
                                                  : Colors.orange.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Nilai & Score
                                if (nilai != null && nilai.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Nilai Tugas: $nilai / 100',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Deadline Bar
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: deadline != null
                                        ? (isDeadlinePassed
                                              ? Colors.red.shade50
                                              : Colors.blue.shade50)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: deadline != null
                                          ? (isDeadlinePassed
                                                ? Colors.red.shade200
                                                : Colors.blue.shade200)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.alarm_on_rounded,
                                        size: 16,
                                        color: deadline != null
                                            ? (isDeadlinePassed
                                                  ? Colors.red.shade700
                                                  : Colors.blue.shade700)
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Deadline: ${deadline ?? 'Tidak ditentukan'}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: deadline != null
                                                ? (isDeadlinePassed
                                                      ? Colors.red.shade900
                                                      : Colors.blue.shade900)
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (tanggalMulai != null &&
                                    tanggalMulai.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 13,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Diberikan: $tanggalMulai',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                // Deskripsi tugas
                                if (deskripsi.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    deskripsi,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade800,
                                      height: 1.4,
                                    ),
                                  ),
                                ],

                                // File / Lampiran tugas dari dosen
                                if (urls.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '📎 Lampiran Tugas dari Dosen:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...urls.map(
                                    (u) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _openFileUrl(context, u),
                                        icon: const Icon(
                                          Icons.attach_file_rounded,
                                          size: 16,
                                        ),
                                        label: Text(
                                          u.length > 40
                                              ? '${u.substring(0, 40)}...'
                                              : u,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                // KOTAK RIWAYAT PENGUMPULAN (Jika Mahasiswa Sudah Mengumpulkan)
                                if (hasSubmitted) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFBBF7D0),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.task_alt_rounded,
                                              size: 16,
                                              color: Color(0xFF16A34A),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'Tugas Anda Telah Terkirim',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF166534),
                                              ),
                                            ),
                                            if (submissionDate != null &&
                                                submissionDate.isNotEmpty) ...[
                                              const Spacer(),
                                              Text(
                                                submissionDate,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF166534),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (submittedLink.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          InkWell(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            onTap: () => _openFileUrl(
                                              context,
                                              submittedLink,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF86EFAC,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.link_rounded,
                                                    size: 15,
                                                    color: Color(0xFF16A34A),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      submittedLink,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Color(
                                                          0xFF15803D,
                                                        ),
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(
                                                    Icons.open_in_new_rounded,
                                                    size: 13,
                                                    color: Color(0xFF15803D),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (submittedKendala.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.notes_rounded,
                                                size: 14,
                                                color: Color(0xFF4B5563),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Kendala: $submittedKendala',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF374151),
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (feedback != null &&
                                            feedback.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                  Icons.comment_bank_outlined,
                                                  size: 14,
                                                  color: Color(0xFFB45309),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'Feedback Dosen: $feedback',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF92400E),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            style: TextButton.styleFrom(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                            ),
                                            onPressed: () => _showSubmitModal(
                                              context: context,
                                              taskId: taskId,
                                              judul: judul,
                                              initialLink: submittedLink,
                                              initialKendala: submittedKendala,
                                            ),
                                            icon: const Icon(
                                              Icons.edit_note_rounded,
                                              size: 15,
                                            ),
                                            label: const Text(
                                              'Perbarui / Kirim Ulang Link',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  // TOMBOL PENGUMPULAN TUGAS UTAMA
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: () => _showSubmitModal(
                                        context: context,
                                        taskId: taskId,
                                        judul: judul,
                                        initialLink: submittedLink,
                                        initialKendala: submittedKendala,
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1F81FF,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.send_rounded,
                                        size: 17,
                                      ),
                                      label: const Text(
                                        'Kumpulkan Tugas',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Bottom Sheet untuk Mengumpulkan / Mengirim Tugas Harian
class _SubmitTugasBottomSheet extends ConsumerStatefulWidget {
  final dynamic taskId;
  final String kodeKelasHarian;
  final String judul;
  final String? initialLink;
  final String? initialKendala;

  const _SubmitTugasBottomSheet({
    required this.taskId,
    required this.kodeKelasHarian,
    required this.judul,
    this.initialLink,
    this.initialKendala,
  });

  @override
  ConsumerState<_SubmitTugasBottomSheet> createState() =>
      _SubmitTugasBottomSheetState();
}

class _SubmitTugasBottomSheetState
    extends ConsumerState<_SubmitTugasBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _linkController;
  late final TextEditingController _kendalaController;

  @override
  void initState() {
    super.initState();
    _linkController = TextEditingController(text: widget.initialLink ?? '');
    _kendalaController = TextEditingController(
      text: widget.initialKendala ?? '',
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    _kendalaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final link = _linkController.text.trim();
    final kendala = _kendalaController.text.trim();

    final success = await ref
        .read(tugasSubmitControllerProvider.notifier)
        .submit(
          tugasHarianId: widget.taskId,
          kodeKelasHarian: widget.kodeKelasHarian,
          linkTugas: link,
          kendala: kendala,
        );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ref.invalidate(detailTugasProvider(widget.kodeKelasHarian));
      ref.invalidate(tugasHarianProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tugas harian berhasil dikumpulkan! 🎉',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final errorMsg =
          ref.read(tugasSubmitControllerProvider).errorMessage ??
          'Gagal mengirim tugas. Silakan periksa koneksi atau sesi login Anda.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMsg)),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(tugasSubmitControllerProvider);
    final isSubmitting = submitState.isSubmitting;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F81FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      color: Color(0xFF1F81FF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1F81FF,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'TIDN${widget.taskId}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F81FF),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Kumpulkan Tugas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.judul,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Info Tip Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Color(0xFF1D4ED8),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pastikan link tugas (Google Drive, GitHub, Notion, atau Figma) dapat diakses publik atau dosen pengampu.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E40AF),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Input Link Tugas
              const Text(
                'Link Pengumpulan Tugas *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _linkController,
                enabled: !isSubmitting,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText:
                      'https://drive.google.com/... atau https://github.com/...',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  prefixIcon: const Icon(Icons.link_rounded, size: 18),
                  suffixIcon: _linkController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            setState(() {
                              _linkController.clear();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF1F81FF),
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (val) {
                  final text = val?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Link tugas wajib diisi!';
                  }
                  if (!text.startsWith('http://') &&
                      !text.startsWith('https://')) {
                    return 'Link harus diawali http:// atau https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Input Kendala
              const Text(
                'Kendala Pengerjaan (Opsional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _kendalaController,
                enabled: !isSubmitting,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Tuliskan catatan atau kendala jika ada (opsional)...',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 36),
                    child: Icon(Icons.edit_note_rounded, size: 20),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF1F81FF),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Submit
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1F81FF),
                    disabledBackgroundColor: const Color(
                      0xFF1F81FF,
                    ).withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Sedang Mengirim...',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Kirim Tugas',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
