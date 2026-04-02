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
      title: '동네 세탁소와 수선집을\n한눈에 비교해요',
      description: '지도에서 가까운 매장을 확인하고,\n하트로 저장한 곳도 바로 모아볼 수 있어요.',
      icon: Icons.location_on_rounded,
      accent: Color(0xFF1A39FF),
    ),
    (
      title: '케어라벨 스캔으로\n세탁 방법을 빠르게 확인해요',
      description: '옷의 세탁 기호를 읽고 관리법을 정리해서,\n헷갈리지 않게 도와줘요.',
      icon: Icons.qr_code_scanner_rounded,
      accent: Color(0xFF00A3BF),
    ),
    (
      title: '의류 상태를 분석하고\n옷장에 저장할 수 있어요',
      description: '오염도와 손상도를 보고 지금 내 옷 상태를\n직관적으로 확인할 수 있어요.',
      icon: Icons.checkroom_rounded,
      accent: Color(0xFF43A047),
    ),
    (
      title: '커뮤니티에서 정보 공유하고\n다른 사람 프로필도 볼 수 있어요',
      description: '후기와 세탁 팁을 나누고,\n저장한 매장 리스트까지 함께 살펴보세요.',
      icon: Icons.groups_rounded,
      accent: Color(0xFFFFB300),
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
      backgroundColor: const Color(0xFFF8FDFF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  ClothesUpLogo(width: 120),
                  const Spacer(),
                  TextButton(
                    onPressed: _skip,
                    child: const Text(
                      '건너뛰기',
                      style: TextStyle(
                        color: Color(0xFF7A8793),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  final pageHeight = MediaQuery.of(context).size.height;
                  final isCompact = pageHeight < 760;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SizedBox.expand(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: constraints.maxWidth,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: isCompact ? 8 : 24),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.fromLTRB(
                                        28,
                                        isCompact ? 20 : 28,
                                        28,
                                        isCompact ? 16 : 28,
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: isCompact ? 104 : 120,
                                            height: isCompact ? 104 : 120,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.88,
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: page.accent.withValues(
                                                    alpha: 0.16,
                                                  ),
                                                  blurRadius: 24,
                                                  offset: const Offset(0, 12),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              page.icon,
                                              size: isCompact ? 48 : 56,
                                              color: page.accent,
                                            ),
                                          ),
                                          SizedBox(height: isCompact ? 24 : 36),
                                          Text(
                                            page.title,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: isCompact ? 24 : 28,
                                              height: 1.3,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF1D1B20),
                                            ),
                                          ),
                                          SizedBox(height: isCompact ? 14 : 18),
                                          Text(
                                            page.description,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: isCompact ? 14 : 15,
                                              height: 1.7,
                                              color: const Color(0xFF5E6B76),
                                            ),
                                          ),
                                          SizedBox(height: isCompact ? 16 : 28),
                                          Align(
                                            alignment: const Alignment(1.6, 0.1),
                                            child: Image.asset(
                                              'assets/images/tutorial_mascot_wave.png',
                                              width: isCompact ? 104 : 124,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
                  const SizedBox(height: 22),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
