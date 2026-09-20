import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../services/lms_api_service.dart';
import '../../auth/presentation/login_page.dart';
import '../../dashboard/presentation/dashboard_page.dart';
import '../../license/application/license_service.dart';
import '../../license/presentation/activation_page.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSessionAndNavigate();
    });
  }

  Future<void> _checkSessionAndNavigate() async {
    final delayFuture = Future.delayed(const Duration(milliseconds: 1200));

    // 1. Cek Gerbang Lisensi Hardware (100% Full-App Gatekeeper)
    final isLicensed = await ref.read(licenseServiceProvider).isLicenseActive();

    final apiService = ref.read(lmsApiServiceProvider);
    bool isAuthenticated = false;

    if (isLicensed) {
      try {
        final hasSession = await apiService.hasActiveSession();
        if (hasSession) {
          isAuthenticated = await apiService.validateSessionWithServer();
        }
      } catch (e) {
        debugPrint('[SplashPage] Gagal memvalidasi sesi aktif: $e');
      }
    }

    await delayFuture;

    if (!mounted) return;

    // Jika belum aktivasi lisensi hardware, paksa masuk ke halaman aktivasi pertama
    final Widget targetPage;
    if (!isLicensed) {
      targetPage = const ActivationPage();
    } else if (isAuthenticated) {
      targetPage = const DashboardPage();
    } else {
      targetPage = const LoginPage();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetPage,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SvgPicture.asset(
          'assets/icon/idn_ic.svg',
          width: 48.w,
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(
            Color(0xFF1F81FF),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
