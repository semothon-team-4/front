import 'package:flutter/material.dart';

import '../widgets/clothes_up_logo.dart';
import 'login_screen.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    (
      title: '주변 세탁소 / 수선집\n가격 비교',
      description: '영수증 리뷰 기반으로\n실제 가격을 투명하게 비교해요',
      icon: Icons.local_laundry_service_rounded,
      accent: Color(0xFFE3F8FF),
    ),
    (
      title: '케어라벨 스캔으로\n세탁 방법을 빠르게 확인해요',
      description: '옷의 세탁 기호를 읽고 관리법을 정리해서,\n헷갈리지 않게 도와줘요.',
      icon: Icons.qr_code_scanner_rounded,
      accent: Color(0xFFE8F9FF),
    ),
    (
      title: '의류 상태를 분석하고\n옷장에 저장할 수 있어요',
      description: '오염도와 손상도를 보고 지금 내 옷 상태를\n직관적으로 확인할 수 있어요.',
      icon: Icons.checkroom_rounded,
      accent: Color(0xFFEAFBF2),
    ),
    (
      title: '커뮤니티에서 정보 공유하고\n다른 사람 프로필도 볼 수 있어요',
      description: '후기와 세탁 팁을 나누고,\n저장한 매장 리스트까지 함께 살펴보세요.',
      icon: Icons.groups_rounded,
      accent: Color(0xFFFFF6DE),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage == _pages.length - 1) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _skip() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Center(child: ClothesUpLogo(width: 132)),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxHeight < 620;
                        return Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              child: Column(
                                children: [
                                  SizedBox(height: isCompact ? 42 : 64),
                                  Container(
                                    width: isCompact ? 112 : 126,
                                    height: isCompact ? 112 : 126,
                                    decoration: BoxDecoration(
                                      color: page.accent,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Icon(
                                      page.icon,
                                      size: isCompact ? 52 : 58,
                                      color: const Color(0xFF8EDDF4),
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 24 : 30),
                                  Text(
                                    page.title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isCompact ? 21 : 23,
                                      height: 1.4,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1D1B20),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    page.description,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isCompact ? 14 : 15,
                                      height: 1.55,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6E6E6E),
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 10 : 14),
                                  Align(
                                    alignment: const Alignment(1.08, 0),
                                    child: Transform.translate(
                                      offset: Offset(
                                        isCompact ? 26 : 34,
                                        isCompact ? -6 : -10,
                                      ),
                                      child: Image.asset(
                                        'assets/images/tutorial_mascot_wave.png',
                                        width: isCompact ? 154 : 186,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 0 : 2),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF1A39FF)
                              : const Color(0xFFD0D7DE),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _goNext,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF8FEAFD),
                        foregroundColor: const Color(0xFF1D1B20),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? '시작하기' : '다음',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _skip,
                    child: const Text(
                      '건너뛰기',
                      style: TextStyle(
                        color: Color(0xFF9A9A9A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
