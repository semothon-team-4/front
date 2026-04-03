import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

typedef SaveWardrobeCallback =
    Future<void> Function({required String name, required String category});

// --- 분석 결과 위젯 (케어라벨 & 의류 공용) ---
class AnalysisResultView extends StatelessWidget {
  final File? image;
  final bool isCareLabel;
  final Map<String, dynamic>? analysisResult;
  final bool showRegisterButton;
  final ValueChanged<int>? onNavigate;
  final VoidCallback onBack;
  final SaveWardrobeCallback onSave;
  final VoidCallback onReset;
  final VoidCallback onSaveImage; // 이미지 저장 전용 콜백 추가
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
    required this.onSaveImage, // 추가
    required this.onStartClothingScan,
  });

  // 케어라벨 항목 데이터 (아이콘, 제목, 설명)
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
    ('assets/images/laundry_symbol_do_not_iron.png', '다리미 사용 불가', '열 손상 주의'),
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

  Widget _buildResultImage({
    required double width,
    required double height,
    required IconData fallbackIcon,
    required Color fallbackColor,
    required Color fallbackIconColor,
  }) {
    if (image != null) {
      return Image.file(
        image!,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }

    final result = analysisResult ?? const <String, dynamic>{};
    final rawImageUrl = (result['imageUrl'] as String?)?.trim() ?? '';
    final rawImagePath = (result['imagePath'] as String?)?.trim() ?? '';
    final localFile = rawImagePath.isNotEmpty ? File(rawImagePath) : null;
    final hasLocalImage = localFile != null && localFile.existsSync();

    if (hasLocalImage) {
      return Image.file(
        localFile,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }

    if (rawImageUrl.isNotEmpty) {
      return Image.network(
        rawImageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: width,
          height: height,
          color: fallbackColor,
          child: Center(
            child: Icon(
              fallbackIcon,
              color: fallbackIconColor,
              size: 70,
            ),
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      color: fallbackColor,
      child: Center(
        child: Icon(
          fallbackIcon,
          color: fallbackIconColor,
          size: 70,
        ),
      ),
    );
  }

  // ──── 케어라벨 스캔 결과 ──────────────────────────
  Widget _buildCareLabelResult(BuildContext context) {
    final result = analysisResult ?? const <String, dynamic>{};
    final labels = ((result['careLabels'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '분석 결과✨',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1B20),
          ),
        ),
        leading: const SizedBox(width: 48),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF1D1B20)),
            onPressed: onReset,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFDCF9FF),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: List.generate(
                    labels.isNotEmpty ? labels.length : _careItems.length,
                    (index) {
                      final item = _careItems[index];
                      final rawItem = labels.isNotEmpty ? labels[index] : null;
                      final title =
                          (rawItem?['desc'] as String?)?.trim().isNotEmpty ==
                              true
                          ? rawItem!['desc'] as String
                          : item.$2;
                      final iconB64 = (rawItem?['iconB64'] as String?)?.trim();
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                _CareLabelIcon(iconB64: iconB64),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    title,
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
                          if (index <
                              (labels.isNotEmpty
                                      ? labels.length
                                      : _careItems.length) -
                                  1)
                            const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        ],
                      );
                    },
                  ),
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
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A39FF),
                                  borderRadius: BorderRadius.circular(100),
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
              const SizedBox(height: 24),
              ResultActionButton(
                label: '의류 스캔하기',
                icon: Icons.arrow_forward,
                onTap: onStartClothingScan,
                isPrimary: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: ResultActionButton(
                      label: '이미지 저장하기',
                      icon: Icons.download_outlined,
                      onTap: null,
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ResultActionButton(
                      label: '내 옷장에 등록하기',
                      onTap: () => _showWardrobeSaveDialog(
                        context,
                        initialName: '스캔한 의류',
                        initialCategory: '상의',
                      ),
                      isPrimary: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ──── 의류 스캔 결과 ──────────────────────────
  Widget _buildClothingResult(BuildContext context) {
    final result = analysisResult ?? const <String, dynamic>{};
    final grade = (result['grade'] as String?)?.toUpperCase() ?? 'B';
    final stainLevel = ((result['stainLevel'] as num?) ?? 10).toInt().clamp(
      0,
      100,
    );
    final damageLevel = ((result['damageLevel'] as num?) ?? 40).toInt().clamp(
      0,
      100,
    );
    final title = (result['name'] as String?)?.trim().isNotEmpty == true
        ? result['name'] as String
        : '스캔한 의류';
    final category = (result['category'] as String?)?.trim().isNotEmpty == true
        ? result['category'] as String
        : '면 / 폴리에스테르';
    final recommendation =
        (result['recommendation'] as String?)?.trim().isNotEmpty == true
        ? result['recommendation'] as String
        : '분석 결과 기본적인 관리는 가능하지만 일부 주의가 필요해요.';

    // 등급별 가이드 로직
    final String guideTitle =
        (result['guideTitle'] as String?) ??
        '전반적으로 양호한 상태예요. 현재 상태 그대로 보관해 보세요.';
    final String guideTip =
        (result['guideTip'] as String?) ??
        '의류의 형태를 유지하기 위해 통풍이 잘 되는 곳에 보관해 주세요.';
    final isGoodGrade = grade == 'A';
    final displayedGuideStatusLabel = isGoodGrade ? '관리 불필요' : '관리 필요';
    final displayedGuideTitle = isGoodGrade
        ? '옷 상태가 매우 좋아요. 현재 상태 그대로 보관하면 오래 입을 수 있어요.'
        : '옷 상태가 매우 좋지 않아요. 현재 상태 그대로 보관하면 오래 입을 수 없어요.';

    // 등급별 컬러링
    final gradeColor = switch (grade) {
      'A' => const Color(0xFF4CAF50),
      'B' => const Color(0xFFF5B38A),
      'C' => const Color(0xFFFFA000),
      _ => const Color(0xFFC62828),
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '분석 결과',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D1B20),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1D1B20)),
          onPressed: onBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildResultImage(
                  width: double.infinity,
                  height: 260,
                  fallbackIcon: Icons.checkroom,
                  fallbackColor: const Color(0xFFF8FAFF),
                  fallbackIconColor: const Color(0xFFCFD8DC),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$title · $category',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF455A64),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5FE).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '내 옷의 등급은?',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF263238),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                ClothingMetricRow(
                                  label: '오염도',
                                  value: stainLevel / 100,
                                  color: const Color(0xFF81C784),
                                  valueLabel: '$stainLevel%',
                                ),
                                const SizedBox(height: 18),
                                ClothingMetricRow(
                                  label: '손상도',
                                  value: damageLevel / 100,
                                  color: const Color(0xFFC62828),
                                  valueLabel: '$damageLevel%',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 2,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 132,
                                    height: 132,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.92),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.06,
                                          ),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          grade,
                                          style: TextStyle(
                                            fontSize: 68,
                                            fontWeight: FontWeight.bold,
                                            color: gradeColor.withValues(
                                              alpha: 0.8,
                                            ),
                                            height: 0.85,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          '등급',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF546E7A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      recommendation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF37474F),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _showGradeInfo(context),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '어떻게 판단했나요?',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF90A4AE),
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Color(0xFF90A4AE),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7F3FB),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('💡', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 8),
                        Text(
                          '관리 가이드',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGoodGrade ? Icons.check : Icons.warning_amber_rounded,
                            size: 18,
                            color: isGoodGrade
                                ? const Color(0xFF10B981)
                                : const Color(0xFFE53935),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            displayedGuideStatusLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isGoodGrade
                                  ? const Color(0xFF333333)
                                  : const Color(0xFF2D2D2D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayedGuideTitle.isNotEmpty
                          ? displayedGuideTitle
                          : guideTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.favorite,
                                size: 18,
                                color: Color(0xFFFF5A5F),
                              ),
                              SizedBox(width: 6),
                              Text(
                                '보관 팁',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            guideTip,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF444444),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ResultActionButton(
                      label: '이미지 저장하기',
                      icon: Icons.download_outlined,
                      onTap: onSaveImage,
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: ResultActionButton(
                      label: '커뮤니티로 공유하기',
                      icon: Icons.share_outlined,
                      onTap: null,
                      isPrimary: false,
                    ),
                  ),
                ],
              ),
              if (showRegisterButton) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ResultActionButton(
                    label: '내 옷장에 등록하기',
                    onTap: () => _showWardrobeSaveDialog(
                      context,
                      initialName: title,
                      initialCategory: category,
                    ),
                    isPrimary: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ──── 어떻게 판단했나요? 상세 다이얼로그 (화면 중앙 팝업 방식) ──────────────────────────
  void _showGradeInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            color: Colors.white,
            child: Stack(
              children: [
                // 메인 콘텐츠 (스크롤 가능)
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Color(0xFF1E88E5),
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '어떻게 판단했나요?',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF263238),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            // 1. 오염도 판단 기준
                            const _SectionHeader(title: '오염도 판단 기준'),
                            const _CriteriaDetail(
                              text: '옷 전체 면적 대비 실제 오염 영역 비율로 계산해요.',
                            ),
                            const _CriteriaList(
                              items: [
                                '색상 불균일 (원래 색과 다른 부분)',
                                '얼룩 패턴 (경계가 불규칙한 색상 변화)',
                                '밝기 차이 (특정 부위만 어둡거나 밝음)',
                                '빈티지 워싱/페이딩은 오염으로 보지 않아요',
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Row(
                              children: [
                                _StatusChip(
                                  label: '0~5% 깨끗',
                                  color: Color(0xFFA5D6A7),
                                  textColor: Color(0xFF2E7D32),
                                ),
                                SizedBox(width: 6),
                                _StatusChip(
                                  label: '6~20% 약간',
                                  color: Color(0xFFBBDEFB),
                                  textColor: Color(0xFF1565C0),
                                ),
                                SizedBox(width: 6),
                                _StatusChip(
                                  label: '21~40% 눈에 띔',
                                  color: Color(0xFFFFF9C4),
                                  textColor: Color(0xFFF9A825),
                                ),
                                SizedBox(width: 6),
                                _StatusChip(
                                  label: '41%+ 심함',
                                  color: Color(0xFFFFCDD2),
                                  textColor: Color(0xFFC62828),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            // 2. 손상도 판단 기준
                            const _SectionHeader(title: '손상도 판단 기준'),
                            const _CriteriaDetail(
                              text: '옷 전체 면적 대비 손상 영역 비율로 계산해요.',
                            ),
                            const _CriteriaList(
                              items: [
                                '구멍/뚫린 부분 (배경이 비치는 영역)',
                                '실밥 풀림 (가장자리가 해진 부분)',
                                '마모 (표면이 닳아 색이 옅어진 부분)',
                                '보풀 (표면이 울퉁불퉁한 텍스처)',
                                '디스트레스드 디자인은 손상으로 보지 않아요',
                              ],
                            ),
                            const SizedBox(height: 16),
                            // 경고 박스
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Text('⚠️', style: TextStyle(fontSize: 14)),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '손상도 36% 이상이면 오염도 관계없이 C등급',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFC62828),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Row(
                              children: [
                                _StatusChip(
                                  label: '0~5% 없음',
                                  color: Color(0xFFA5D6A7),
                                  textColor: Color(0xFF2E7D32),
                                ),
                                SizedBox(width: 6),
                                _StatusChip(
                                  label: '6~15% 약간',
                                  color: Color(0xFFBBDEFB),
                                  textColor: Color(0xFF1565C0),
                                ),
                                SizedBox(width: 6),
                                _StatusChip(
                                  label: '16~35% 눈에 띔',
                                  color: Color(0xFFFFF9C4),
                                  textColor: Color(0xFFF9A825),
                                ),
                                SizedBox(width: 6),
                                _StatusChip(
                                  label: '36%+ 심함',
                                  color: Color(0xFFFFCDD2),
                                  textColor: Color(0xFFC62828),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            // 3. 등급 산정 방식
                            const _SectionHeader(title: '등급 산정 방식'),
                            const _CriteriaDetail(
                              text: '① 손상도 36% 이상 → 무조건 C등급',
                            ),
                            const _CriteriaDetail(text: '② 그 외 → 종합점수로 판단'),
                            const SizedBox(height: 12),
                            const Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '종합점수 = ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF455A64),
                                    ),
                                  ),
                                  TextSpan(
                                    text: '오염도 x 0.4 + 손상도 x 0.6',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5C6BC0),
                                    ),
                                  ),
                                ],
                              ),
                              style: TextStyle(fontSize: 14),
                            ),
                            const Text(
                              '(손상은 세탁으로 해결 불가 → 더 높은 가중치)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF90A4AE),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Row(
                              children: [
                                _StatusChip(
                                  label: '0~10점 S',
                                  color: Color(0xFFA5D6A7),
                                  textColor: Color(0xFF2E7D32),
                                ),
                                SizedBox(width: 6),
                                _StatusChip(
                                  label: '11~25점 A',
                                  color: Color(0xFFBBDEFB),
                                  textColor: Color(0xFF1565C0),
                                ),
                                SizedBox(width: 6),
                                _StatusChip(
                                  label: '26~45점 B',
                                  color: Color(0xFFFFF9C4),
                                  textColor: Color(0xFFF9A825),
                                ),
                                SizedBox(width: 6),
                                _StatusChip(
                                  label: '46점+ C',
                                  color: Color(0xFFFFCDD2),
                                  textColor: Color(0xFFC62828),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // 우측 상단 닫기 X 버튼
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF90A4AE)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showWardrobeSaveDialog(
    BuildContext context, {
    required String initialName,
    required String initialCategory,
  }) async {
    final submission = await showDialog<({String name, String category})>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _WardrobeSaveDialog(
          initialName: initialName,
          initialCategory: initialCategory,
        );
      },
    );

    if (submission == null || !context.mounted) return;
    try {
      await onSave(name: submission.name, category: submission.category);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}

class _WardrobeSaveDialog extends StatefulWidget {
  final String initialName;
  final String initialCategory;

  const _WardrobeSaveDialog({
    required this.initialName,
    required this.initialCategory,
  });

  @override
  State<_WardrobeSaveDialog> createState() => _WardrobeSaveDialogState();
}

class _WardrobeSaveDialogState extends State<_WardrobeSaveDialog> {
  static const _categories = ['상의', '하의', '아우터', '신발', '가방', '모자'];
  late final TextEditingController _nameController;
  late String _selectedCategory;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedCategory = _categories.contains(widget.initialCategory)
        ? widget.initialCategory
        : '상의';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '옷장에 등록',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1B20),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '옷 이름',
              errorText: _nameError,
              filled: true,
              fillColor: const Color(0xFFF7FBFD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) {
              if (_nameError != null) {
                setState(() => _nameError = null);
              }
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              labelText: '분류',
              filled: true,
              fillColor: const Color(0xFFF7FBFD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            items: _categories
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedCategory = value);
            },
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1D1B20),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFF1D1B20)),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1A39FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              setState(() => _nameError = '옷 이름을 입력해 주세요.');
              return;
            }
            Navigator.of(
              context,
            ).pop((name: name, category: _selectedCategory));
          },
          child: const Text('등록'),
        ),
      ],
    );
  }
}

class _CareLabelIcon extends StatelessWidget {
  final String? iconB64;

  const _CareLabelIcon({
    required this.iconB64,
  });

  @override
  Widget build(BuildContext context) {
    final raw = iconB64;
    if (raw != null && raw.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(raw),
          width: 26,
          height: 26,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox(width: 26, height: 26),
        );
      } catch (_) {
        return const SizedBox(width: 26, height: 26);
      }
    }
    return const SizedBox(width: 26, height: 26);
  }
}

// ───── 내부 컴포넌트 ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black, // 더 선명한 검은색으로 변경
        ),
      ),
    );
  }
}

class _CriteriaDetail extends StatelessWidget {
  final String text;
  const _CriteriaDetail({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
        ), // 더 선명한 검은색으로 변경
      ),
    );
  }
}

class _CriteriaList extends StatelessWidget {
  final List<String> items;
  const _CriteriaList({required this.items});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ), // 불렛 포인트도 약간 더 선명하게
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ), // 리스트 내용 검은색으로 변경
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _StatusChip({
    required this.label,
    required this.color,
    required this.textColor,
  });
  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

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
        height: 52,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF8FEAFD) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8FEAFD), width: 1.5),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFF8FEAFD).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: const Color(0xFF1D1B20)),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1B20),
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
          width: 38,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF546E7A),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          valueLabel,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF78909C),
          ),
        ),
      ],
    );
  }
}
