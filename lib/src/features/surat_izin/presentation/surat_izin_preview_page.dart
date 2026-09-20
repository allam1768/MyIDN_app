import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../application/surat_izin_pdf_service.dart';
import '../domain/models/surat_izin_model.dart';

/// Halaman Pratinjau & Berbagi Dokumen PDF Surat Izin Mahasiswa Politeknik IDN
class SuratIzinPreviewPage extends StatefulWidget {
  final SuratIzinModel model;

  const SuratIzinPreviewPage({super.key, required this.model});

  @override
  State<SuratIzinPreviewPage> createState() => _SuratIzinPreviewPageState();
}

class _SuratIzinPreviewPageState extends State<SuratIzinPreviewPage> {
  bool _isHeaderExpanded = true;
  bool _isSharing = false;
  Uint8List? _cachedPdfBytes;

  String get _fileName =>
      'Surat_Izin_${widget.model.namaLengkap.replaceAll(' ', '_')}_${widget.model.nim}.pdf';

  Future<Uint8List> _getPdfBytes() async {
    if (_cachedPdfBytes != null) {
      return _cachedPdfBytes!;
    }
    final bytes = await SuratIzinPdfService.generatePdf(widget.model);
    _cachedPdfBytes = bytes;
    return bytes;
  }

  void _copyWaIntroMessage({bool showSnackBar = true}) {
    final message = widget.model.generateWhatsAppMessage();
    Clipboard.setData(ClipboardData(text: message));

    if (showSnackBar && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16.w,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pesan Pengantar WA Disalin!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5.sp,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Tinggal tempel saat melampirkan file PDF di WhatsApp.',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          duration: const Duration(seconds: 4),
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
      );
    }
  }

  Future<void> _sharePdfDocument() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      // Salin pesan pengantar secara otomatis sebelum modal share dibuka
      _copyWaIntroMessage(showSnackBar: false);

      final pdfBytes = await _getPdfBytes();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: _fileName,
        subject: 'Surat Izin - ${widget.model.namaLengkap}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8.w),
                const Expanded(
                  child: Text(
                    'Pesan pengantar WA sudah otomatis disalin ke clipboard!',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1F81FF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            duration: const Duration(seconds: 4),
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membagikan dokumen: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _printPdfDocument() async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) => _getPdfBytes(),
        name: _fileName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencetak dokumen: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showWhatsAppIntroSheet() {
    _copyWaIntroMessage(showSnackBar: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),

                // Title & Tag
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: const Icon(
                        Icons.chat_rounded,
                        color: Color(0xFF16A34A),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Format Pesan Pengantar WhatsApp',
                            style: TextStyle(
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Teks resmi permohonan izin untuk Dosen / Mentor',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Preview Bubble
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxHeight: 280.h),
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      widget.model.generateWhatsAppMessage(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        height: 1.5,
                        color: const Color(0xFF14532D),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          side: const BorderSide(color: Color(0xFF16A34A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        icon: const Icon(
                          Icons.copy_rounded,
                          color: Color(0xFF16A34A),
                          size: 18,
                        ),
                        label: Text(
                          'Salin Teks',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                        onPressed: () {
                          _copyWaIntroMessage();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: Text(
                          'Kirim PDF Sekarang',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _sharePdfDocument();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pratinjau Surat Izin',
              style: TextStyle(
                color: const Color(0xFF0F172A),
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Politeknik IDN Bogor',
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: Column(
        children: [
          // Header Info Ringkasan Mahasiswa & Dokumen
          _buildDocumentSummaryHeader(),

          // Area Pratinjau PDF Interaktif
          Expanded(
            child: PdfPreview(
              build: (format) => _getPdfBytes(),
              initialPageFormat: PdfPageFormat.a4,
              pdfFileName: _fileName,
              canChangePageFormat: false,
              canChangeOrientation: false,
              useActions: false, // Gunakan custom action bar bertema aplikasi
              canDebug: false,
              scrollViewDecoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
              ),
              pdfPreviewPageDecoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ],
              ),
              loadingWidget: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 20.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF1F81FF),
                          ),
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        'Menyiapkan Dokumen PDF...',
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'Format resmi Surat Izin Politeknik IDN',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              onError: (context, error) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEF3C7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.description_rounded,
                              color: Color(0xFFD97706),
                              size: 32,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Dokumen PDF Siap Dikirim!',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Pratinjau visual PDF di layar sedang dipersiapkan. File PDF sudah berhasil dibentuk dan siap langsung dibagikan ke WhatsApp atau dicetak.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1F81FF),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 12.h,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: Text(
                              'Kirim PDF Sekarang',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: _sharePdfDocument,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              children: [
                // Tombol Cetak Dokumen Cepat
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: IconButton(
                    tooltip: 'Cetak Dokumen',
                    icon: const Icon(
                      Icons.print_rounded,
                      color: Color(0xFF475569),
                      size: 20,
                    ),
                    onPressed: _printPdfDocument,
                  ),
                ),
                SizedBox(width: 10.w),

                // Tombol Salin / Buka Pesan Pengantar WA
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      side: const BorderSide(color: Color(0xFF16A34A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    icon: const Icon(
                      Icons.chat_rounded,
                      color: Color(0xFF16A34A),
                      size: 18,
                    ),
                    label: Text(
                      'Format WA',
                      style: TextStyle(
                        color: const Color(0xFF16A34A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                    onPressed: _showWhatsAppIntroSheet,
                  ),
                ),
                SizedBox(width: 10.w),

                // Tombol Kirim / Share PDF
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      backgroundColor: const Color(0xFF1F81FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    icon: _isSharing
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.share_rounded, size: 18),
                    label: Text(
                      _isSharing ? 'Menyiapkan...' : 'Kirim PDF',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5.sp,
                      ),
                    ),
                    onPressed: _isSharing ? null : _sharePdfDocument,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header Ringkasan Info Dokumen Mahasiswa (Bisa di-expand/collapse)
  Widget _buildDocumentSummaryHeader() {
    final model = widget.model;
    final isSakit = model.isSakit;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Baris Utama: Nama, NIM, & Tombol Toggle
          InkWell(
            onTap: () {
              setState(() {
                _isHeaderExpanded = !_isHeaderExpanded;
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(
                children: [
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: Color(0xFF1F81FF),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.namaLengkap,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          '${model.nim} • ${model.jurusanKelas}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSakit
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      model.jenisIzin.label,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isSakit
                            ? const Color(0xFFB45309)
                            : const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    _isHeaderExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Detail Tambahan yang dapat dilipat
          if (_isHeaderExpanded) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildInfoPill(
                          icon: Icons.calendar_today_rounded,
                          label: 'Durasi',
                          value:
                              '${model.durasiHari} Hari (${model.mulaiIzin.day}/${model.mulaiIzin.month}${model.durasiHari > 1 ? ' - ${model.akhirIzin.day}/${model.akhirIzin.month}' : ''})',
                        ),
                        SizedBox(width: 8.w),
                        _buildInfoPill(
                          icon: model.suratDokterBytes != null
                              ? Icons.health_and_safety_rounded
                              : Icons.article_outlined,
                          label: 'Halaman',
                          value: model.suratDokterBytes != null
                              ? '2 Hlm (+Dokter)'
                              : '1 Halaman',
                          valueColor: model.suratDokterBytes != null
                              ? const Color(0xFF16A34A)
                              : null,
                        ),
                      ],
                    ),
                    if (model.namaMentor.isNotEmpty ||
                        model.namaMatkul.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              'Tujuan: ${model.namaMentor.isNotEmpty ? model.namaMentor : 'Dosen/Mentor'}${model.namaMatkul.isNotEmpty ? ' • ${model.namaMatkul}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF1F81FF)),
            SizedBox(width: 6.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9.5.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
