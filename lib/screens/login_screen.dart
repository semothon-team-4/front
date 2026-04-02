import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/clothes_up_logo.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      _showSnack('이메일과 비밀번호를 입력해주세요');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthService.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _goSignUp() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SignUpScreen()));
  }

  Widget _linkText(String text, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: onTap != null
            ? const Color(0xFF1A39FF)
            : const Color(0xFF9E9E9E),
      ),
    ),
  );

  Widget _dot() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 6),
    child: Text('·', style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
  );

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.12),
              ClothesUpLogo(width: MediaQuery.of(context).size.width * 0.52),
              const SizedBox(height: 32),
              const Text(
                '클로즈업에 오신 것을 환영합니다!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 40),
              // 이메일
              _fieldLabel('이메일'),
              const SizedBox(height: 8),
              _inputField(
                controller: _emailCtrl,
                hint: 'email address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // 비밀번호
              _fieldLabel('비밀번호'),
              const SizedBox(height: 8),
              _inputField(
                controller: _passwordCtrl,
                hint: 'password',
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: const Color(0xFFB0BEC5),
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 32),
              // 로그인 버튼
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF8FEAFD),
                    foregroundColor: const Color(0xFF1D1B20),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1D1B20),
                          ),
                        )
                      : const Text(
                          '로그인',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // 아이디 찾기 · 비밀번호 찾기 · 회원가입
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _linkText('아이디 찾기', null),
                  _dot(),
                  _linkText('비밀번호 찾기', null),
                  _dot(),
                  _linkText('회원가입', _goSignUp),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF8FEAFD), width: 2),
        ),
      ),
    );
  }
}

Widget _fieldLabel(String text) => Align(
  alignment: Alignment.centerLeft,
  child: Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Color(0xFF1D1B20),
    ),
  ),
);
