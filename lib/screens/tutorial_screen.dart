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
      title: ' 세탁소 / 수선집\n가격 비교',
      description: '영수증 기반 리뷰와 매장별 best 3를 \n 한눈에 볼 수 있어요. ',
      icon: Icons.local_laundry_service_rounded,
      accent: Color(0xFFE3F8FF),
    ),
    (
      title: '택 스캔으로\n세탁 법 확인',
      description: '카메라로 세탁 택을 찍으면 \nAI가 기호를 바로 분석해드려요.',
      icon: Icons.qr_code_scanner_rounded,
      accent: Color(0xFFE8F9FF),
    ),
    (
      title: '의류 상태\n A-D 등급 진단',
      description: '옷을 스캔하면 세탁 기호와 함께\n손상 위험도를 등급으로 알려드려요.',
      icon: Icons.checkroom_rounded,
      accent: Color(0xFFEAFBF2),
    ),
    (
      title: '커뮤니티에서 \n경험 나누기',
      description: '자유롭게 글을 올리거나\n진단 결과를 공유하고 조언을 받아보세요.',
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

  Widget _buildDefaultPage(
    ({Color accent, String description, IconData icon, String title}) page,
    BoxConstraints constraints,
  ) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: constraints.maxWidth,
          child: Column(
            children: [
              const SizedBox(height: 76),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F8FF),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Icon(
                  page.icon,
                  size: 54,
                  color: const Color(0xFF8EDDF4),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  height: 1.38,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                page.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6E6E6E),
                ),
              ),
              const SizedBox(height: 34),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastPage(
    ({Color accent, String description, IconData icon, String title}) page,
    BoxConstraints constraints,
  ) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: constraints.maxWidth,
          child: Column(
            children: [
              const SizedBox(height: 76),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F8FF),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  size: 50,
                  color: Color(0xFF8EDDF4),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  height: 1.38,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                page.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6E6E6E),
                ),
              ),
              const SizedBox(height: 34),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultBottomControls() {
    return SizedBox(
      height: 194,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            child: Row(
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
          ),
          Positioned(
            top: 98,
            left: 34,
            right: 34,
            child: SizedBox(
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
                child: const Text(
                  '다음',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          Positioned(
            top: 148,
            child: TextButton(
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
          ),
        ],
      ),
    );
  }

  Widget _buildLastBottomControls() {
    return SizedBox(
      height: 194,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 0,
            child: Row(
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
          ),
          Positioned(
            top: 22,
            child: Container(
              width: 108,
              height: 94,
              alignment: Alignment.bottomCenter,
              color: Colors.white,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRect(
                      child: Transform.translate(
                        offset: const Offset(-4, 8),
                        child: Image.asset(
                          'assets/images/tutorial_last_mascot.png',
                          width: 112,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 9,
                    child: Container(color: Colors.white),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    width: 5,
                    bottom: 0,
                    child: Container(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 102,
            left: 34,
            right: 34,
            child: SizedBox(
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
                  minimumSize: const Size.fromHeight(0),
                ),
                child: const Text(
                  '시작하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
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
                        final isLastPage = index == _pages.length - 1;
                        return isLastPage
                            ? _buildLastPage(page, constraints)
                            : _buildDefaultPage(page, constraints);
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 18),
              child: _currentPage == _pages.length - 1
                  ? _buildLastBottomControls()
                  : _buildDefaultBottomControls(),
            ),
          ],
        ),
      ),
    );
  }
}
