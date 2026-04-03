import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/analysis_result_view.dart';
import '../widgets/share_post_sheet.dart';
import '../services/analysis_service.dart';

class WardrobeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  final int refreshSignal;
  const WardrobeScreen({super.key, this.onNavigate, this.refreshSignal = 0});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  int _totalCount = 0;
  Map<String, int> _gradeCount = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
  int _tagCount = 0;
  String _selectedCategory = '전체'; // 분류 필터

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void didUpdateWidget(WardrobeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final closet = await AnalysisService.fetchMyCloset();
      final items = ((closet["items"] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final serverCounts = <String, int>{"A": 0, "B": 0, "C": 0, "D": 0};
      final rawCounts = Map<String, dynamic>.from(
        (closet["gradeCounts"] as Map?) ?? {},
      );
      for (final key in serverCounts.keys) {
        serverCounts[key] = (rawCounts[key] as num?)?.toInt() ?? 0;
      }
      final serverTotalCount =
          (closet["totalCount"] as num?)?.toInt() ?? items.length;
      final serverTagCount =
          (closet["tagCount"] as num?)?.toInt() ??
          (serverTotalCount -
                  ((serverCounts["A"] ?? 0) +
                      (serverCounts["B"] ?? 0) +
                      (serverCounts["C"] ?? 0) +
                      (serverCounts["D"] ?? 0)))
              .clamp(0, serverTotalCount);

      final detailedItems = <Map<String, dynamic>>[];
      for (final item in items) {
        final id = item["id"];
        if (id is! int) continue;
        try {
          final detail = await AnalysisService.fetchAnalysisDetail(id);
          detailedItems.add({
            ...item,
            ...detail,
            "iconColor": _colorForCategory(
              (detail["category"] as String?) ??
                  (item["category"] as String?) ??
                  "",
            ),
          });
        } catch (_) {
          detailedItems.add({
            ...item,
            "iconColor": _colorForCategory((item["category"] as String?) ?? ""),
            "lastCare": "방금 전",
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _items = detailedItems;
        _totalCount = serverTotalCount;
        _gradeCount = serverCounts;
        _tagCount = serverTagCount;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _totalCount = 0;
        _gradeCount = {"A": 0, "B": 0, "C": 0, "D": 0};
        _tagCount = 0;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  Color _colorForCategory(String cat) {
    switch (cat) {
      case '상의':
        return const Color(0xFF1A39FF);
      case '하의':
        return const Color(0xFF1A39FF);
      case '아우터':
        return const Color(0xFF37474F);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A':
        return const Color(0xFF41D83C);
      case 'B':
        return const Color(0xFFFFD931);
      case 'C':
        return const Color(0xFFFF9131);
      case 'D':
        return const Color(0xFFFF3131);
      default:
        return Colors.grey;
    }
  }

  String _gradeDesc(String grade) {
    switch (grade) {
      case 'A':
        return '최상 — 관리 잘 됨';
      case 'B':
        return '양호 — 곧 세탁 권장';
      case 'C':
        return '주의 — 세탁 필요';
      case 'D':
        return '관리 필요 — 즉시 처리';
      default:
        return '';
    }
  }

  void _openShareSheet(Map<String, dynamic> item) {
    final itemName = (item['name'] as String?) ?? '의류';
    final itemGrade = (item['grade'] as String?) ?? 'TAG';
    final itemDesc = (item['desc'] as String?) ?? '분석 결과를 확인해 주세요.';
    final itemLastCare = (item['lastCare'] as String?) ?? '방금 전';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SharePostSheet(
        initialTitle: '$itemName 상태 공유 ($itemGrade등급)',
        initialContent: '$itemDesc\n\n마지막 세탁: $itemLastCare',
        category: '의류상태',
        imagePreview: Container(
          height: 120,
          color: ((item['iconColor'] as Color?) ?? const Color(0xFF9E9E9E))
              .withValues(alpha: 0.15),
          child: Stack(
            children: [
              Positioned.fill(
                child: _ClothingPreview(
                  imageUrl: (item['imageUrl'] as String?) ?? '',
                  imagePath: (item['imagePath'] as String?) ?? '',
                  iconColor:
                      (item['iconColor'] as Color?) ?? const Color(0xFF9E9E9E),
                  iconSize: 44,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Text(
                  itemName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        (item['iconColor'] as Color?) ??
                        const Color(0xFF9E9E9E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((posted) {
      if (posted == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('커뮤니티에 공유되었습니다!'),
            backgroundColor: Color(0xFF1A39FF),
          ),
        );
      }
    });
  }

  Future<void> _openAnalysisResult(Map<String, dynamic> item) async {
    final rawId = item["id"];
    final analysisId = rawId is int
        ? rawId
        : (rawId is num
              ? rawId.toInt()
              : int.tryParse(rawId?.toString() ?? ""));

    var analysisResult = Map<String, dynamic>.from(item);

    if (analysisId != null) {
      try {
        final detail = await AnalysisService.fetchAnalysisDetail(analysisId);
        analysisResult = {...analysisResult, ...detail};
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst("Exception: ", "")),
            ),
          );
        }
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalysisResultView(
          image: null,
          isCareLabel: false,
          analysisResult: analysisResult,
          showRegisterButton: false,
          onNavigate: widget.onNavigate,
          onBack: () => Navigator.of(context).pop(),
          onSave: ({required name, required category}) async {},
          onReset: () => Navigator.of(context).pop(),
          onSaveImage: () {},
          onStartClothingScan: () {},
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showDetailSheet(Map<String, dynamic> item) {
    final itemGrade = ((item['grade'] as String?) ?? 'TAG').toUpperCase();

    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ClothingDetailSheet(
        item: item,
        gradeColor: _gradeColor(itemGrade),
        gradeDesc: _gradeDesc(itemGrade),
        onShare: () => _openShareSheet(item),
      ),
    ).then((result) async {
      if (result == 'delete') {
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('의류 삭제'),
            content: Text('"${item['name']}"을(를) 삭제할까요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  '삭제',
                  style: TextStyle(color: Color(0xFFE53935)),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true && item['id'] != null) {
          try {
            await AnalysisService.deleteAnalysis(item['id'] as int);
            await _loadItems();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceFirst('Exception: ', '')),
              ),
            );
          }
        }
      } else if (result == 'laundry') {
        widget.onNavigate?.call(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 분류 필터 적용
    final filtered = _selectedCategory == '전체'
        ? _items
        : _items.where((i) => i['category'] == _selectedCategory).toList();
    final gradeCount = _gradeCount;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
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
                        totalCount: _totalCount,
                        gradeCount: gradeCount,
                        tagCount: _tagCount,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
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
                                  '관리가 필요한 의류가 ${gradeCount['D']}벌 있어요',
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
                              final cats = ['전체', '상의', '하의', '아우터', '기타'];
                              final picked = await showModalBottomSheet<String>(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (sheetContext) => Column(
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
                                    ...cats.map(
                                      (c) => ListTile(
                                        title: Text(
                                          c,
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                        trailing: _selectedCategory == c
                                            ? const Icon(
                                                Icons.check,
                                                color: Color(0xFF1A39FF),
                                              )
                                            : null,
                                        onTap: () =>
                                            Navigator.pop(sheetContext, c),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
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
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.checkroom_outlined,
                                      size: 52,
                                      color: Color(0xFFCFD8DC),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      '등록된 의류가 없어요',
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
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _ClothingCard(
                                item: filtered[index],
                                onTap: () =>
                                    _openAnalysisResult(filtered[index]),
                                onShare: () => _openShareSheet(filtered[index]),
                              ),
                              childCount: filtered.length,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.78,
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
  final int tagCount;
  final VoidCallback onClose;

  const _WardrobeHeader({
    required this.totalCount,
    required this.gradeCount,
    required this.tagCount,
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
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '내 옷장',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        totalCount.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                    ),
                  ],
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
                ((availableWidth - (cardSize * cardCount)) / (cardCount - 1))
                    .clamp(minGap, 8.0);

            final statConfigs = [
              (
                title: 'A등급',
                count: gradeCount['A'] ?? 0,
                gradient: const [Color(0xFFFF9EA8), Color(0xFFFFFFFF)],
              ),
              (
                title: 'B등급',
                count: gradeCount['B'] ?? 0,
                gradient: const [Color(0xFFFFC39A), Color(0xFFFFFFFF)],
              ),
              (
                title: 'C등급',
                count: gradeCount['C'] ?? 0,
                gradient: const [Color(0xFFFFE88F), Color(0xFFFFFFFF)],
              ),
              (
                title: 'D등급',
                count: gradeCount['D'] ?? 0,
                gradient: const [Color(0xFFC9FF74), Color(0xFFFFFFFF)],
              ),
              (
                title: 'TAG',
                count: tagCount,
                gradient: const [Color(0xFF8EDBF1), Color(0xFFFFFFFF)],
              ),
            ];

            return Row(
              children: [
                ...statConfigs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final config = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == statConfigs.length - 1 ? 0 : gap,
                    ),
                    child: _WardrobeStatCard(
                      size: cardSize,
                      count: config.count,
                      title: config.title,
                      subtitle: null,
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
  final String? subtitle;
  final IconData? icon;
  final Color textColor;
  final List<Color> gradientColors;

  const _WardrobeStatCard({
    required this.size,
    required this.count,
    required this.title,
    this.subtitle,
    this.icon, // ignore: unused_element_parameter
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
            if (subtitle != null) ...[
              SizedBox(height: size * 0.03),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: size * 0.13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClothingCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback onShare;

  const _ClothingCard({
    required this.item,
    required this.onTap,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = (item['imageUrl'] as String?) ?? '';
    final imagePath = (item['imagePath'] as String?) ?? '';
    final itemName = (item['name'] as String?) ?? '이름 없는 의류';
    final itemCategory = (item['category'] as String?) ?? '기타';
    final itemLastCare = (item['lastCare'] as String?) ?? '방금 전';
    final grade = (item['grade'] as String?)?.toUpperCase();
    final isTag = grade == null || grade.isEmpty;
    final badgeText = isTag ? 'TAG' : grade;
    final badgeColor = switch (badgeText) {
      'A' => const Color(0xFFFF9EA8),
      'B' => const Color(0xFFFFC39A),
      'C' => const Color(0xFFFFE88F),
      'D' => const Color(0xFFC9FF74),
      _ => const Color(0xFF8EDBF1),
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color:
                      ((item['iconColor'] as Color?) ?? const Color(0xFF9E9E9E))
                          .withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _ClothingPreview(
                        imageUrl: imageUrl,
                        imagePath: imagePath,
                        iconColor:
                            (item['iconColor'] as Color?) ??
                            const Color(0xFF9E9E9E),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        iconSize: 58,
                      ),
                    ),
                    // 등급 배지 — 흰 배경 + 등급 색 텍스트 (Figma 화면13, 우하단)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.95),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 공유 버튼
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
                    itemName,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4FD),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          itemCategory,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF1A39FF),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        itemLastCare,
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

// 의류 상세 바텀시트
class _ClothingDetailSheet extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color gradeColor;
  final String gradeDesc;
  final VoidCallback onShare;

  const _ClothingDetailSheet({
    required this.item,
    required this.gradeColor,
    required this.gradeDesc,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = (item['imageUrl'] as String?) ?? '';
    final imagePath = (item['imagePath'] as String?) ?? '';
    final itemName = (item['name'] as String?) ?? '이름 없는 의류';
    final itemCategory = (item['category'] as String?) ?? '기타';
    final itemGrade = ((item['grade'] as String?) ?? 'TAG').toUpperCase();
    final itemDesc = (item['desc'] as String?) ?? '분석 결과를 확인해 주세요.';
    final itemLastCare = (item['lastCare'] as String?) ?? '방금 전';
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 의류 이미지 + 기본 정보
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color:
                          ((item['iconColor'] as Color?) ??
                                  const Color(0xFF9E9E9E))
                              .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: 84,
                            height: 84,
                            child: _ClothingPreview(
                              imageUrl: imageUrl,
                              imagePath: imagePath,
                              iconColor:
                                  (item['iconColor'] as Color?) ??
                                  const Color(0xFF9E9E9E),
                              iconSize: 48,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D1B20),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                itemCategory,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9E9E9E),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // 등급 표시바
                              _GradeBar(
                                grade: itemGrade,
                                gradeColor: gradeColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 상태 설명
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: gradeColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: gradeColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: gradeColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$itemGrade등급 · $gradeDesc',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          itemDesc,
                          style: TextStyle(
                            fontSize: 13,
                            color: gradeColor,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Color(0xFFB0BEC5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '마지막 세탁: $itemLastCare',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onShare();
                          },
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text('커뮤니티 공유'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1A39FF),
                            side: const BorderSide(color: Color(0xFF1A39FF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context, 'laundry'),
                          icon: const Icon(
                            Icons.local_laundry_service,
                            size: 16,
                          ),
                          label: const Text('세탁소 찾기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A39FF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context, 'delete'),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Color(0xFFE53935),
                      ),
                      label: const Text(
                        '삭제',
                        style: TextStyle(color: Color(0xFFE53935)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 등급 진행 바 (A~D 시각화)
class _GradeBar extends StatelessWidget {
  final String grade;
  final Color gradeColor;

  const _GradeBar({required this.grade, required this.gradeColor});

  double get _progress {
    switch (grade) {
      case 'A':
        return 1.0;
      case 'B':
        return 0.75;
      case 'C':
        return 0.5;
      case 'D':
        return 0.25;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['D', 'C', 'B', 'A'].map((g) {
            return Text(
              g,
              style: TextStyle(
                fontSize: 10,
                color: g == grade ? gradeColor : const Color(0xFFCFD8DC),
                fontWeight: g == grade ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: const Color(0xFFECEFF1),
            valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _ClothingPreview extends StatelessWidget {
  final String imageUrl;
  final String imagePath;
  final Color iconColor;
  final BorderRadius? borderRadius;
  final double iconSize;

  const _ClothingPreview({
    required this.imageUrl,
    required this.imagePath,
    required this.iconColor,
    this.borderRadius,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocalImage = imagePath.isNotEmpty && File(imagePath).existsSync();
    if (hasLocalImage) {
      return Container(
        decoration: BoxDecoration(borderRadius: borderRadius),
        clipBehavior: Clip.antiAlias,
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _defaultImage(),
        ),
      );
    }

    if (imageUrl.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(borderRadius: borderRadius),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _defaultImage(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: iconColor.withValues(alpha: 0.12),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      );
    }
    return _defaultImage();
  }

  Widget _defaultImage() {
    return Container(
      decoration: BoxDecoration(borderRadius: borderRadius),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/tshirt.png',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: iconColor.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Icon(Icons.checkroom, size: iconSize, color: iconColor),
    );
  }
}
