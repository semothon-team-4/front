import 'package:flutter/material.dart';

/// 피그마 기준 clothesUp 로고 이미지.
class ClothesUpLogo extends StatelessWidget {
  final double width;

  const ClothesUpLogo({super.key, this.width = 220});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_reference.png',
      width: width,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
    );
  }
}
