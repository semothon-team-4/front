import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/clothes_up_logo.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _obscurePw = true;
  bool _agreed = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _showSnack('이메일을 입력해주세요');
      return;
    }
    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+$').hasMatch(_emailCtrl.text.trim())) {
      _showSnack('올바른 이메일 형식을 입력해주세요');
      return;
    }
    if (_idCtrl.text.trim().isEmpty) {
      _showSnack('아이디를 입력해주세요');
      return;
    }
    if (_pwCtrl.text.length < 6) {
      _showSnack('비밀번호는 6자 이상이어야 합니다');
      return;
    }
    if (!_agreed) {
      _showSnack('이용약관에 동의해주세요');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthService.signUp(
        email: _emailCtrl.text.trim(),
        password: _pwCtrl.text,
        nickname: _idCtrl.text.trim(),
      );
      if (!mounted) return;
      _showSnack('회원가입이 완료되었습니다. 로그인해주세요.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF7F9FC),
                    minimumSize: const Size(44, 44),
                  ),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Color(0xFF1D1B20),
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.05),
              Center(child: ClothesUpLogo(width: screenWidth * 0.34)),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 132,
                  height: 132,
                  child: ClipOval(
                    child: Transform.scale(
                      scale: 1.4,
                      child: Image.asset(
                        'assets/images/signup_mascot.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                '회원가입',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '이메일과 비밀번호만 입력하면 바로 시작할 수 있도록 깔끔하게 정리했어요.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 32),
              const _FieldLabel('아이디'),
              const SizedBox(height: 8),
              _SignUpField(controller: _idCtrl, hint: '영통세탁왕'),
              const SizedBox(height: 18),
              const _FieldLabel('이메일'),
              const SizedBox(height: 8),
              _SignUpField(
                controller: _emailCtrl,
                hint: 'abc@naver.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              const _FieldLabel('비밀번호'),
              const SizedBox(height: 8),
              _SignUpField(
                controller: _pwCtrl,
                hint: 'password',
                obscure: _obscurePw,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscurePw = !_obscurePw),
                  icon: Icon(
                    _obscurePw
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: const Color(0xFF9AA4B2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              InkWell(
                onTap: () => setState(() => _agreed = !_agreed),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FBFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _agreed
                          ? const Color(0xFF8FEAFD)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _agreed
                              ? const Color(0xFF8FEAFD)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _agreed
                                ? const Color(0xFF8FEAFD)
                                : const Color(0xFFD1D5DB),
                            width: 1.4,
                          ),
                        ),
                        child: _agreed
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Color(0xFF1D1B20),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '이용약관 및 개인정보 처리방침에 동의합니다',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF8FEAFD),
                    foregroundColor: const Color(0xFF1D1B20),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
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
                          '회원가입',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Center(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      children: [
                        TextSpan(text: '이미 계정이 있으신가요? '),
                        TextSpan(
                          text: '로그인',
                          style: TextStyle(
                            color: Color(0xFF1A39FF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
    );
  }
}

class _SignUpField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _SignUpField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF9FBFD),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF8FEAFD), width: 2),
        ),
      ),
    );
  }
}
