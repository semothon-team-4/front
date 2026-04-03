import 'package:flutter/material.dart';

import '../services/community_service.dart';

String buildWardrobeShareTitle(Map<String, dynamic> item) {
  final itemName = (item['name'] as String?)?.trim();
  final itemGrade = (item['grade'] as String?)?.trim();
  final safeName = (itemName == null || itemName.isEmpty) ? '의류' : itemName;
  final safeGrade = (itemGrade == null || itemGrade.isEmpty)
      ? 'TAG'
      : itemGrade;
  return '$safeName 상태 공유 ($safeGrade등급)';
}

class SharePostSheet extends StatefulWidget {
  final String initialTitle;
  final String initialContent;
  final String category;
  final Widget? imagePreview;
  final int? analysisId;

  const SharePostSheet({
    super.key,
    this.initialTitle = '',
    this.initialContent = '',
    this.category = '세탁팁',
    this.imagePreview,
    this.analysisId,
  });

  @override
  State<SharePostSheet> createState() => _SharePostSheetState();
}

class _SharePostSheetState extends State<SharePostSheet> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedCategory;
  bool _isSubmitting = false;

  final List<String> _categories = ['세탁팁', '수선', '제품추천', '의류상태'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _contentController = TextEditingController(text: widget.initialContent);
    _selectedCategory = widget.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요')),
      );
      return;
    }
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await CommunityService.createPost(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        analysisId: widget.analysisId,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
            child: Row(
              children: [
                const Text(
                  '커뮤니티에 공유',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF90A4AE)),
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context, false),
                ),
                TextButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: Text(
                    _isSubmitting ? '등록 중...' : '등록',
                    style: TextStyle(
                      color: _isSubmitting
                          ? const Color(0xFFB0BEC5)
                          : const Color(0xFF1565C0),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카테고리 선택
                  const Text(
                    '카테고리',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF607D8B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1565C0)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? Colors.white : Colors.grey[600],
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // 이미지 미리보기
                  if (widget.imagePreview != null) ...[
                    const Text(
                      '첨부 이미지',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF607D8B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: widget.imagePreview!,
                    ),
                    const SizedBox(height: 20),
                  ],
                  // 제목
                  const Text(
                    '제목',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF607D8B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: '제목을 입력하세요',
                      hintStyle:
                          const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
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
                        borderSide: const BorderSide(color: Color(0xFF1565C0)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 내용
                  const Text(
                    '내용',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF607D8B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: '내용을 자유롭게 작성해주세요',
                      hintStyle:
                          const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
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
                        borderSide: const BorderSide(color: Color(0xFF1565C0)),
                      ),
                      contentPadding: const EdgeInsets.all(14),
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
