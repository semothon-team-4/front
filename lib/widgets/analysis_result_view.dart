import 'dart:io';
import 'package:flutter/material.dart';

// --- 분석 결과 위젯 (케어라벨 & 의류 공용) ---
class AnalysisResultView extends StatelessWidget {
  final File? image;
  final bool isCareLabel;
  final Map<String, dynamic>? analysisResult;
  final bool showRegisterButton;
  final ValueChanged<int>? onNavigate;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onReset;
  final VoidCallback onStartClothingScan;

  const AnalysisResultView({
    super.key,
    required this.image,
    required this.isCareLabel,
    required this.analysisResult,
    this.showRegisterButton = true,
    this.onNavigate,
    required this.onBack,
    required this.onSave,
    required this.onReset,
    required this.onStartClothingScan,
  });

  // 케어라벨 항목: (아이콘, 제목, 설명)
  static const _careItems = [
    (
      'assets/images/laundry_symbol_water_temperature_not_above_30.png',
      '세탁기 사용 가능',
      '30°C 이하의 미지근한 물에서 세탁기 사용 가능',
    ),
    (
      'assets/images/laundry_symbol_do_not_bleach.png',
      '표백제 사용 불가',
      '염소계 표백제 사용 금지',
    ),
    (
      'assets/images/laundry_symbol_mild_drying_processes.png',
      '건조기 사용 가능',
      '저온 건조 가능',
    ),
    (
      'assets/images/laundry_symbol_do_not_iron.png',
      '다리미 사용 불가',
      '열 손상 주의',
    ),
    (
      'assets/images/laundry_symbol_do_not_dry_clean.png',
      '드라이클리닝 금지',
      '물세탁 방법으로만 세탁',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return isCareLabel
        ? _buildCareLabelResult(context)
        : _buildClothingResult(context);
  }

  // -- 케어라벨 스캔 결과 --
  Widget _buildCareLabelResult(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  const Spacer(),
                  const Text(
                    '분석 결과✨',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF1D1B20)),
                    onPressed: onReset,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: image != null
                              ? Image.file(
                                  image!,
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: double.infinity,
                                  height: 180,
                                  color: const Color(0xFFE8F4FD),
                                  child: const Center(
                                    child: Icon(
                                      Icons.dry_cleaning,
                                      color: Color(0xFF8FEAFD),
                                      size: 60,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFDCF9FF), width: 1.5),
                      ),
                      child: Column(
                        children: List.generate(_careItems.length, (index) {
                          final item = _careItems[index];
                          return Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      item.$1,
                                      width: 26,
                                      height: 26,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        item.$2,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A39FF),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (index < _careItems.length - 1)
                                const Divider(
                                    height: 1, color: Color(0xFFEEEEEE)),
                            ],
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4F8FF),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x0F000000),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/images/TShirt_icon.png',
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A39FF),
                                        borderRadius:
                                            BorderRadius.circular(100),
                                      ),
                                      child: const Text(
                                        '선택사항',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      '의류 전체를 촬영하면',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1D1B20),
                                        height: 1.2,
                                      ),
                                    ),
                                    const Text(
                                      '더 정확한 관리법을 알려드려요!',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A39FF),
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: const Center(
                              child: Text(
                                '소재/오염도/손상도까지 분석 가능',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF5D7A8A),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ResultActionButton(
                      label: '의류 스캔하기',
                      icon: Icons.arrow_forward,
                      onTap: onStartClothingScan,
                      isPrimary: true,
                    ),
                    const SizedBox(height: 16),
                    showRegisterButton
                        ? Row(
                            children: [
                              Expanded(
                                child: ResultActionButton(
                                  label: '이미지 저장하기',
                                  icon: Icons.download_outlined,
                                  onTap: onReset,
                                  isPrimary: false,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ResultActionButton(
                                  label: '내 옷장에 등록하기',
                                  onTap: onSave,
                                  isPrimary: false,
                                ),
                              ),
                            ],
                          )
                        : ResultActionButton(
                            label: '이미지 저장하기',
                            icon: Icons.download_outlined,
                            onTap: onReset,
                            isPrimary: false,
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- 의류 스캔 결과 --
  Widget _buildClothingResult(BuildContext context) {
    final result = analysisResult ?? const <String, dynamic>{};
    final grade = (result['grade'] as String?)?.toUpperCase() ?? 'B';
    final stainLevel = ((result['stainLevel'] as num?) ?? 10).toInt().clamp(0, 100);
    final damageLevel = ((result['damageLevel'] as num?) ?? 40).toInt().clamp(0, 100);
    final title = (result['name'] as String?)?.trim().isNotEmpty == true
        ? result['name'] as String
        : '스캔한 의류';
    final category = (result['category'] as String?)?.trim().isNotEmpty == true
        ? result['category'] as String
        : '기타';
    final recommendation =
        (result['recommendation'] as String?)?.trim().isNotEmpty == true
            ? result['recommendation'] as String
            : '기본적인 관리는 가능하지만 일부 주의가 필요해요.';
    final careLabels = ((result['careLabels'] as List?) ?? const [])
        .map((label) => Map<String, dynamic>.from(label as Map))
        .toList();
    final subtitle = careLabels.isEmpty
        ? '$title · $category'
        : '$title · ${careLabels.map((label) => label['name']).join(' / ')}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1D1B20)),
                    onPressed: onBack,
                  ),
                  const Spacer(),
                  const Text(
                    '분석 결과',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: image != null
                          ? Image.file(
                              image!,
                              width: 219,
                              height: 292,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 219,
                              height: 292,
                              color: const Color(0xFFF0F7FA),
                              child: const Center(
                                child: Icon(
                                  Icons.checkroom,
                                  color: Color(0xFF8FEAFD),
                                  size: 60,
                                ),
                               ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7B7B7B),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCF9FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '내 옷의 등급은?',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1D1B20),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ClothingMetricRow(
                                      label: '오염도',
                                      value: stainLevel / 100,
                                      color: const Color(0xFF98DA9A),
                                      valueLabel: '$stainLevel%',
                                    ),
                                    const SizedBox(height: 14),
                                    ClothingMetricRow(
                                      label: '손상도',
                                      value: damageLevel / 100,
                                      color: const Color(0xFFB73D3D),
                                      valueLabel: '$damageLevel%',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF8FEAFD),
                                    width: 2.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      grade,
                                      style: const TextStyle(
                                        fontSize: 54,
                                        fontWeight: FontWeight.w300,
                                        height: 0.95,
                                        color: Color(0xFFF5B38A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      '등급',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      recommendation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF555555),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '등급은 세탁 기호와 의류 상태를 함께 분석하여,\n잘못된 관리로 인한 손상 위험도를 등급으로 안내합니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.5,
                        color: Color(0xFF9A9A9A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => _showGradeInfo(context),
                        child: const Column(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: Color(0xFF777777)),
                            SizedBox(height: 2),
                            Text('등급 기준', style: TextStyle(fontSize: 9, color: Color(0xFF777777))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // 하단 버튼 구성
                    Row(
                      children: [
                        Expanded(
                          child: ResultActionButton(
                            label: '이미지 저장하기',
                            icon: Icons.download_outlined,
                            onTap: onReset,
                            isPrimary: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: ResultActionButton(
                            label: '커뮤니티로 공유하기',
                            icon: Icons.share_outlined,
                            onTap: null, // 추후 기능 연결
                            isPrimary: false,
                          ),
                        ),
                      ],
                    ),
                    if (showRegisterButton) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: SizedBox(
                          width: 148,
                          child: ResultActionButton(
                            label: '내 옷장에 등록하기',
                            onTap: onSave,
                            isPrimary: true,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGradeInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('등급 기준', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text(
          'A등급: 일반적인 세탁과 관리로도 손상 위험이 낮아요.\n'
          'B등급: 기본적인 관리는 가능하지만 일부 주의가 필요해요.\n'
          'C등급: 세탁 방법이나 건조 방식에 따라 손상될 수 있어요.\n'
          'D등급: 손상될 위험이 높아 세심한 관리가 필요해요.',
          style: TextStyle(fontSize: 13, color: Color(0xFF1A39FF), height: 1.7),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
        ],
      ),
    );
  }
}

// -- 하위 컴포넌트들 --
class ResultActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final IconData? icon;

  const ResultActionButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.isPrimary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 49,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF8FEAFD) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF8FEAFD), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: const Color(0xFF1D1B20)),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isPrimary ? 14 : 13,
                  fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                  color: const Color(0xFF1D1B20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClothingMetricRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String valueLabel;

  const ClothingMetricRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(height: 8, color: const Color(0xFFE8E5E5)),
                FractionallySizedBox(
                  widthFactor: value,
                  child: Container(height: 8, color: color),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          valueLabel,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7A7A7A),
          ),
        ),
      ],
    );
  }
}

class ClothingPreview extends StatelessWidget {
  final String imageUrl;
  final Color iconColor;
  final double iconSize;
  final BorderRadius? borderRadius;

  const ClothingPreview({
    super.key,
    required this.imageUrl,
    required this.iconColor,
    this.iconSize = 48,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.network(imageUrl, fit: BoxFit.cover),
      );
    } else if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.file(File(imageUrl), fit: BoxFit.cover),
      );
    }
    return Center(
      child: Icon(Icons.checkroom, size: iconSize, color: iconColor),
    );
  }
}
