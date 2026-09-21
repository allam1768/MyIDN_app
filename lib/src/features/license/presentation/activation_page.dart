import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/presentation/login_page.dart';
import '../application/device_identity_service.dart';
import '../application/license_service.dart';

/// Halaman Gerbang Aktivasi Pertama (First-Time Activation Gatekeeper)
/// Wajib memasukkan Serial Key yang sah sebelum pengguna dapat masuk ke aplikasi.
class ActivationPage extends ConsumerStatefulWidget {
  const ActivationPage({super.key});

  @override
  ConsumerState<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends ConsumerState<ActivationPage> {
  final TextEditingController _keyController = TextEditingController();
  String? _deviceId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceId() async {
    final id = await DeviceIdentityService.getDeviceId();
    if (mounted) {
      setState(() {
        _deviceId = id;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        _keyController.text = data!.text!.trim();
        _errorMessage = null;
      });
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _copyDeviceId() async {
    if (_deviceId != null) {
      await Clipboard.setData(ClipboardData(text: _deviceId!));
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kode Perangkat $_deviceId disalin ke clipboard!'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF1F2937),
          ),
        );
      }
    }
  }

  Future<void> _openWhatsApp() async {
    if (_deviceId == null) return;
    final message =
        'Halo Admin Allam, saya ingin membeli lisensi resmi aplikasi MyIDN seharga Rp 25.000.\n\n'
        '📱 Kode Perangkat Saya:\n$_deviceId\n\n'
        'Berikut saya lampirkan foto/screenshot bukti transfer pembayaran QRIS sebesar Rp 25.000 untuk proses pembuatan Serial Key resmi. Terima kasih!';
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal membuka WhatsApp. Silakan salin kode perangkat manual.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _submitActivation() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _errorMessage =
            'Silakan masukkan atau tempel Serial Key terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(licenseControllerProvider.notifier)
        .activate(key);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.stars_rounded, color: Color(0xFFFBBF24)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aktivasi Berhasil! Selamat datang di IDN Reminder.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF065F46),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );

      // Arahkan ke halaman login LMS utama
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _errorMessage =
            'Serial Key tidak valid untuk perangkat ini! Pastikan kode lisensi sesuai dengan kode perangkat Anda.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Icon Badge Hero & Premium Notice
                Container(
                  width: 68.r,
                  height: 68.r,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1D4ED8).withValues(alpha: 0.28),
                        blurRadius: 16.r,
                        offset: Offset(0, 6.h),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: const Color(0xFFFBBF24),
                      size: 34.sp,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Badge Aplikasi Berbayar
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 14.sp,
                        color: const Color(0xFFD97706),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'APLIKASI BERBAYAR • LISENSI SEUMUR HIDUP',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF92400E),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),

                // 2. Headline & Subtitle
                Text(
                  'Aktivasi Lisensi MyIDN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Aplikasi ini merupakan software berbayar untuk mahasiswa Politeknik IDN. Satu lisensi berlaku permanen selamanya dan terkunci aman pada perangkat ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    color: const Color(0xFF6B7280),
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 24.h),

                // 3. Card Pembayaran QRIS
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2_rounded,
                            size: 18.sp,
                            color: const Color(0xFF1D4ED8),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'LANGKAH 1: PEMBAYARAN VIA QRIS',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E3A8A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),

                      // Badge Nominal Harga 25k
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF047857), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF059669).withValues(alpha: 0.28),
                              blurRadius: 8.r,
                              offset: Offset(0, 3.h),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sell_rounded, size: 14.sp, color: Colors.white),
                            SizedBox(width: 6.w),
                            Text(
                              'Harga Lisensi: Rp 25.000 (Sekali Bayar)',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Scan barcode QRIS di bawah ini dan transfer sebesar Rp 25.000 menggunakan GoPay, OVO, DANA, ShopeePay, BCA, atau Mobile Banking apa saja:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // Tampilan Gambar QRIS
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.asset(
                            'assets/dokumen/qris.png',
                            width: 220.w,
                            height: 220.w,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Nominal Transfer: Rp 25.000 (Pas)',
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF047857),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '⚡ QRIS Nasional Resmi • Bebas Biaya Admin',
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),

                // 4. Card Kode Perangkat & Konfirmasi Bukti Pembayaran
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'LANGKAH 2: KODE PERANGKAT & BUKTI BAYAR',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E3A8A),
                              letterSpacing: 0.5,
                            ),
                          ),
                          InkWell(
                            onTap: _copyDeviceId,
                            borderRadius: BorderRadius.circular(6.r),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 13.sp,
                                    color: const Color(0xFF1D4ED8),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Salin',
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _deviceId ?? 'Memuat ID Perangkat...',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 15.sp,
                              color: const Color(0xFFB45309),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'PENTING: Mohon kirimkan Kode Perangkat ini ke WhatsApp Admin beserta lampiran FOTO / SCREENSHOT BUKTI TRANSFER QRIS agar lisensi langsung dibuatkan.',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF92400E),
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
                      SizedBox(
                        width: double.infinity,
                        height: 42.h,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF059669),
                            side: const BorderSide(color: Color(0xFFA7F3D0)),
                            backgroundColor: const Color(0xFFECFDF5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          onPressed: _openWhatsApp,
                          icon: Icon(Icons.chat_rounded, size: 16.sp),
                          label: Text(
                            'Kirim Kode & Bukti Transfer ke Admin',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),

                // 5. Input Serial Key
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'LANGKAH 3: MASUKKAN SERIAL KEY RESMI',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E3A8A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                TextField(
                  controller: _keyController,
                  maxLines: 2,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.sp,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tempel serial key resmi (IDN-KEY-...) di sini',
                    hintStyle: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF94A3B8),
                      fontFamily: 'sans-serif',
                    ),
                    contentPadding: EdgeInsets.all(12.r),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(
                        color: Color(0xFF1D4ED8),
                        width: 1.5,
                      ),
                    ),
                    suffixIcon: IconButton(
                      tooltip: 'Tempel dari Clipboard',
                      icon: const Icon(
                        Icons.content_paste_rounded,
                        color: Color(0xFF1D4ED8),
                      ),
                      onPressed: _pasteFromClipboard,
                    ),
                  ),
                ),

                if (_errorMessage != null) ...[
                  SizedBox(height: 8.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 14.sp,
                        color: const Color(0xFFDC2626),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: const Color(0xFFDC2626),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 20.h),

                // 6. Tombol Aktivasi Utama
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: _isLoading ? null : _submitActivation,
                    child: _isLoading
                        ? SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_rounded, size: 18.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Aktivasi & Masuk ke Aplikasi',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
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
      ),
    );
  }
}
