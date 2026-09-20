import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/pencil_signature_pad.dart';
import '../../dashboard/presentation/dashboard_providers.dart';
import '../../dashboard/presentation/dashboard_utils.dart';
import '../domain/models/surat_izin_model.dart';
import 'surat_izin_preview_page.dart';
import '../../license/application/license_service.dart';
import '../../license/presentation/activation_modal.dart';

/// Halaman Formulir Pengajuan Surat Izin Tidak Masuk Kelas Politeknik IDN
class SuratIzinFormPage extends ConsumerStatefulWidget {
  final String? initialNama;
  final String? initialNim;
  final String? initialProdi;
  final String? initialMatkul;
  final String? initialMentor;
  final DateTime? initialTanggal;

  const SuratIzinFormPage({
    super.key,
    this.initialNama,
    this.initialNim,
    this.initialProdi,
    this.initialMatkul,
    this.initialMentor,
    this.initialTanggal,
  });

  @override
  ConsumerState<SuratIzinFormPage> createState() => _SuratIzinFormPageState();
}

class _SuratIzinFormPageState extends ConsumerState<SuratIzinFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaController;
  late final TextEditingController _nimController;
  late final TextEditingController _jurusanController;
  late final TextEditingController _noHpController;
  late final TextEditingController _keteranganController;
  late final TextEditingController _mentorController;

  late DateTime _mulaiIzin;
  late DateTime _akhirIzin;
  JenisIzin _jenisIzin = JenisIzin.sakitDiRumah;

  late final PencilSignatureController _signatureController;
  Uint8List? _suratDokterBytes;
  final ImagePicker _picker = ImagePicker();

  static const _prefPhoneKey = 'saved_surat_izin_no_hp';

  @override
  void initState() {
    super.initState();
    final today = widget.initialTanggal ?? DateTime.now();
    _mulaiIzin = DateTime(today.year, today.month, today.day);
    _akhirIzin = DateTime(today.year, today.month, today.day);

    _namaController = TextEditingController(text: widget.initialNama ?? '');
    _nimController = TextEditingController(text: widget.initialNim ?? '');
    _jurusanController = TextEditingController(text: widget.initialProdi ?? '');
    _noHpController = TextEditingController();
    _keteranganController = TextEditingController();
    _mentorController = TextEditingController(text: widget.initialMentor ?? '');

    _signatureController = PencilSignatureController(
      penColor: Colors.black,
      minStrokeWidth: 1.5,
      maxStrokeWidth: 4.2,
    );

    _loadSavedPhone();
  }

  Future<void> _loadSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString(_prefPhoneKey);
    if (savedPhone != null && savedPhone.isNotEmpty && mounted) {
      if (_noHpController.text.isEmpty) {
        _noHpController.text = savedPhone;
      }
    }
  }

  Future<void> _savePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPhoneKey, phone.trim());
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nimController.dispose();
    _jurusanController.dispose();
    _noHpController.dispose();
    _keteranganController.dispose();
    _mentorController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  int get _durasiHari {
    final start = DateTime(_mulaiIzin.year, _mulaiIzin.month, _mulaiIzin.day);
    final end = DateTime(_akhirIzin.year, _akhirIzin.month, _akhirIzin.day);
    final diff = end.difference(start).inDays;
    return (diff >= 0 ? diff : 0) + 1;
  }

  Future<void> _pickMulaiTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _mulaiIzin,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() {
        _mulaiIzin = picked;
        if (_akhirIzin.isBefore(_mulaiIzin)) {
          _akhirIzin = _mulaiIzin;
        }
      });
    }
  }

  Future<void> _pickAkhirTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _akhirIzin.isBefore(_mulaiIzin) ? _mulaiIzin : _akhirIzin,
      firstDate: _mulaiIzin,
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() {
        _akhirIzin = picked;
      });
    }
  }

  Future<void> _pickSuratDokter(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (xFile != null) {
        final bytes = await xFile.readAsBytes();
        setState(() {
          _suratDokterBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon bubuhkan tanda tangan Anda terlebih dahulu.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Lampiran surat dokter bersifat opsional; jika dilampirkan akan otomatis disertakan sebagai halaman ke-2 PDF.

    final signatureBytes = await _signatureController.toPngBytes();

    await _savePhone(_noHpController.text);

    final model = SuratIzinModel(
      namaLengkap: _namaController.text.trim(),
      nim: _nimController.text.trim(),
      jurusanKelas: _jurusanController.text.trim(),
      mulaiIzin: _mulaiIzin,
      akhirIzin: _akhirIzin,
      noHp: _noHpController.text.trim(),
      jenisIzin: _jenisIzin,
      keterangan: _keteranganController.text.trim(),
      namaMatkul: widget.initialMatkul ?? '',
      namaMentor: _mentorController.text.trim(),
      tandaTanganBytes: signatureBytes,
      suratDokterBytes: _suratDokterBytes,
    );

    if (!mounted) return;

    // Gerbang Lisensi Pro untuk Fitur Pembuatan Surat Izin
    final isPro = ref.read(licenseControllerProvider).valueOrNull ?? false;
    if (!isPro) {
      final activated = await ActivationModal.show(context);
      if (activated != true) {
        return; // Batal jika belum aktivasi lisensi
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SuratIzinPreviewPage(model: model)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sinkronisasi data profil jika field controller masih kosong
    final dashboardAsync = ref.watch(dashboardMahasiswaProvider);
    final kelasAsync = ref.watch(kelasHarianProvider);
    final profile = DashboardUtils.extractUserProfile(
      dashboardAsync.valueOrNull,
      kelasAsync.valueOrNull,
    );

    if (_namaController.text.isEmpty && profile.name != 'Mahasiswa') {
      _namaController.text = profile.name;
    }
    if (_nimController.text.isEmpty && profile.nim.isNotEmpty) {
      _nimController.text = profile.nim;
    }
    if (_jurusanController.text.isEmpty && profile.prodi != '-') {
      _jurusanController.text = profile.kelas != '-'
          ? '${profile.prodi} - ${profile.kelas}'
          : profile.prodi;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Buat Surat Izin Kelas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          children: [
            // Banner Info Format Resmi
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_rounded,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Format resmi Form Permohonan Izin Tidak Masuk Kelas Politeknik IDN Bogor.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF1E40AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Card 1: Biodata Mahasiswa
            _buildSectionHeader('Biodata Mahasiswa', Icons.person_rounded),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _namaController,
                      label: 'Nama Lengkap',
                      hint: 'Contoh: Musa Abdurrohim',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _nimController,
                      label: 'Nomor Induk Mahasiswa (NIM)',
                      hint: 'Contoh: 250490346014',
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'NIM wajib diisi'
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _jurusanController,
                      label: 'Jurusan & Kelas',
                      hint: 'Contoh: Teknik Rekayasa Komputer Jaringan',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Jurusan wajib diisi'
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _noHpController,
                      label: 'No. Handphone / WhatsApp',
                      hint: 'Contoh: 081904485273',
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'No. HP wajib diisi'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Card 2: Detail Waktu & Jenis Izin
            _buildSectionHeader(
              'Detail Permohonan Izin',
              Icons.event_note_rounded,
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date pickers
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickMulaiTanggal,
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mulai Izin',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '${_mulaiIzin.day}/${_mulaiIzin.month}/${_mulaiIzin.year}',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: InkWell(
                            onTap: _pickAkhirTanggal,
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Akhir Izin',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    '${_akhirIzin.day}/${_akhirIzin.month}/${_akhirIzin.year}',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Total Durasi: $_durasiHari Hari',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // Keterangan Izin Radio
                    Text(
                      'Keterangan Izin (Formulir Resmi)',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 8.w,
                      children: JenisIzin.values.map((item) {
                        final isSelected = _jenisIzin == item;
                        return ChoiceChip(
                          label: Text(item.label),
                          selected: isSelected,
                          selectedColor: const Color(0xFFDBEAFE),
                          labelStyle: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF1E40AF)
                                : const Color(0xFF4B5563),
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _jenisIzin = item);
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 12.h),

                    _buildTextField(
                      controller: _keteranganController,
                      label: 'Detail Alasan / Keterangan',
                      hint: 'Contoh: Sakit Demam dan Flu / Keperluan Keluarga',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Alasan izin wajib diisi'
                          : null,
                    ),
                    SizedBox(height: 12.h),

                    _buildTextField(
                      controller: _mentorController,
                      label: 'Nama Mentor / Asisten Dosen Tujuan',
                      hint: 'Contoh: Ka Aghna Damarula Priatna',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nama mentor/asdos wajib diisi'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Card 3: Tanda Tangan Mahasiswa
            _buildSectionHeader('Tanda Tangan Mahasiswa', Icons.draw_rounded),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Badge Efek Pensil Dinamis
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: const Color(0xFFBFDBFE),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.brush_rounded,
                                size: 12.sp,
                                color: const Color(0xFF1D4ED8),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Pensil Dinamis (Tinta Hitam)',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1D4ED8),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tombol Aksi Menu Tanda Tangan (Urungkan & Hapus)
                        AnimatedBuilder(
                          animation: _signatureController,
                          builder: (context, _) {
                            final hasStrokes = _signatureController.isNotEmpty;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Tombol Urungkan (Undo)
                                Material(
                                  color: hasStrokes
                                      ? const Color(0xFFF1F5F9)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6.r),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6.r),
                                    onTap: hasStrokes
                                        ? () => _signatureController.undo()
                                        : null,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                        border: Border.all(
                                          color: hasStrokes
                                              ? const Color(0xFFCBD5E1)
                                              : const Color(0xFFE2E8F0),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.undo_rounded,
                                            size: 13.sp,
                                            color: hasStrokes
                                                ? const Color(0xFF334155)
                                                : const Color(0xFF94A3B8),
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            'Urungkan',
                                            style: TextStyle(
                                              fontSize: 10.5.sp,
                                              fontWeight: FontWeight.w600,
                                              color: hasStrokes
                                                  ? const Color(0xFF334155)
                                                  : const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),

                                // Tombol Hapus (Clear)
                                Material(
                                  color: hasStrokes
                                      ? const Color(0xFFFEF2F2)
                                      : const Color(0xFFFAFAFA),
                                  borderRadius: BorderRadius.circular(6.r),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6.r),
                                    onTap: hasStrokes
                                        ? () => _signatureController.clear()
                                        : null,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                        border: Border.all(
                                          color: hasStrokes
                                              ? const Color(0xFFFECACA)
                                              : const Color(0xFFE2E8F0),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.delete_sweep_outlined,
                                            size: 13.sp,
                                            color: hasStrokes
                                                ? const Color(0xFFDC2626)
                                                : const Color(0xFF94A3B8),
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            'Hapus',
                                            style: TextStyle(
                                              fontSize: 10.5.sp,
                                              fontWeight: FontWeight.w600,
                                              color: hasStrokes
                                                  ? const Color(0xFFDC2626)
                                                  : const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      height: 170.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: PencilSignaturePad(
                          controller: _signatureController,
                          backgroundColor: Colors.white,
                          placeholderText:
                              'Goreskan tanda tangan tinta hitam Anda di sini...',
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 12.sp,
                          color: Colors.grey.shade500,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            'Bebas geser: Scroll form otomatis terkunci saat Anda menggoreskan tanda tangan.',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Card 4: Lampiran Surat Dokter (Dropdown / Accordion Opsional)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(
                  color: _suratDokterBytes != null
                      ? const Color(0xFFBFDBFE)
                      : Colors.grey.shade200,
                ),
              ),
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: _suratDokterBytes != null,
                  tilePadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 4.h,
                  ),
                  leading: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: _suratDokterBytes != null
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      _suratDokterBytes != null
                          ? Icons.check_circle_rounded
                          : Icons.medical_services_outlined,
                      color: _suratDokterBytes != null
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                      size: 20.sp,
                    ),
                  ),
                  title: Text(
                    'Lampiran Surat Dokter',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    _suratDokterBytes != null
                        ? '1 foto terlampir (akan jadi halaman ke-2 PDF)'
                        : 'Opsional • Buka jika ingin menyertakan surat dokter',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      color: _suratDokterBytes != null
                          ? const Color(0xFF2563EB)
                          : Colors.grey.shade500,
                      fontWeight: _suratDokterBytes != null
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                  childrenPadding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
                  children: [
                    if (_suratDokterBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.memory(
                          _suratDokterBytes!,
                          height: 180.h,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          minimumSize: Size(double.infinity, 38.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('Hapus Lampiran Dokter'),
                        onPressed: () {
                          setState(() => _suratDokterBytes = null);
                        },
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 11.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              icon: const Icon(
                                Icons.camera_alt_rounded,
                                size: 18,
                                color: Color(0xFF2563EB),
                              ),
                              label: Text(
                                'Kamera',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              onPressed: () =>
                                  _pickSuratDokter(ImageSource.camera),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 11.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              icon: const Icon(
                                Icons.photo_library_rounded,
                                size: 18,
                                color: Color(0xFF2563EB),
                              ),
                              label: Text(
                                'Galeri',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              onPressed: () =>
                                  _pickSuratDokter(ImageSource.gallery),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 13.sp,
                            color: Colors.grey.shade500,
                          ),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: Text(
                              'Lampiran otomatis digabungkan sebagai halaman ke-2 pada dokumen PDF.',
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                color: Colors.grey.shade600,
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
            SizedBox(height: 24.h),

            // Tombol Generate PDF
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: Text(
                'Pratinjau Surat Izin (PDF)',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              onPressed: _submitForm,
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: const Color(0xFF2563EB)),
          SizedBox(width: 6.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: 13.sp),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        labelStyle: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
        hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
    );
  }
}
