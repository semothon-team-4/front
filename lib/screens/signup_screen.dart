import 'package:flutter/material.dart';

import '../widgets/clothes_up_logo.dart';
import '../widgets/seal_mascot.dart';
import 'home_screen.dart';

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  void _submit() {
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

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
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
              SizedBox(height: screenWidth * 0.04),
              Align(
                alignment: Alignment.centerLeft,
                child: ClothesUpLogo(width: screenWidth * 0.48),
              ),
              const SizedBox(height: 14),
              const Center(
                child: SealMascot(
                  size: 92,
                  helpText: '반가워요!\n회원가입하고 클로즈업을 시작해보세요.',
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
              const _FieldLabel('이메일'),
              const SizedBox(height: 8),
              _SignUpField(
                controller: _emailCtrl,
                hint: 'email address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              const _FieldLabel('아이디'),
              const SizedBox(height: 8),
              _SignUpField(controller: _idCtrl, hint: 'minju kim'),
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
                  onPressed: _submit,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF8FEAFD),
                    foregroundColor: const Color(0xFF1D1B20),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: const Text(
                    '회원가입',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
