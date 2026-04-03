import 'dart:io';

import 'package:flutter/material.dart';

class MascotProfileAvatar extends StatelessWidget {
  final double size;
  final File? imageFile;
  final double? borderWidth;
  final Color backgroundColor;
  final Color? borderColor;

  const MascotProfileAvatar({
    super.key,
    required this.size,
    this.imageFile,
    this.borderWidth,
    this.backgroundColor = const Color(0xFFDBF4F9),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth ?? 1.5)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageFile != null
          ? Image.file(imageFile!, fit: BoxFit.cover)
          : Transform.scale(
              scale: 1.24,
              child: Image.asset(
                'assets/images/profile_default.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
    );
  }
}
