import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_service.dart';
import '../services/wardrobe_db.dart';
import 'community_screen.dart';

// 스캔 모드: 케어라벨 스캔 vs 옷 스캔
enum _ScanMode { careLabel, clothing }

class ScanScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const ScanScreen({super.key, this.onNavigate});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  _ScanMode _mode = _ScanMode.careLabel;
  File? _scannedImage;
  bool _isAnalyzing = false;
  bool _scanComplete = false; // 스캔 완료 카드 표시
  int _resultPage = -1; // -1: 결과 없음, 0: 1/2, 1: 2/2

  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(_scanLineCtrl);
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndScan(ImageSource source) async {
    final file = await ImageService.pickImage(source);
    if (file == null) return;
    setState(() {
      _scannedImage = file;
      _isAnalyzing = true;
      _scanComplete = false;
      _resultPage = -1;
    });
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _scanComplete = true;
      });
    }
  }

  Future<void> _startClothingScanFlow() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFF1A39FF),
              ),
              title: const Text('카메라로 의류 촬영'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: Color(0xFF1A39FF),
              ),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    setState(() {
      _mode = _ScanMode.clothing;
      _scanComplete = false;
      _resultPage = -1;
    });

    await _pickAndScan(source);
  }

  void _reset() => setState(() {
    _scannedImage = null;
    _isAnalyzing = false;
    _scanComplete = false;
    _resultPage = -1;
  });

  @override
  Widget build(BuildContext context) {
    // 결과 화면 — 택 스캔 결과 (화면13)
    if (_resultPage == 0) {
      return _TagScanResultScreen(
        image: _scannedImage,
        mode: _mode,
        onNavigate: widget.onNavigate,
        onBack: () => setState(() => _resultPage = -1),
        onSave: _saveToWardrobe,
        onReset: _reset,
        onStartClothingScan: _startClothingScanFlow,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A2340),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2340),
        elevation: 0,
        centerTitle: true,
        title: Text(
          _mode == _ScanMode.careLabel ? '케어라벨 SCAN' : '의류 SCAN',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _reset,
        ),
      ),
      body: Stack(
        children: [
          // ── 카메라 뷰파인더 영역 ─────────────────────
          Positioned.fill(
            bottom: _scanComplete ? 200 : 0,
            child: _scannedImage != null
                ? Image.file(_scannedImage!, fit: BoxFit.cover)
                : _buildViewfinder(),
          ),

          // ── 모드 선택 칩 (상단) ───────────────────────
          if (!_scanComplete && !_isAnalyzing)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ModeChip(
                    label: '케어라벨 스캔',
                    active: _mode == _ScanMode.careLabel,
                    onTap: () => setState(() {
                      _mode = _ScanMode.careLabel;
                      _reset();
                    }),
                  ),
                  const SizedBox(width: 10),
                  _ModeChip(
                    label: '의류 스캔',
                    active: _mode == _ScanMode.clothing,
                    onTap: () => setState(() {
                      _mode = _ScanMode.clothing;
                      _reset();
                    }),
                  ),
                ],
              ),
            ),

          // ── 분석 중 오버레이 ──────────────────────────
          if (_isAnalyzing)
            Positioned.fill(
              bottom: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF8FEAFD),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 20),
                      Text(
                        '분석 중...',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── 스캔 완료 카드 ─────────────────────────────
          if (_scanComplete)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ScanCompleteCard(
                mode: _mode,
                onViewResult: () => setState(() => _resultPage = 0),
              ),
            ),

          // ── 촬영 버튼 (단일 원형 셔터) ────────────────
          if (!_scanComplete && !_isAnalyzing && _scannedImage == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: Column(
                children: [
                  // 안내 문구
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF363737),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _mode == _ScanMode.careLabel
                          ? '케어라벨이 선명하게 보이도록 찍어주세요'
                          : '의류 전체가 보이도록 찍어주세요',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 갤러리 버튼
                      GestureDetector(
                        onTap: () => _pickAndScan(ImageSource.gallery),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                      // 셔터 버튼 (큰 원형)
                      GestureDetector(
                        onTap: () => _pickAndScan(ImageSource.camera),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: Color(0xFF8FEAFD),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Color(0xFF1D1B20),
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 84), // 좌우 대칭
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 스캔 프레임 애니메이션
  Widget _buildViewfinder() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 그리드 배경
        CustomPaint(painter: _GridPainter(), child: const SizedBox.expand()),
        // 스캔 프레임
        SizedBox(
          width: 240,
          height: 160,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x5542A5F5), width: 1),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: _Corner(top: true, left: true),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: _Corner(top: true, left: false),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: _Corner(top: false, left: true),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: _Corner(top: false, left: false),
              ),
              // 스캔 라인
              AnimatedBuilder(
                animation: _scanLineAnim,
                builder: (_, _) => Positioned(
                  top: _scanLineAnim.value * 150,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0xCC8FEAFD),
                          Color(0xFF8FEAFD),
                          Color(0xCC8FEAFD),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveToWardrobe() async {
    final nameCtrl = TextEditingController();
    final categoryNotifier = ValueNotifier<String>('상의');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('옷장에 저장'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '의류 이름 (예: 흰 면 셔츠)',
                hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                filled: true,
                fillColor: const Color(0xFFF8FAFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<String>(
              valueListenable: categoryNotifier,
              builder: (_, selected, _) => DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: InputDecoration(
                  labelText: '카테고리',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ['상의', '하의', '아우터', '기타']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) categoryNotifier.value = v;
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8FEAFD),
              foregroundColor: const Color(0xFF1D1B20),
              elevation: 0,
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final name = nameCtrl.text.trim().isEmpty
          ? '스캔한 의류'
          : nameCtrl.text.trim();
      final now = DateTime.now();
      String? imagePath;
      if (_scannedImage != null) {
        try {
          imagePath = await ImageService.saveImageLocally(
            _scannedImage!,
            'scan_${now.millisecondsSinceEpoch}.jpg',
          );
        } catch (_) {}
      }
      try {
        await WardrobeDB.insertClothing({
          'name': name,
          'category': categoryNotifier.value,
          'grade': 'B',
          'desc': '스캔 등록',
          'imagePath': imagePath ?? '',
          'lastCare': '방금 전',
        });
      } catch (e) {
        debugPrint('옷장 저장 오류: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$name"이(가) 옷장에 저장되었어요!'),
            backgroundColor: const Color(0xFF1A39FF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        // 옷장 탭으로 이동
        widget.onNavigate?.call(1);
      }
    }
    nameCtrl.dispose();
    categoryNotifier.dispose();
  }
}

// ─── 스캔 완료 카드 (Figma 화면10) ───────────────────────────────
class _ScanCompleteCard extends StatelessWidget {
  final _ScanMode mode;
  final VoidCallback onViewResult;

  const _ScanCompleteCard({required this.mode, required this.onViewResult});

  @override
  Widget build(BuildContext context) {
    final isCareLabel = mode == _ScanMode.careLabel;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 아이콘 + 텍스트
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF8FEAFD).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCareLabel ? Icons.dry_cleaning : Icons.checkroom,
                  color: const Color(0xFF1A39FF),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '스캔 완료!',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isCareLabel ? '케어라벨을 발견했어요' : '의류를 인식했어요',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 결과 확인하기 버튼 → 택 스캔 결과 화면(화면13)으로 이동
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewResult,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8FEAFD),
                foregroundColor: const Color(0xFF1D1B20),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '결과 확인하기',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 스캔 결과 화면 (케어라벨 & 의류 공용) ────────────────────
class _TagScanResultScreen extends StatelessWidget {
  final File? image;
  final _ScanMode mode;
  final ValueChanged<int>? onNavigate;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onReset;
  final VoidCallback onStartClothingScan;

  const _TagScanResultScreen({
    required this.image,
    required this.mode,
    required this.onNavigate,
    required this.onBack,
    required this.onSave,
    required this.onReset,
    required this.onStartClothingScan,
  });

  // 케어라벨 항목: (아이콘, 제목, 설명)
  static const _careItems = [
    (
      Icons.local_laundry_service_outlined,
      '세탁기 사용 가능',
      '30°C 이하의 미지근한 물에서 세탁기 사용 가능',
    ),
    (Icons.block, '표백제 사용 불가', '염소계 표백제 사용 금지'),
    (Icons.wb_sunny_outlined, '건조기 사용 가능', '저온 건조 가능'),
    (Icons.iron_outlined, '다리미 사용 불가', '열 손상 주의'),
    (Icons.dry_cleaning, '드라이클리닝 금지', '물세탁 방법으로만 세탁'),
  ];

  @override
  Widget build(BuildContext context) {
    final isCareLabel = mode == _ScanMode.careLabel;
    return isCareLabel
        ? _buildCareLabelResult(context)
        : _buildClothingResult(context);
  }

  // ── 케어라벨 스캔 결과 ────────────────────────────────────────
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
                  const Spacer(),
                  const Text(
                    '스캔 완료!',
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
                    // 스캔 이미지
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

                    // 세탁 기호 안내
                    const Text(
                      '세탁 기호 안내',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._careItems.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCF9FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item.$1,
                                size: 20,
                                color: const Color(0xFF1A39FF),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.$2,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A39FF),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.$3,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF1A39FF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _ResultActionButton(
                            label: '이미지 저장하기',
                            icon: Icons.download_outlined,
                            onTap: onReset,
                            isPrimary: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ResultActionButton(
                            label: '내 옷장에 등록하기',
                            onTap: onSave,
                            isPrimary: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 의류 스캔하기 (선택사항)
                    GestureDetector(
                      onTap: onStartClothingScan,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCF9FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            '의류 스캔하기',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1D1B20),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1A39FF),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              '선택사항',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        '의류 전체를 촬영하면\n더 정확한 관리법을 알려드려요!',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF1D1B20),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: Color(0xFF1D1B20),
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '소재/오염도/손상도까지 분석 가능',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF5D7A8A),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  // ── 의류 스캔 결과 ────────────────────────────────────────────
  Widget _buildClothingResult(BuildContext context) {
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
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1D1B20),
                    ),
                    onPressed: onBack,
                  ),
                  const Spacer(),
                  const Text(
                    '스캔 완료!',
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
                    // 스캔 이미지
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
                    const Text(
                      '데님 팬츠 · 면 98% / 폴리에스테르 2%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '내 옷의 등급은?',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1D1B20),
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    _ClothingMetricRow(
                                      label: '오염도',
                                      value: 0.10,
                                      color: Color(0xFF98DA9A),
                                      valueLabel: '10%',
                                    ),
                                    SizedBox(height: 14),
                                    _ClothingMetricRow(
                                      label: '손상도',
                                      value: 0.40,
                                      color: Color(0xFFB73D3D),
                                      valueLabel: '40%',
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
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'B',
                                      style: TextStyle(
                                        fontSize: 54,
                                        fontWeight: FontWeight.w300,
                                        height: 0.95,
                                        color: Color(0xFFF5B38A),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
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
                    const Text(
                      '기본적인 관리는 가능하지만 일부 주의가 필요해요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              '등급 기준',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: const Text(
                              'A등급: 일반적인 세탁과 관리로도 손상 위험이 낮아요.\n'
                              'B등급: 기본적인 관리는 가능하지만 일부 주의가 필요해요.\n'
                              'C등급: 세탁 방법이나 건조 방식에 따라 손상될 수 있어요.\n'
                              'D등급: 손상될 위험이 높아 세심한 관리가 필요해요.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1A39FF),
                                height: 1.7,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('확인'),
                              ),
                            ],
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Color(0xFF777777),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '등급 기준',
                              style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF777777),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: _ResultActionButton(
                            label: '이미지 저장하기',
                            icon: Icons.download_outlined,
                            onTap: onReset,
                            isPrimary: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ResultActionButton(
                            label: '커뮤니티로 공유하기',
                            icon: Icons.share_outlined,
                            onTap: () => showCommunityWriteSheet(context),
                            isPrimary: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: SizedBox(
                        width: 148,
                        child: _ResultActionButton(
                          label: '내 옷장에 등록하기',
                          onTap: onSave,
                          isPrimary: true,
                        ),
                      ),
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
}

class _ClothingMetricRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String valueLabel;

  const _ClothingMetricRow({
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

class _ResultActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final IconData? icon;

  const _ResultActionButton({
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
          borderRadius: BorderRadius.circular(14),
          border: isPrimary ? null : Border.all(color: const Color(0xFFE0E0E0)),
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

// ─── 모드 선택 칩 ────────────────────────────────────────────
class _ModeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF8FEAFD)
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0xFF8FEAFD)
                : Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? const Color(0xFF1D1B20) : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── 코너 데코레이션 ──────────────────────────────────────────
class _Corner extends StatelessWidget {
  final bool top;
  final bool left;
  const _Corner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? const BorderSide(color: Color(0xFF8FEAFD), width: 3)
              : BorderSide.none,
          bottom: !top
              ? const BorderSide(color: Color(0xFF8FEAFD), width: 3)
              : BorderSide.none,
          left: left
              ? const BorderSide(color: Color(0xFF8FEAFD), width: 3)
              : BorderSide.none,
          right: !left
              ? const BorderSide(color: Color(0xFF8FEAFD), width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }
}

// ─── 그리드 배경 ──────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0DFFFFFF)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
