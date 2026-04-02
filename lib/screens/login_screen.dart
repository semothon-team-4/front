import 'package:flutter/material.dart';
import '../widgets/clothes_up_logo.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _goSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _SignUpScreen()),
    );
  }

  Widget _linkText(String text, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                color: onTap != null
                    ? const Color(0xFF1A39FF)
                    : const Color(0xFF9E9E9E))),
      );

  Widget _dot() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Text('·',
            style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
      );

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
              ClothesUpLogo(
                width: MediaQuery.of(context).size.width * 0.52,
              ),
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
                  onPressed: _submit,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF8FEAFD),
                    foregroundColor: const Color(0xFF1D1B20),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    '로그인',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
        hintStyle:
            const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Text(text,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1D1B20))),
    );

// ════════════════════════════════════════════════════════════════
// 회원가입 화면 (Figma 229:1369)
// ════════════════════════════════════════════════════════════════
class _SignUpScreen extends StatefulWidget {
  const _SignUpScreen();

  @override
  State<_SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<_SignUpScreen> {
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
      _snack('이메일을 입력해주세요');
      return;
    }
    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+$')
        .hasMatch(_emailCtrl.text.trim())) {
      _snack('올바른 이메일 형식을 입력해주세요');
      return;
    }
    if (_idCtrl.text.trim().isEmpty) {
      _snack('아이디를 입력해주세요');
      return;
    }
    if (_pwCtrl.text.length < 6) {
      _snack('비밀번호는 6자 이상이어야 합니다');
      return;
    }
    if (!_agreed) {
      _snack('이용약관에 동의해주세요');
      return;
    }
    // 가입 완료 → 홈으로
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // 뒤로가기
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.arrow_back,
                      color: Color(0xFF1D1B20), size: 24),
                ),
              ),
              SizedBox(height: sw * 0.06),
              // 로고
              ClothesUpLogo(width: sw * 0.45),
              const SizedBox(height: 8),
              // 마스코트 원형 로고 영역 (seal 캐릭터 자리)
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8FEAFD).withValues(alpha: 0.25),
                ),
                child: const Icon(Icons.dry_cleaning_rounded,
                    size: 52, color: Color(0xFF8FEAFD)),
              ),
              const SizedBox(height: 28),

              // ── 이메일 ──
              _fieldLabel('이메일'),
              const SizedBox(height: 8),
              _Field(
                controller: _emailCtrl,
                hint: 'email address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              // ── 아이디 ──
              _fieldLabel('아이디'),
              const SizedBox(height: 8),
              _Field(
                controller: _idCtrl,
                hint: 'minju kim',
              ),
              const SizedBox(height: 14),

              // ── 비밀번호 ──
              _fieldLabel('비밀번호'),
              const SizedBox(height: 8),
              _Field(
                controller: _pwCtrl,
                hint: 'password',
                obscure: _obscurePw,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePw ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: const Color(0xFFB0BEC5),
                  ),
                  onPressed: () => setState(() => _obscurePw = !_obscurePw),
                ),
              ),
              const SizedBox(height: 20),

              // ── 소셜 로그인 구분선 ──
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('또는',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFFB0BEC5))),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                ],
              ),
              const SizedBox(height: 14),

              // ── 소셜 로그인 버튼 ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialBtn(
                    color: const Color(0xFFFEE500),
                    icon: Icons.chat_bubble_rounded,
                    iconColor: const Color(0xFF3C1E1E),
                    label: '카카오',
                    onTap: () => _snack('카카오 로그인 준비중입니다'),
                  ),
                  const SizedBox(width: 16),
                  _SocialBtn(
                    color: Colors.white,
                    icon: Icons.g_mobiledata_rounded,
                    iconColor: const Color(0xFF4285F4),
                    label: 'Google',
                    onTap: () => _snack('구글 로그인 준비중입니다'),
                    border: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── 이용약관 동의 ──
              GestureDetector(
                onTap: () => setState(() => _agreed = !_agreed),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color:
                            _agreed ? const Color(0xFF8FEAFD) : Colors.white,
                        border: Border.all(
                          color: _agreed
                              ? const Color(0xFF8FEAFD)
                              : const Color(0xFFE0E0E0),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _agreed
                          ? const Icon(Icons.check,
                              size: 12, color: Color(0xFF1D1B20))
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '이용약관 및 개인정보 처리방침에 동의합니다',
                        style: TextStyle(
                            fontSize: 10, color: Color(0xFF616161)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 회원가입 버튼 ──
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _submit,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF8FEAFD),
                    foregroundColor: const Color(0xFF1D1B20),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    '회원가입',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── 로그인 링크 ──
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E)),
                    children: [
                      TextSpan(text: '이미 계정이 있으신가요? '),
                      TextSpan(
                        text: '로그인',
                        style: TextStyle(
                          color: Color(0xFF1A39FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// 소셜 로그인 버튼
class _SocialBtn extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final bool border;

  const _SocialBtn({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: border
              ? Border.all(color: const Color(0xFFE0E0E0))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: iconColor)),
          ],
        ),
      ),
    );
  }
}

// 공용 텍스트 필드
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _Field({
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
        hintStyle:
            const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFF8FEAFD), width: 2),
        ),
      ),
    );
  }
}
