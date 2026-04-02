import 'package:flutter/material.dart';

class SealMascot extends StatefulWidget {
  final String helpText;
  final double size;

  const SealMascot({super.key, required this.helpText, this.size = 120});

  @override
  State<SealMascot> createState() => _SealMascotState();
}

class _SealMascotState extends State<SealMascot>
    with SingleTickerProviderStateMixin {
  bool _showHelp = false;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _bounceAnim = Tween<double>(begin: 0, end: -7).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _bounceController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showHelp = !_showHelp),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 말풍선
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              alignment: Alignment.bottomCenter,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: _showHelp
                ? Container(
                    key: const ValueKey('bubble'),
                    constraints: const BoxConstraints(maxWidth: 185),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A39FF),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A39FF)
                              .withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.helpText,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        CustomPaint(
                          size: const Size(12, 6),
                          painter: _BubbleTailPainter(),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(key: ValueKey('empty'), height: 0),
          ),
          // Figma 마스코트 이미지 (바운스 애니메이션)
          AnimatedBuilder(
            animation: _bounceController,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _bounceAnim.value),
              child: child,
            ),
            // Transform.scale로 줌인 → PNG 주변 여백을 잘라내고 마스코트를 크게 표시
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Transform.scale(
                scale: 2.2,
                child: Image.asset(
                  'assets/images/mascot.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1A39FF);
    final path = Path()
      ..moveTo(size.width / 2 - 5, 0)
      ..lineTo(size.width / 2 + 5, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
