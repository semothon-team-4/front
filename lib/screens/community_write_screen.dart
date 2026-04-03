import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/image_service.dart';

const _kWriteCategories = ['세탁팁', '수선', '제품추천', '의류상태'];

class CommunityWriteScreen extends StatefulWidget {
  const CommunityWriteScreen({super.key});

  @override
  State<CommunityWriteScreen> createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _titleFocusNode = FocusNode();
  File? _selectedImage;
  String _selectedCategory = _kWriteCategories.first;

  bool get _canSubmit =>
      _titleCtrl.text.trim().isNotEmpty && _contentCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_refresh);
    _contentCtrl.addListener(_refresh);
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_refresh);
    _contentCtrl.removeListener(_refresh);
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickFromGallery() async {
    final image = await ImageService.pickImage(ImageSource.gallery);
    if (image == null || !mounted) return;
    setState(() => _selectedImage = image);
  }

  void _submit() {
    if (!_canSubmit) return;

    Navigator.of(context).pop({
      'title': _titleCtrl.text.trim(),
      'content': _contentCtrl.text.trim(),
      'imagePath': _selectedImage?.path,
      'hasImage': _selectedImage != null,
      'category': _selectedCategory,
    });
  }

  Color _categoryColor(String category) {
    switch (category) {
      case '세탁팁':
        return const Color(0xFF1A39FF);
      case '수선':
        return const Color(0xFFE91E63);
      case '제품추천':
        return const Color(0xFF43A047);
      case '의류상태':
        return const Color(0xFFFB8C00);
      default:
        return const Color(0xFF90A4AE);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                child: SizedBox(
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF1D1B20),
                            size: 22,
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          '글쓰기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D1B20),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _canSubmit ? _submit : null,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF1D1B20),
                            disabledForegroundColor: const Color(0xFFCFCBC7),
                          ),
                          child: Text(
                            '완료',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _canSubmit
                                  ? const Color(0xFF1D1B20)
                                  : const Color(0xFFCFCBC7),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '카테고리',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5E5852),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _kWriteCategories.map((category) {
                          final color = _categoryColor(category);
                          final isSelected = _selectedCategory == category;

                          return GestureDetector(
                            onTap: () {
                              if (_selectedCategory == category) return;
                              setState(() => _selectedCategory = category);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: 0.14)
                                    : const Color(0xFFF6F7FB),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isSelected
                                      ? color.withValues(alpha: 0.38)
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? color
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _titleCtrl,
                        focusNode: _titleFocusNode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5E5852),
                        ),
                        decoration: const InputDecoration(
                          hintText: '제목을 입력해주세요.',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7B746C),
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFE4E0DB)),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFE4E0DB)),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF1D1B20)),
                          ),
                          contentPadding: EdgeInsets.only(bottom: 16),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _contentCtrl,
                        minLines: 12,
                        maxLines: null,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.7,
                          color: Color(0xFF3B3631),
                        ),
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: '여러분의 경험이나 문제를 자유롭게 공유해보세요!',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFD1CCC6),
                          ),
                        ),
                      ),
                      if (_selectedImage != null) ...[
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedImage = null),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.55,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomInset),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFF0ECE7))),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _pickFromGallery,
                      icon: const Icon(
                        Icons.photo_camera,
                        size: 28,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: null,
                      icon: const Icon(
                        Icons.checkroom_outlined,
                        size: 28,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
