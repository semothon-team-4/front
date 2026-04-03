import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/analysis_result_view.dart';
import '../services/analysis_service.dart';
import '../services/image_service.dart';

// --- 케어라벨 스캔 화면 ---
class CareLabelScanScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const CareLabelScanScreen({super.key, this.onNavigate});

  @override
  State<CareLabelScanScreen> createState() => _CareLabelScanScreenState();
}

class _CareLabelScanScreenState extends State<CareLabelScanScreen>
    with SingleTickerProviderStateMixin {
  File? _scannedImage;
  Map<String, dynamic>? _analysisResult;
  bool _isAnalyzing = false;
  bool _scanComplete = false;
  int _resultPage = -1;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickAndScan(ImageSource source) async {
    final file = await ImageService.pickImage(source);
    if (file == null) return;
    setState(() {
      _scannedImage = file;
      _analysisResult = null;
      _isAnalyzing = true;
      _scanComplete = false;
      _resultPage = -1;
    });
    try {
      // 케어라벨 스캔 시뮬레이션
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _scanComplete = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _scanComplete = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _reset() => setState(() {
    _scannedImage = null;
    _analysisResult = null;
    _isAnalyzing = false;
    _scanComplete = false;
    _resultPage = -1;
  });

  Future<void> _saveImage() async {
    if (_scannedImage == null) return;
    try {
      final now = DateTime.now();
      await ImageService.saveImageLocally(
        _scannedImage!,
        'scan_label_${now.millisecondsSinceEpoch}.jpg',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('이미지가 갤러리에 저장되었어요!'),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resultPage == 0) {
      return AnalysisResultView(
        image: _scannedImage,
        isCareLabel: true,
        analysisResult: _analysisResult,
        onNavigate: widget.onNavigate,
        onBack: () => setState(() => _resultPage = -1),
        onSave: _saveToWardrobe,
        onReset: _reset,
        onSaveImage: _saveImage,
        onStartClothingScan: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ClothingScanScreen(onNavigate: widget.onNavigate),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A2340),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2340),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '케어라벨 SCAN',
          style: TextStyle(
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
          Positioned.fill(
            bottom: _scanComplete ? 200 : 0,
            child: _scannedImage != null
                ? Image.file(_scannedImage!, fit: BoxFit.cover)
                : _buildViewfinder(),
          ),
          if (_isAnalyzing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF8FEAFD)),
                      SizedBox(height: 20),
                      Text('분석 중...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          if (_scanComplete)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ScanCompleteCard(
                isCareLabel: true,
                onViewResult: () => setState(() => _resultPage = 0),
              ),
            ),
          if (!_scanComplete && !_isAnalyzing && _scannedImage == null)
            _buildShutter(context),
        ],
      ),
    );
  }

  Widget _buildShutter(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 48,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF363737),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '케어라벨이 선명하게 보이도록 찍어주세요',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLargeIconButton(
                icon: Icons.photo_library_outlined,
                onTap: () => _pickAndScan(ImageSource.gallery),
              ),
              const SizedBox(width: 40),
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
              const SizedBox(width: 84),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
        child: Icon(icon, color: Colors.white, size: 20),
      ),
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
                value: selected,
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
      try {
        if (_scannedImage != null) {
          await ImageService.saveImageLocally(
            _scannedImage!,
            'scan_${now.millisecondsSinceEpoch}.jpg',
          );
        }
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text('"$name"이(가) 옷장에 저장되었어요!'),
              ],
            ),
            backgroundColor: const Color(0xFF1A39FF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        widget.onNavigate?.call(1);
      }
    }
    nameCtrl.dispose();
    categoryNotifier.dispose();
  }

  Widget _buildViewfinder() {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(painter: _GridPainter(), child: const SizedBox.expand()),
        // main 스타일의 원형 가이드라인
        CircleAvatar(
          radius: 120,
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF8FEAFD).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- 의류 스캔 화면 ---
class ClothingScanScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigate;
  const ClothingScanScreen({super.key, this.onNavigate});

  @override
  State<ClothingScanScreen> createState() => _ClothingScanScreenState();
}

class _ClothingScanScreenState extends State<ClothingScanScreen>
    with SingleTickerProviderStateMixin {
  File? _scannedImage;
  Map<String, dynamic>? _analysisResult;
  bool _isAnalyzing = false;
  bool _scanComplete = false;
  int _resultPage = -1;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickAndScan(ImageSource source) async {
    final file = await ImageService.pickImage(source);
    if (file == null) return;
    setState(() {
      _scannedImage = file;
      _analysisResult = null;
      _isAnalyzing = true;
      _scanComplete = false;
      _resultPage = -1;
    });
    try {
      // ─── [임시 처리 시작] 실제 백엔드 요청 대신 더미 데이터 사용 ──────────────────
      /*
      final result = await AnalysisService.requestAnalysis(
        image: file,
        name: '스캔한 의류',
        category: '기타',
      );
      */
      await Future.delayed(const Duration(seconds: 2)); // 분석 시뮬레이션
      final result = {
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'name': '스캔한 화이트 셔츠',
        'category': '상의',
        'grade': 'B',
        'lastCare': '2024.03.20',
        'imagePath': file.path,
        'iconColor': const Color(0xFF64B5F6),
        'stainLevel': 10,
        'damageLevel': 40,
        'recommendation': '기본적인 관리는 가능하지만 일부 주의가 필요해요.',
        'guideTitle': '전반적으로 양호한 상태예요. 다만 무릎 부위 등에 경미한 오염이 발견되었습니다.',
        'guideTip': '데님은 접어서 서랍에 보관하거나 허리 부분을 집게로 잡아 걸어두면 형태 유지에 좋습니다.',
        'careLabels': [
          {'name': '물세탁 가능', 'icon': 'water_wash', 'desc': '30도 이하 미지근한 물'},
          {'name': '표백 금지', 'icon': 'no_bleach', 'desc': '염소계 표백제 사용 불가'},
        ],
      };
      // ─── [임시 처리 끝] ─────────────────────────────────────────────────────────────
      if (!mounted) return;
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
        _scanComplete = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _scanComplete = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _reset() => setState(() {
    _scannedImage = null;
    _analysisResult = null;
    _isAnalyzing = false;
    _scanComplete = false;
    _resultPage = -1;
  });

  Future<void> _saveImage() async {
    if (_scannedImage == null) return;
    try {
      final now = DateTime.now();
      await ImageService.saveImageLocally(
        _scannedImage!,
        'scan_cloth_${now.millisecondsSinceEpoch}.jpg',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('이미지가 갤러리에 저장되었어요!'),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resultPage == 0) {
      return AnalysisResultView(
        image: _scannedImage,
        isCareLabel: false,
        analysisResult: _analysisResult,
        onNavigate: widget.onNavigate,
        onBack: () => setState(() => _resultPage = -1),
        onSave: _saveToWardrobe,
        onReset: _reset,
        onSaveImage: _saveImage,
        onStartClothingScan: () {},
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A2340),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2340),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '의류 SCAN',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _scannedImage != null
                ? Image.file(_scannedImage!, fit: BoxFit.cover)
                : _buildViewfinder(),
          ),
          if (_isAnalyzing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF8FEAFD)),
                      SizedBox(height: 20),
                      Text('분석 중...', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          if (_scanComplete)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ScanCompleteCard(
                isCareLabel: false,
                onViewResult: () => setState(() => _resultPage = 0),
              ),
            ),
          if (!_scanComplete && !_isAnalyzing && _scannedImage == null)
            _buildShutter(context),
        ],
      ),
    );
  }

  Widget _buildShutter(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 48,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF363737),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '의류 전체가 보이도록 찍어주세요',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLargeIconButton(
                icon: Icons.photo_library_outlined,
                onTap: () => _pickAndScan(ImageSource.gallery),
              ),
              const SizedBox(width: 40),
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
              const SizedBox(width: 84),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildViewfinder() {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(painter: _GridPainter(), child: const SizedBox.expand()),
        CircleAvatar(
          radius: 120,
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF8FEAFD).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveToWardrobe() async {
    final name = (_analysisResult?['name'] as String?) ?? '스캔한 의류';
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text('"$name"이(가) 내 옷장에 등록되었어요!'),
          ],
        ),
        backgroundColor: const Color(0xFF1A39FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    widget.onNavigate?.call(1);
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}

// --- 스캔 완료 카드 ---
class _ScanCompleteCard extends StatelessWidget {
  final bool isCareLabel;
  final VoidCallback onViewResult;

  const _ScanCompleteCard({
    required this.isCareLabel,
    required this.onViewResult,
  });

  @override
  Widget build(BuildContext context) {
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
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF8FEAFD).withValues(alpha: 0.1),
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
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewResult,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A39FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '결과 확인하기',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
