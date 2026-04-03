import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/analysis_service.dart';
import '../services/image_service.dart';
import '../widgets/share_post_sheet.dart';

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
  String? _selectedImageUrl;
  int? _selectedAnalysisId;
  String? _selectedClothingName;
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
    setState(() {
      _selectedImage = image;
      _selectedImageUrl = null;
      _selectedAnalysisId = null;
      _selectedClothingName = null;
    });
  }

  Future<void> _pickFromCloset() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ClosetPickerSheet(),
    );

    if (selected == null || !mounted) return;

    final analysisId = (selected['id'] as num?)?.toInt();
    final imageUrl = (selected['imageUrl'] as String?)?.trim() ?? '';
    final clothingName = (selected['name'] as String?)?.trim();

    setState(() {
      _selectedImage = null;
      _selectedImageUrl = imageUrl.isEmpty ? null : imageUrl;
      _selectedAnalysisId = analysisId;
      _selectedClothingName = clothingName == null || clothingName.isEmpty
          ? null
          : clothingName;
      _titleCtrl.text = buildWardrobeShareTitle(selected);
      _contentCtrl.clear();
    });
  }

  void _submit() {
    if (!_canSubmit) return;

    Navigator.of(context).pop({
      'title': _titleCtrl.text.trim(),
      'content': _contentCtrl.text.trim(),
      'imagePath': _selectedImage?.path ?? _selectedImageUrl,
      'hasImage': _selectedImage != null || _selectedImageUrl != null,
      'analysisId': _selectedAnalysisId,
      'selectedClothingName': _selectedClothingName,
      'category': _selectedCategory,
    });
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageUrl = null;
      _selectedAnalysisId = null;
      _selectedClothingName = null;
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
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: 0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? color
                                      : const Color(0xFF98A2B3),
                                  fontWeight: FontWeight.w600,
                                ),
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
                      if (_selectedImage != null || _selectedImageUrl != null) ...[
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 220,
                                child: _selectedImage != null
                                    ? Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        _selectedImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          color: const Color(0xFFE8F4FD),
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.image_outlined,
                                            size: 48,
                                            color: Color(0xFFB0BEC5),
                                          ),
                                        ),
                                      ),
                              ),
                              if (_selectedClothingName != null)
                                Positioned(
                                  left: 12,
                                  bottom: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _selectedClothingName!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: GestureDetector(
                                  onTap: _clearSelectedImage,
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
                      onPressed: _pickFromCloset,
                      icon: Icon(
                        Icons.checkroom_outlined,
                        size: 28,
                        color: _selectedAnalysisId != null
                            ? const Color(0xFF1A39FF)
                            : const Color(0xFF111111),
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

class _ClosetPickerSheet extends StatefulWidget {
  const _ClosetPickerSheet();

  @override
  State<_ClosetPickerSheet> createState() => _ClosetPickerSheetState();
}

class _ClosetPickerSheetState extends State<_ClosetPickerSheet> {
  late Future<List<Map<String, dynamic>>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = AnalysisService.fetchMyAnalyses();
  }

  Future<void> _reload() async {
    setState(() {
      _itemsFuture = AnalysisService.fetchMyAnalyses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E7EC),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '내 옷장에서 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1B20),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '선택한 옷의 사진이 게시글에 함께 표시돼요.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF7B8794),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            size: 40,
                            color: Color(0xFFB0BEC5),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            snapshot.error
                                .toString()
                                .replaceFirst('Exception: ', ''),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7B8794),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _reload,
                            child: const Text('다시 불러오기'),
                          ),
                        ],
                      ),
                    );
                  }

                  final items = snapshot.data ?? const [];
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        '옷장에 등록된 옷이 없어요.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF90A4AE),
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.82,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final imageUrl = (item['imageUrl'] as String?) ?? '';
                      final name = (item['name'] as String?) ?? '내 옷';
                      final category = (item['category'] as String?) ?? '';
                      final grade = (item['grade'] as String?) ?? '';

                      return GestureDetector(
                        onTap: () => Navigator.of(context).pop(item),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE7ECF3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  color: const Color(0xFFF4F8FF),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.checkroom_outlined,
                                            size: 42,
                                            color: Color(0xFFB0BEC5),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.checkroom_outlined,
                                          size: 42,
                                          color: Color(0xFFB0BEC5),
                                        ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1D1B20),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                                child: Row(
                                  children: [
                                    if (category.isNotEmpty)
                                      Expanded(
                                        child: Text(
                                          category,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF7B8794),
                                          ),
                                        ),
                                      ),
                                    if (grade.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE9F2FF),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          grade,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1A39FF),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
