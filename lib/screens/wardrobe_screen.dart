import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/share_post_sheet.dart';
import '../services/analysis_service.dart';
import '../services/image_service.dart';

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
      final items = await AnalysisService.fetchMyAnalyses();
      final detailedItems = <Map<String, dynamic>>[];
      for (final item in items) {
        final id = item['id'];
        if (id is! int) continue;
        final detail = await AnalysisService.fetchAnalysisDetail(id);
        detailedItems.add({
          ...detail,
          'iconColor': _colorForCategory((detail['category'] as String?) ?? ''),
        });
      }
      if (!mounted) return;
      setState(() {
        _items = detailedItems;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SharePostSheet(
        initialTitle: '${item['name']} 상태 공유 (${item['grade']}등급)',
        initialContent: '${item['desc']}\n\n마지막 세탁: ${item['lastCare']}',
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
                  item['name'],
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

  Future<void> _showAddClothingSheet() async {
    File? pickedImage;
    final nameCtrl = TextEditingController();
    String selectedCategory = '상의';
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '의류 추가',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1B20),
                  ),
                ),
                const SizedBox(height: 16),
                // 사진 선택
                GestureDetector(
                  onTap: () async {
                    final file = await ImageService.showPickerSheet(ctx);
                    if (file != null) setSheetState(() => pickedImage = file);
                  },
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4FD),
                      borderRadius: BorderRadius.circular(14),
                      image: pickedImage != null
                          ? DecorationImage(
                              image: FileImage(pickedImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: pickedImage == null
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  color: Color(0xFF1A39FF),
                                  size: 32,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  '사진 추가',
                                  style: TextStyle(
                                    color: Color(0xFF1A39FF),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 14),
                // 이름
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: '의류 이름 (예: 화이트 셔츠)',
                    hintStyle: const TextStyle(color: Color(0xFFB0BEC5)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1A39FF)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 카테고리
                Row(
                  children: ['상의', '하의', '아우터', '기타'].map((cat) {
                    final sel = selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFF1A39FF)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 13,
                            color: sel ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty ||
                                pickedImage == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('사진과 의류 이름을 입력해주세요.'),
                                ),
                              );
                              return;
                            }
                            setSheetState(() => isSubmitting = true);
                            try {
                              await AnalysisService.requestAnalysis(
                                image: pickedImage!,
                                name: nameCtrl.text.trim(),
                                category: selectedCategory,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              await _loadItems();
                            } catch (e) {
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceFirst(
                                      'Exception: ',
                                      '',
                                    ),
                                  ),
                                ),
                              );
                            } finally {
                              if (ctx.mounted) {
                                setSheetState(() => isSubmitting = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A39FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '추가하기',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(Map<String, dynamic> item) {
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ClothingDetailSheet(
        item: item,
        gradeColor: _gradeColor(item['grade'] as String),
        gradeDesc: _gradeDesc(item['grade'] as String),
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

    final gradeCount = <String, int>{'A': 0, 'B': 0, 'C': 0, 'D': 0};
    for (final item in _items) {
      final g = (item['grade'] as String?) ?? 'A';
      gradeCount[g] = (gradeCount[g] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('내 옷장'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A39FF)),
            )
          : CustomScrollView(
              slivers: [
                // ── 통계 헤더 ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.checkroom,
                                size: 24,
                                color: Color(0xFF1A39FF),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_items.length}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A39FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: ['A', 'B', 'C', 'D'].map((g) {
                              final count = gradeCount[g] ?? 0;
                              final color = _gradeColor(g);
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$count',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: color,
                                        ),
                                      ),
                                      Text(
                                        '$g등급',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── D등급 경고 ──────────────────────────────────
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
                            Text(
                              '관리가 필요한 의류가 ${gradeCount['D']}벌 있어요',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE65100),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── 분류 필터 ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Row(
                      children: [
                        const Text(
                          '분류',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1D1B20),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                                      onTap: () => Navigator.pop(context, c),
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
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCF9FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedCategory,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1D1B20),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
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

                // ── 그리드 ──────────────────────────────────────
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
                              gradeColor: _gradeColor(
                                (filtered[index]['grade'] as String?) ?? 'A',
                              ),
                              onTap: () => _showDetailSheet(filtered[index]),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClothingSheet,
        backgroundColor: const Color(0xFF1A39FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '의류 추가',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ClothingCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color gradeColor;
  final VoidCallback onTap;
  final VoidCallback onShare;

  const _ClothingCard({
    required this.item,
    required this.gradeColor,
    required this.onTap,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = (item['imageUrl'] as String?) ?? '';
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            item['grade'],
                            style: TextStyle(
                              color: gradeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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
                    item['name'],
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
                          item['category'],
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF1A39FF),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item['lastCare'],
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
                                item['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D1B20),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['category'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9E9E9E),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // 등급 표시바
                              _GradeBar(
                                grade: item['grade'] as String,
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
                                '${item['grade']}등급 · $gradeDesc',
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
                          item['desc'],
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
                        '마지막 세탁: ${item['lastCare']}',
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
  final Color iconColor;
  final BorderRadius? borderRadius;
  final double iconSize;

  const _ClothingPreview({
    required this.imageUrl,
    required this.iconColor,
    this.borderRadius,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(borderRadius: borderRadius),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
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
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: iconColor.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Icon(Icons.checkroom, size: iconSize, color: iconColor),
    );
  }
}
