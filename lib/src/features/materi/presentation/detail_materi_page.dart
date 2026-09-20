import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../common_widgets/async_value_widget.dart';
import '../../../common_widgets/kelas_header_card.dart';
import '../../../common_widgets/raw_json_card.dart';
import '../../../constants/lms_endpoints.dart';
import 'materi_providers.dart';

class DetailMateriPage extends ConsumerWidget {
  final String kodeKelasHarian;
  final String namaKelas;

  const DetailMateriPage({
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
        'link_materi',
        'url',
        'link',
        'file_url',
        'file_path',
        'path',
        'materi_file',
        'attachment',
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
    } else if (item is String) {
      String u = item.trim();
      if (u.startsWith('/')) u = '${LmsEndpoints.baseUrl}$u';
      if (u.startsWith('http')) {
        extractedUrls.add(u);
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

  Widget _buildUrlActionButtons(BuildContext context, String url) {
    final lower = url.toLowerCase();
    final isGoogleSlide = lower.contains('docs.google.com/presentation');
    final isGoogleDoc = lower.contains('docs.google.com/document');
    final isPdf =
        lower.endsWith('.pdf') ||
        lower.contains('.pdf?') ||
        lower.contains('export/pdf');

    String? pdfExportUrl;
    if (isGoogleSlide || isGoogleDoc) {
      if (url.contains('/edit')) {
        pdfExportUrl = url.replaceAll(RegExp(r'/edit.*$'), '/export/pdf');
      } else {
        pdfExportUrl = '$url/export/pdf';
      }
    }

    if (isGoogleSlide) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openFileUrl(context, url),
              icon: const Icon(Icons.slideshow_rounded, size: 20),
              label: const Text(
                '📽️ Buka Presentasi (PPT / Google Slides)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF29900),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (pdfExportUrl != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openFileUrl(context, pdfExportUrl!),
                icon: const Icon(
                  Icons.picture_as_pdf,
                  size: 18,
                  color: Colors.red,
                ),
                label: const Text(
                  '📥 Unduh Slide sebagai PDF',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    if (isGoogleDoc) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openFileUrl(context, url),
              icon: const Icon(Icons.description, size: 20),
              label: const Text('📄 Buka Dokumen (Google Docs)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          if (pdfExportUrl != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openFileUrl(context, pdfExportUrl!),
                icon: const Icon(
                  Icons.picture_as_pdf,
                  size: 18,
                  color: Colors.red,
                ),
                label: const Text(
                  '📥 Unduh Dokumen sebagai PDF',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    if (isPdf) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _openFileUrl(context, url),
          icon: const Icon(Icons.picture_as_pdf, size: 20),
          label: const Text('📕 Buka File Dokumen PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _openFileUrl(context, url),
        icon: const Icon(Icons.open_in_new, size: 18),
        label: Text(
          url.length > 35
              ? '🔗 Buka Link: ${url.substring(0, 35)}...'
              : '🔗 Buka: $url',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Declarative & auto-cached via Riverpod!
    final materiAsync = ref.watch(detailMateriProvider(kodeKelasHarian));

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(namaKelas)),
      body: AsyncValueWidget<dynamic>(
        value: materiAsync,
        onRetry: () => ref.invalidate(detailMateriProvider(kodeKelasHarian)),
        data: (detailData) {
          List<dynamic> materiList = [];
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

            final rawMateri =
                props['materis'] ?? props['materi_harians'] ?? props['materi'];
            if (rawMateri is List) {
              materiList = rawMateri;
            } else if (rawMateri is Map && rawMateri['data'] is List) {
              materiList = rawMateri['data'];
            }
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(detailMateriProvider(kodeKelasHarian)),
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
                    primaryColor: Colors.teal,
                    icon: Icons.class_rounded,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '📄 Daftar File Materi (${materiList.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (materiList.isEmpty)
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
                                Icons.folder_open_rounded,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Belum ada file materi yang diunggah untuk kelas ini.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
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
                      itemCount: materiList.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = materiList[index];
                        final Map itemMap = (item is Map) ? item : {};

                        final judul =
                            itemMap['judul'] ??
                            itemMap['nama'] ??
                            'Materi ${index + 1}';
                        final rawDeskripsi =
                            itemMap['deskripsi']?.toString() ?? '';
                        final deskripsiClean = _cleanHtmlTags(rawDeskripsi);
                        final tanggalDibuat =
                            itemMap['created_at']?.toString() ?? '-';

                        final List<String> extractedUrls = _extractUrlsFromItem(
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
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.article_rounded,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        judul.toString(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (deskripsiClean.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    deskripsiClean,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Tanggal: $tanggalDibuat',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                if (extractedUrls.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  ...extractedUrls.map(
                                    (url) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: _buildUrlActionButtons(
                                        context,
                                        url,
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
                  if (kDebugMode) ...[
                    const SizedBox(height: 20),
                    RawJsonCard(
                      title: 'Raw JSON Detail Materi',
                      icon: Icons.code_rounded,
                      color: Colors.purple,
                      data: detailData,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
