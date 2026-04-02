import 'package:flutter/material.dart';

/// clothesUp 로고 — "clothes"(텍스트) + "Up"(텍스트) + tshirt.png 오버레이
/// 피그마 화면1처럼 티셔츠가 "Up" 바로 위에 붙어있는 형태
class ClothesUpLogo extends StatelessWidget {
  /// 로고 전체 너비 기준 (fontSize는 자동 계산)
  final double width;

  const ClothesUpLogo({super.key, this.width = 220});

  @override
  Widget build(BuildContext context) {
    final fontSize = width * 0.175;
    final tshirtSize = fontSize * 0.95;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // "clothes" 텍스트
        Text(
          'clothes',
          style: TextStyle(
            color: const Color(0xFF0D1B4F),
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        // "Up" + 티셔츠 오버레이
        Stack(
          clipBehavior: Clip.none,
          children: [
            // 티셔츠 PNG — "Up" 바로 위에 배치
            Positioned(
              bottom: fontSize * 0.85,
              left: fontSize * 0.05,
              child: Image.asset(
                'assets/images/tshirt.png',
                width: tshirtSize,
                height: tshirtSize,
                fit: BoxFit.contain,
              ),
            ),
            // "Up" 텍스트
            Text(
              'Up',
              style: TextStyle(
                color: const Color(0xFF8FEAFD),
                fontSize: fontSize,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
