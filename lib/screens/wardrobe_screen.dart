import 'dart:io';
import 'package:flutter/material.dart';
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
  bool _isLoading = true;
  String _selectedCategory = '전체';
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
    // [비활성화] 백엔드 요청 대신 더미 데이터 사용
    await Future.delayed(const Duration(milliseconds: 500));
    _items = [
      {
        'id': '1',
        'name': '화이트 코튼 셔츠',
        'category': '상의',
        'grade': 'A',
        'lastCare': '2024.03.20',
        'imagePath': null,
        'iconColor': const Color(0xFF64B5F6),
        'stainLevel': 5,
        'damageLevel': 10,
        'recommendation': '상태가 아주 좋아요! 일반적인 세탁으로 관리하세요.',
      },
      {
        'id': '2',
        'name': '데님 팬츠',
        'category': '하의',
        'grade': 'B',
        'lastCare': '2024.03.15',
        'imagePath': null,
        'iconColor': const Color(0xFF1A237E),
        'stainLevel': 15,
        'damageLevel': 25,
        'recommendation': '중성세제를 사용하여 뒤집어서 세탁하는 것을 추천해요.',
      },
      {
        'id': '3',
        'name': '울 가디건',
        'category': '아우터',
        'grade': 'C',
        'lastCare': '2024.02.28',
        'imagePath': null,
        'iconColor': const Color(0xFFBCAAA4),
        'stainLevel': 30,
        'damageLevel': 45,
        'recommendation': '마찰에 의한 보풀이 있으니 드라이클리닝을 권장합니다.',
      },
      {
        'id': '4',
        'name': '린넨 자켓',
        'category': '아우터',
        'grade': 'D',
        'lastCare': '2024.01.10',
        'imagePath': null,
        'iconColor': const Color(0xFFE0E0E0),
        'stainLevel': 60,
        'damageLevel': 70,
        'recommendation': '손상이 심한 상태입니다. 전문 세탁소에 맡겨주세요.',
      },
    ];
    if (mounted) setState(() => _isLoading = false);
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
              const SnackBar(content: Text('이미지가 저장되었습니다.')),
            );
          },
          onStartClothingScan: () {},
        ),
      ),
    ).then((_) => _loadItems());
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == '전체'
        ? _items
        : _items.where((i) => i['category'] == _selectedCategory).toList();
    final gradeCount = <String, int>{};
    for (var it in _items) {
      final g = it['grade'] as String;
      gradeCount[g] = (gradeCount[g] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
          ? const Center(
            child: Text(
              '옷장이 비어있어요. 멋진 옷을 스캔해보세요!',
              style: TextStyle(color: Color(0xFFB0BEC5)),
            ),
          )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '내 옷장',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D1B20),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _ItemCountBox(label: '전체', count: _items.length),
                            _ItemCountBox(label: '좋음(A)', count: gradeCount['A'] ?? 0),
                            _ItemCountBox(label: '주의(C)', count: gradeCount['C'] ?? 0),
                            _ItemCountBox(label: '위험(D)', count: gradeCount['D'] ?? 0),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if ((gradeCount['D'] ?? 0) > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFCDD2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '세심한 관리가 필요한 옷이 ${gradeCount['D']}벌 있어요.',
                                style: const TextStyle(
                                  color: Color(0xFFC62828),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['전체', '상의', '하의', '아우터', '기타'].map((cat) {
                          final isActive = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isActive,
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                              backgroundColor: Colors.white,
                              selectedColor: const Color(0xFF8FEAFD),
                              labelStyle: TextStyle(
                                color: isActive ? const Color(0xFF1D1B20) : const Color(0xFF9E9E9E),
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isActive ? Colors.transparent : const Color(0xFFEEEEEE),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  sliver: filtered.isEmpty
                      ? const SliverFillRemaining(
                        child: Center(child: Text('해당 카테고리에 옷이 없어요.')),
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
                            final it = filtered[index];
                            return _ClothingItemCard(
                              item: it,
                              onTap: () => _showDetailSheet(it),
                              onShare: () => _openShareSheet(it),
                              gradeColor: _gradeColor(it['grade'] as String),
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF1D1B20),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('옷 분석하기', style: TextStyle(color: Colors.white)),
      ),
    );
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

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A': return const Color(0xFF4CAF50);
      case 'B': return const Color(0xFF8BC34A);
      case 'C': return const Color(0xFFFFA000);
      case 'D': return const Color(0xFFE53935);
      default: return Colors.grey;
    }
  }
}

class _ItemCountBox extends StatelessWidget {
  final String label;
  final int count;
  const _ItemCountBox({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1D1B20)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
      ],
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

// ── 의류 공유 바텀시트 ──────────────────────────────────────────
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D1B20)),
          ),
          const SizedBox(height: 12),
          const Text(
            '이 옷의 분석 결과를 게시글로 바로 작성합니다.',
            style: TextStyle(fontSize: 14, color: Color(0xFF78909C)),
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
                  child: Center(
                    child: Icon(Icons.checkroom, color: const Color(0xFF1A39FF).withValues(alpha: 0.5)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('$category · $grade등급', style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 12)),
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
                elevation: 0,
              ),
              child: const Text('게시글 작성하러 가기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
