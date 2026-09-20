import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../application/device_identity_service.dart';
import '../application/license_generator_service.dart';

/// Halaman Khusus Creator / Admin (Allam Permata Putra) untuk generate Serial Key
class AdminKeygenPage extends ConsumerStatefulWidget {
  const AdminKeygenPage({super.key});

  @override
  ConsumerState<AdminKeygenPage> createState() => _AdminKeygenPageState();
}

class _AdminKeygenPageState extends ConsumerState<AdminKeygenPage> {
  final TextEditingController _deviceController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  GeneratedLicenseItem? _lastGenerated;
  List<GeneratedLicenseItem> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _deviceController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final list = await ref.read(licenseGeneratorServiceProvider).getHistory();
    if (mounted) {
      setState(() {
        _history = list;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      String text = data.text!.trim();
      // Jika teks panjang seperti format chat "Kode Perangkat saya: IDN-XXXX-XXXX", ekstrak IDN- nya
      final regExp = RegExp(
        r'IDN-[A-Z0-9]{4}-[A-Z0-9]{4}',
        caseSensitive: false,
      );
      final match = regExp.firstMatch(text);
      if (match != null) {
        text = match.group(0)!;
      }
      setState(() {
        _deviceController.text = text.toUpperCase();
        _errorMessage = null;
      });
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _useCurrentDevice() async {
    final myId = await DeviceIdentityService.getDeviceId();
    setState(() {
      _deviceController.text = myId;
      _errorMessage = null;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _generateKey() async {
    final rawDevice = _deviceController.text.trim();
    if (rawDevice.isEmpty) {
      setState(() {
        _errorMessage = 'Masukkan kode perangkat pembeli terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final item = await ref
          .read(licenseGeneratorServiceProvider)
          .generateKey(
            rawDeviceId: rawDevice,
            customerName: _nameController.text.trim(),
          );

      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _lastGenerated = item;
          _isLoading = false;
        });
        await _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal membuat serial key: $e';
        });
      }
    }
  }

  Future<void> _copyText(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF1E293B),
        ),
      );
    }
  }

  Future<void> _shareToWhatsApp(GeneratedLicenseItem item) async {
    final message = ref
        .read(licenseGeneratorServiceProvider)
        .buildWhatsAppMessage(
          serialKey: item.serialKey,
          customerName: item.customerName,
        );
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        _copyText(message, 'Teks WA disalin karena gagal membuka WhatsApp.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18.sp),
          color: const Color(0xFF0F172A),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Creator Key Studio',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 14.w),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield_rounded,
                  size: 13.sp,
                  color: const Color(0xFF4F46E5),
                ),
                SizedBox(width: 4.w),
                Text(
                  'MASTER',
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. Input Form Card
            _buildGeneratorFormCard(),
            SizedBox(height: 18.h),

            // 3. Last Generated Key Result
            if (_lastGenerated != null) ...[
              _buildResultCard(_lastGenerated!),
              SizedBox(height: 24.h),
            ],

            // 4. Riwayat Lisensi Dibuat
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratorFormCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KODE PERANGKAT PEMBELI',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF475569),
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: _useCurrentDevice,
                    borderRadius: BorderRadius.circular(6.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      child: Text(
                        'HP Ini',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    ' • ',
                    style: TextStyle(
                      color: const Color(0xFFCBD5E1),
                      fontSize: 11.sp,
                    ),
                  ),
                  InkWell(
                    onTap: _pasteFromClipboard,
                    borderRadius: BorderRadius.circular(6.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.paste_rounded,
                            size: 12.sp,
                            color: const Color(0xFF4F46E5),
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            'Tempel',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4F46E5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _deviceController,
            textCapitalization: TextCapitalization.characters,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Misal: IDN-A7F2-91B0',
              hintStyle: TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 13.sp,
                fontWeight: FontWeight.normal,
                color: const Color(0xFF94A3B8),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 12.h,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(
                  color: Color(0xFF4F46E5),
                  width: 1.5,
                ),
              ),
            ),
          ),
          SizedBox(height: 14.h),

          // Nama Pembeli (Opsional)
          Text(
            'NAMA / CATATAN PEMBELI (OPSIONAL)',
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF475569),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 6.h),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Misal: Ahmad Fauzi (RPL 2024)',
              hintStyle: TextStyle(
                fontSize: 12.5.sp,
                color: const Color(0xFF94A3B8),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 11.h,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(
                  color: Color(0xFF4F46E5),
                  width: 1.5,
                ),
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 14.sp,
                    color: const Color(0xFFDC2626),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              icon: _isLoading
                  ? SizedBox(
                      width: 18.r,
                      height: 18.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.auto_fix_high_rounded, size: 18.sp),
              label: Text(
                _isLoading
                    ? 'Menandatangani Kriptografi...'
                    : 'Generate Serial Key Sekarang',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(GeneratedLicenseItem item) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Serial Key Berhasil Dibuat!',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF14532D),
                      ),
                    ),
                    Text(
                      'Target: ${item.deviceId} ${item.customerName.isNotEmpty ? "(${item.customerName})" : ""}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Box Serial Key
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: SelectableText(
              item.serialKey,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                height: 1.35,
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyText(
                    item.serialKey,
                    'Serial Key disalin ke clipboard!',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF166534),
                    side: const BorderSide(color: Color(0xFF86EFAC)),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                  ),
                  icon: Icon(Icons.copy_rounded, size: 14.sp),
                  label: Text(
                    'Salin Key',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _shareToWhatsApp(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                  ),
                  icon: Icon(Icons.send_rounded, size: 14.sp),
                  label: Text(
                    'Kirim ke WA',
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 16.sp,
                  color: const Color(0xFF475569),
                ),
                SizedBox(width: 6.w),
                Text(
                  'Riwayat Key Terbuat (${_history.length})',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            if (_history.isNotEmpty)
              InkWell(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Hapus Seluruh Riwayat?'),
                      content: const Text(
                        'Riwayat kunci yang pernah dibuat akan dihapus dari penyimpanan HP ini.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Hapus Semua'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref
                        .read(licenseGeneratorServiceProvider)
                        .clearHistory();
                    await _loadHistory();
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: Text(
                    'Hapus Semua',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 10.h),
        if (_history.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 24.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.key_off_rounded,
                  size: 28.sp,
                  color: const Color(0xFF94A3B8),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Belum ada Serial Key yang pernah dibuat.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _history.length,
            separatorBuilder: (context, index) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              final item = _history[index];
              return Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.phone_android_rounded,
                        size: 16.sp,
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.deviceId,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              if (item.customerName.isNotEmpty) ...[
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text(
                                    '• ${item.customerName}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            item.serialKey.length > 25
                                ? '${item.serialKey.substring(0, 25)}...'
                                : item.serialKey,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy_rounded, size: 16.sp),
                      color: const Color(0xFF64748B),
                      tooltip: 'Salin Key',
                      onPressed: () => _copyText(
                        item.serialKey,
                        'Serial Key untuk ${item.deviceId} disalin!',
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.share_rounded, size: 16.sp),
                      color: const Color(0xFF16A34A),
                      tooltip: 'Kirim ke WA',
                      onPressed: () => _shareToWhatsApp(item),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
