import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common_widgets/custom_text_field.dart';
import '../../dashboard/presentation/dashboard_page.dart';
import 'auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const _prefNimKey = 'saved_nim';
  static const _prefPasswordKey = 'saved_password';

  final _formKey = GlobalKey<FormState>();
  final _nimController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNim = prefs.getString(_prefNimKey) ?? '';
      final savedPassword = prefs.getString(_prefPasswordKey) ?? '';

      if (mounted) {
        if (savedNim.isNotEmpty) _nimController.text = savedNim;
        if (savedPassword.isNotEmpty) _passwordController.text = savedPassword;
      }
    } catch (_) {}
  }

  Future<void> _saveCredentials(String nim, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefNimKey, nim);
      await prefs.setString(_prefPasswordKey, password);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(authControllerProvider.notifier)
        .login(
          nim: _nimController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Listen navigasi & error
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.isAuthenticated) {
        // Simpan ke autofill native OS (Google / Keychain) & local prefs
        TextInput.finishAutofillContext(shouldSave: true);
        _saveCredentials(_nimController.text.trim(), _passwordController.text);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.redAccent,
            ),
          );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Masuk',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22.sp,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Selamat datang kembali! Silakan masuk ke akun Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF667085),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 28.h),

                    // Username / NIM field
                    CustomTextField(
                      controller: _nimController,
                      label: 'Username / NIM',
                      hintText: 'Masukkan username atau NIM',
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: const Color(0xFF667085),
                        size: 18.r,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Username / NIM wajib diisi'
                          : null,
                    ),
                    SizedBox(height: 16.h),

                    // Password field
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Kata Sandi',
                      hintText: 'Masukkan kata sandi',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        color: const Color(0xFF667085),
                        size: 18.r,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF667085),
                          size: 18.r,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Kata sandi wajib diisi'
                          : null,
                    ),
                    SizedBox(height: 28.h),

                    // Tombol Masuk
                    SizedBox(
                      width: double.infinity,
                      height: 46.h,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1F81FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        onPressed: authState.isLoading ? null : _submit,
                        child: authState.isLoading
                            ? SizedBox(
                                width: 20.r,
                                height: 20.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Masuk',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
