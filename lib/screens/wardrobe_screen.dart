import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/image_service.dart';
import '../widgets/analysis_result_view.dart';
import 'community_screen.dart';

class WardrobeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  final int? refreshSignal;

  const WardrobeScreen({super.key, this.onNavigate, this.refreshSignal});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  static const _allCategory = '전체';

  bool _isLoading = true;
  String _selectedCategory = _allCategory;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void didUpdateWidget(covariant WardrobeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshSignal != oldWidget.refreshSignal) {
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 300));

    _items = [
      {
        'id': '1',
        'name': '화이트 코튼 셔츠',
        'category': '상의',
        'grade': 'A',
        'lastCare': '2026.03.20',
        'imagePath': null,
        'iconColor': const Color(0xFF64B5F6),
        'stainLevel': 5,
        'damageLevel': 10,
        'recommendation': '현재 상태가 아주 좋아요. 기본 세탁과 보관만 꾸준히 해주면 됩니다.',
      },
      {
        'id': '2',
        'name': '네이비 슬랙스',
        'category': '하의',
        'grade': 'B',
        'lastCare': '2026.03.15',
        'imagePath': null,
        'iconColor': const Color(0xFF1A237E),
        'stainLevel': 15,
        'damageLevel': 25,
        'recommendation': '중성세제로 세탁하고 마찰이 심한 부분은 부드럽게 관리해 주세요.',
      },
      {
        'id': '3',
        'name': '베이지 가디건',
        'category': '아우터',
        'grade': 'C',
        'lastCare': '2026.02.28',
        'imagePath': null,
        'iconColor': const Color(0xFFBCAAA4),
        'stainLevel': 30,
        'damageLevel': 45,
        'recommendation': '마모가 조금 보여요. 옷걸이 자국과 보풀을 함께 점검해 주세요.',
      },
      {
        'id': '4',
        'name': '그레이 자켓',
        'category': '아우터',
        'grade': 'D',
        'lastCare': '2026.01.10',
        'imagePath': null,
        'iconColor': const Color(0xFFE0E0E0),
        'stainLevel': 60,
        'damageLevel': 70,
        'recommendation': '손상이 큰 상태예요. 전문 세탁이나 수선 여부를 먼저 확인하는 것이 좋아요.',
      },
    ];

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showDetailSheet(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisResultView(
          image: item['imagePath'] != null ? File(item['imagePath'] as String) : null,
          isCareLabel: false,
          analysisResult: item,
          showRegisterButton: false,
          onBack: () => Navigator.pop(context),
          onSave: () {},
          onReset: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('이미지가 초기화되었습니다.')),
            );
          },
          onSaveImage: () async {
            try {
              final imagePath = item['imagePath'] as String?;
              if (imagePath != null) {
                final file = File(imagePath);
                if (await file.exists()) {
                  final now = DateTime.now();
                  await ImageService.saveImageLocally(
                    file,
                    'wardrobe_${now.millisecondsSinceEpoch}.jpg',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text('이미지를 저장했어요.'),
                          ],
                        ),
                        backgroundColor: const Color(0xFF1A39FF),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                  return;
                }
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('저장할 이미지를 찾을 수 없어요.')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('저장에 실패했어요: $e')),
                );
              }
            }
          },
          onStartClothingScan: () {},
        ),
      ),
    ).then((_) => _loadItems());
  }

  void _openShareSheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SharePostSheet(
        title: item['name'] as String,
        category: item['category'] as String,
        grade: item['grade'] as String,
        imageUrl: item['imagePath'] as String?,
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return const Color(0xFF4CAF50);
      case 'B':
        return const Color(0xFF8BC34A);
      case 'C':
        return const Color(0xFFFFA000);
      case 'D':
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == _allCategory
        ? _items
        : _items.where((item) => item['category'] == _selectedCategory).toList();
    final gradeCount = <String, int>{};
    for (final item in _items) {
      final grade = item['grade'] as String;
      gradeCount[grade] = (gradeCount[grade] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A39FF)),
            )
          : SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: _WardrobeHeader(
                        totalCount: _items.length,
                        gradeCount: gradeCount,
                        onClose: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            widget.onNavigate?.call(0);
                          }
                        },
                      ),
                    ),
                  ),
                  if ((gradeCount['D'] ?? 0) > 0)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFFCC02)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFFB8C00),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '관리 우선 대상 의류가 ${gradeCount['D']}개 있어요.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFE65100),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            '분류',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1D1B20),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              const categories = ['전체', '상의', '하의', '아우터', '기타'];
                              final picked = await showModalBottomSheet<String>(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (_) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 12),
                                    Container(
                                      width: 36,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0E0E0),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...categories.map(
                                      (category) => ListTile(
                                        title: Text(
                                          category,
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                        trailing: _selectedCategory == category
                                            ? const Icon(Icons.check, color: Color(0xFF1A39FF))
                                            : null,
                                        onTap: () => Navigator.pop(context, category),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              );
                              if (picked != null) {
                                setState(() => _selectedCategory = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF79D5F1),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedCategory,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF1D1B20),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 18,
                                    color: Color(0xFF1D1B20),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    sliver: filtered.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(top: 60),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.checkroom_outlined,
                                      size: 52,
                                      color: Color(0xFFCFD8DC),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      '등록된 의류가 없어요.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF90A4AE),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.78,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = filtered[index];
                                return _ClothingItemCard(
                                  item: item,
                                  onTap: () => _showDetailSheet(item),
                                  onShare: () => _openShareSheet(item),
                                  gradeColor: _getGradeColor(item['grade'] as String),
                                );
                              },
                              childCount: filtered.length,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _WardrobeHeader extends StatelessWidget {
  final int totalCount;
  final Map<String, int> gradeCount;
  final VoidCallback onClose;

  const _WardrobeHeader({
    required this.totalCount,
    required this.gradeCount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(24),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.close_rounded,
                      size: 32,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  '옷장',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D1B20),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            const cardCount = 5;
            const preferredCardSize = 71.0;
            const minGap = 2.0;

            final availableWidth = constraints.maxWidth;
            final cardSize = math.min(
              preferredCardSize,
              (availableWidth - (minGap * (cardCount - 1))) / cardCount,
            );
            final gap =
                ((availableWidth - (cardSize * cardCount)) / (cardCount - 1)).clamp(minGap, 8.0);

            return Row(
              children: [
                _WardrobeStatCard(
                  size: cardSize,
                  count: totalCount,
                  title: '전체',
                  icon: Icons.checkroom_outlined,
                  textColor: const Color(0xFF2A2D34),
                  gradientColors: const [Color(0xFF8ADAF0), Color(0xFFFFFFFF)],
                ),
                SizedBox(width: gap),
                ...['A', 'B', 'C', 'D'].map((grade) {
                  final config = switch (grade) {
                    'A' => (
                        title: 'A등급',
                        gradient: const [Color(0xFFFF9EA8), Color(0xFFFFFFFF)],
                      ),
                    'B' => (
                        title: 'B등급',
                        gradient: const [Color(0xFFFFC39A), Color(0xFFFFFFFF)],
                      ),
                    'C' => (
                        title: 'C등급',
                        gradient: const [Color(0xFFFFE88F), Color(0xFFFFFFFF)],
                      ),
                    _ => (
                        title: 'D등급',
                        gradient: const [Color(0xFFC9FF74), Color(0xFFFFFFFF)],
                      ),
                  };

                  return Padding(
                    padding: EdgeInsets.only(right: grade == 'D' ? 0 : gap),
                    child: _WardrobeStatCard(
                      size: cardSize,
                      count: gradeCount[grade] ?? 0,
                      title: config.title,
                      textColor: const Color(0xFF2A2D34),
                      gradientColors: config.gradient,
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _WardrobeStatCard extends StatelessWidget {
  final double size;
  final int count;
  final String title;
  final IconData? icon;
  final Color textColor;
  final List<Color> gradientColors;

  const _WardrobeStatCard({
    required this.size,
    required this.count,
    required this.title,
    this.icon,
    required this.textColor,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: size * 0.24,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            SizedBox(height: size * 0.055),
            if (icon != null)
              Icon(icon, size: size * 0.36, color: textColor)
            else
              Text(
                title,
                style: TextStyle(
                  fontSize: size * 0.13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClothingItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final Color gradeColor;

  const _ClothingItemCard({
    required this.item,
    required this.onTap,
    required this.onShare,
    required this.gradeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Center(
                        child: Icon(
                          Icons.checkroom,
                          color: (item['iconColor'] as Color?) ?? const Color(0xFF9E9E9E),
                          size: 58,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            item['grade'] as String,
                            style: TextStyle(
                              color: gradeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: onShare,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.share,
                            size: 15,
                            color: Color(0xFF1A39FF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1B20),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4FD),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item['category'] as String,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF1A39FF),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item['lastCare'] as String,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFB0BEC5),
                        ),
                      ),
                    ],
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

class SharePostSheet extends StatelessWidget {
  final String title;
  final String category;
  final String grade;
  final String? imageUrl;

  const SharePostSheet({
    super.key,
    required this.title,
    required this.category,
    required this.grade,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '커뮤니티에 공유하기',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1B20),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE3EAFF)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.checkroom, color: Color(0xFF1A39FF)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1B20),
                        ),
                      ),
                      Text(
                        '$category · $grade등급',
                        style: const TextStyle(
                          color: Color(0xFF90A4AE),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showCommunityWriteSheet(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A39FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                '게시글 작성하러 가기',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
