import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../domain/models/surat_izin_model.dart';

/// Layanan penghasil dokumen PDF resmi Surat Izin Tidak Masuk Kelas Politeknik IDN
class SuratIzinPdfService {
  /// Generate byte array PDF dari entitas SuratIzinModel
  static Future<Uint8List> generatePdf(SuratIzinModel model) async {
    final pdf = pw.Document(
      title: 'Surat Izin Tidak Masuk Kelas - ${model.namaLengkap}',
      author: 'Politeknik IDN Bogor',
      theme: pw.ThemeData.withFont(
        base: pw.Font.times(),
        bold: pw.Font.timesBold(),
        italic: pw.Font.timesItalic(),
        boldItalic: pw.Font.timesBoldItalic(),
      ),
    );

    // Muat logo resmi Politeknik IDN (Square logo)
    Uint8List? idnLogoBytes;
    try {
      final byteData = await rootBundle.load(
        'assets/dokumen/idn_logo_square.png',
      );
      idnLogoBytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
    } catch (_) {
      idnLogoBytes = null;
    }

    // ==========================================
    // HALAMAN 1: FORMULIR UTAMA
    // ==========================================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Kop Surat Resmi
              _buildKopHeader(idnLogoBytes),

              pw.SizedBox(height: 3),
              pw.Text('Lampiran 1.', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 6),

              // Tabel Biodata & Izin
              _buildMainTable(model),

              pw.SizedBox(height: 18),
              pw.Text(
                'Tanda Tangan Dibawah ini :',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 6),

              // Tabel Tanda Tangan
              _buildSignatureTable(model),

              pw.SizedBox(height: 10),

              // Kotak Catatan
              _buildCatatanBox(),

              pw.Spacer(),

              pw.Spacer(),

              // Footer Dokumen Resmi
              _buildDocumentFooter(),
            ],
          );
        },
      ),
    );

    // ==========================================
    // HALAMAN 2: LAMPIRAN SURAT DOKTER (OPSIONAL)
    // ==========================================
    if (model.suratDokterBytes != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildKopHeader(idnLogoBytes),

                pw.SizedBox(height: 16),
                pw.Text(
                  'Kirim Surat Keterangan Dokter dibawah ini :',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),

                // Area Gambar Surat Dokter
                pw.Expanded(
                  child: pw.Container(
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 0.8),
                    ),
                    padding: const pw.EdgeInsets.all(10),
                    alignment: pw.Alignment.center,
                    child: pw.Image(
                      pw.MemoryImage(model.suratDokterBytes!),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),

                pw.SizedBox(height: 10),
                _buildDocumentFooter(),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Header Kop Surat Resmi: Logo IDN di kiri, Teks Judul di kanan, Garis hitam di bawah
  static pw.Widget _buildKopHeader(Uint8List? idnLogoBytes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (idnLogoBytes != null)
              pw.Container(
                width: 94,
                // height: 68,
                margin: const pw.EdgeInsets.only(right: 16),
                child: pw.Image(
                  pw.MemoryImage(idnLogoBytes),
                  fit: pw.BoxFit.contain,
                ),
              )
            else
              _buildFallbackHeader(),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'FORM PERMOHONAN IZIN TIDAK MASUK KELAS',
                    style: pw.TextStyle(
                      fontSize: 13.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Politeknik IDN Bogor',
                    style: pw.TextStyle(
                      fontSize: 12.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Container(
          width: double.infinity,
          height: 1.5,
          color: PdfColors.black,
        ),
      ],
    );
  }

  /// Fallback header jika aset gambar tidak ditemukan
  static pw.Widget _buildFallbackHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue800, width: 2),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            'POLITEKNIK IDN',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.Spacer(),
          pw.Text(
            'Bogor - Jawa Barat',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  /// Footer Dokumen Resmi Sesuai Format Template IDN (Garis + Teks Berbingkai + Balok Oranye)
  static pw.Widget _buildDocumentFooter() {
    final charcoal = PdfColor.fromHex('#595959');
    final idnOrange = PdfColor.fromHex('#EC7D31');

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Sisi kiri: Garis horizontal dan Kotak Teks
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                width: double.infinity,
                height: 1.2,
                color: charcoal,
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1.5,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: charcoal, width: 0.5),
                ),
                child: pw.Text(
                  'Politeknik IDN Bogor | Form Izin Tidak Kelas Politeknik IDN Bogor',
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Sisi kanan: Balok Oranye IDN yang sejajar garis dan teks
        pw.Container(width: 32, height: 15, color: idnOrange),
      ],
    );
  }

  /// Tabel Utama Data Formulir Izin
  static pw.Widget _buildMainTable(SuratIzinModel model) {
    const tableBorder = pw.TableBorder(
      top: pw.BorderSide(color: PdfColors.black, width: 0.8),
      bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
      left: pw.BorderSide(color: PdfColors.black, width: 0.8),
      right: pw.BorderSide(color: PdfColors.black, width: 0.8),
      horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.8),
      verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.8),
    );

    return pw.Table(
      border: tableBorder,
      columnWidths: {
        0: const pw.FixedColumnWidth(130),
        1: const pw.FixedColumnWidth(15),
        2: const pw.FlexColumnWidth(),
      },
      children: [
        _buildTableRow('Nama Lengkap', model.namaLengkap),
        _buildTableRow('NIM', model.nim),
        _buildTableRow('Jurusan & Kelas', model.jurusanKelas),
        _buildTableRow('Lama Izin', model.lamaIzinFormatted),
        _buildTableRow('Mulai Izin', model.mulaiIzinFormatted),
        _buildTableRow('Akhir Izin', model.akhirIzinFormatted),
        _buildTableRow('No. Handphone', model.noHp),
        _buildKeteranganIzinRow(model.jenisIzin),
        _buildTableRow(
          'Keterangan',
          model.keterangan.isNotEmpty ? model.keterangan : '-',
        ),
      ],
    );
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 9.5)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          alignment: pw.Alignment.center,
          child: pw.Text(':', style: const pw.TextStyle(fontSize: 9.5)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 9.5)),
        ),
      ],
    );
  }

  /// Baris khusus Keterangan Izin dengan Checkbox
  static pw.TableRow _buildKeteranganIzinRow(JenisIzin selected) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Text(
            'Keterangan Izin',
            style: const pw.TextStyle(fontSize: 9.5),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          alignment: pw.Alignment.center,
          child: pw.Text(':', style: const pw.TextStyle(fontSize: 9.5)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Row(
            children: [
              _buildCheckbox(
                'Sakit di Rumah',
                selected == JenisIzin.sakitDiRumah,
              ),
              pw.SizedBox(width: 14),
              _buildCheckbox('Sakit di RS', selected == JenisIzin.sakitDiRs),
              pw.SizedBox(width: 14),
              _buildCheckbox('Lainnya', selected == JenisIzin.lainnya),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCheckbox(String label, bool isChecked) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 5,
          height: 5,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
            color: isChecked ? PdfColors.black : PdfColors.white,
          ),
          alignment: pw.Alignment.center,
          child: isChecked
              ? pw.Text(
                  '',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 7,
                  ),
                )
              : null,
        ),
        pw.SizedBox(width: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  /// Tabel 2 Kolom Tanda Tangan
  static pw.Widget _buildSignatureTable(SuratIzinModel model) {
    const tableBorder = pw.TableBorder(
      top: pw.BorderSide(color: PdfColors.black, width: 0.8),
      bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
      left: pw.BorderSide(color: PdfColors.black, width: 0.8),
      right: pw.BorderSide(color: PdfColors.black, width: 0.8),
      horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.8),
      verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.8),
    );

    return pw.Table(
      border: tableBorder,
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1),
      },
      children: [
        // Baris Header Tanda Tangan
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              child: pw.Center(
                child: pw.Text(
                  'Yang Mengajukan',
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              child: pw.Center(
                child: pw.Text(
                  'Mentor / Asisten Dosen',
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
              ),
            ),
          ],
        ),

        // Baris Area Gambar Tanda Tangan
        pw.TableRow(
          children: [
            pw.Container(
              height: 75,
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.all(2),
              margin: const pw.EdgeInsets.symmetric(vertical: 4),
              child: model.tandaTanganBytes != null
                  ? pw.Image(
                      pw.MemoryImage(model.tandaTanganBytes!),
                      fit: pw.BoxFit.contain,
                    )
                  : pw.SizedBox(height: 75),
            ),
            pw.Container(
              height: 75,
              alignment: pw.Alignment.center,
              child: pw.SizedBox(height: 75),
            ),
          ],
        ),

        // Baris Nama Terang
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Center(
                child: pw.Text(
                  model.namaLengkap,
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Center(
                child: pw.Text(
                  model.namaMentor.isNotEmpty
                      ? model.namaMentor
                      : 'Nama mentor',
                  style: const pw.TextStyle(fontSize: 9.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Kotak Catatan Sesuai Format Resmi Dokumen
  static pw.Widget _buildCatatanBox() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Catatan :',
            style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          _buildCatatanItem(
            pw.TextSpan(
              style: const pw.TextStyle(fontSize: 8.5),
              children: [
                const pw.TextSpan(
                  text:
                      'Mahasiswa yang akan mengajukan izin tidak masuk kelas ',
                ),
                pw.TextSpan(
                  text: 'DiWAJIBKAN',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                const pw.TextSpan(
                  text:
                      ' mengisi Form Permohonan Izin Tidak Masuk Kelas (sesuai format lampiran 1).',
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 3),
          _buildCatatanItem(
            pw.TextSpan(
              style: const pw.TextStyle(fontSize: 8.5),
              children: [
                const pw.TextSpan(text: 'Izin karena Sakit >= 2 hari, maka '),
                pw.TextSpan(
                  text: 'WAJIB',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                const pw.TextSpan(
                  text: ' menyertakan Surat keterangan Dokter.',
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 3),
          _buildCatatanItem(
            pw.TextSpan(
              style: const pw.TextStyle(fontSize: 8.5),
              children: [
                const pw.TextSpan(text: 'Jika Izin tapi '),
                pw.TextSpan(
                  text: 'TIDAK',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                const pw.TextSpan(
                  text: ' mengisi Form Lampiran ini maka akan dianggap ',
                ),
                pw.TextSpan(
                  text: 'ALPHA',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCatatanItem(pw.InlineSpan span) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 4, right: 6),
          width: 3.5,
          height: 3.5,
          decoration: const pw.BoxDecoration(
            color: PdfColors.black,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.Expanded(child: pw.RichText(text: span)),
      ],
    );
  }
}
