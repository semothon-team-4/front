import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 세탁소/수선집 등록 (Figma 04 — 드롭다운 인라인)
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController(text: '경기도 수원시 영통구 반달로 74-1');
  final _descCtrl = TextEditingController();

  String? _selectedCategory;       // 세탁소 | 수선집
  String? _selectedClothingType;   // 상의, 하의, …
  double _minPrice = 0;
  double _maxPrice = 1000000;
  double _kindness = 0;
  double _satisfaction = 0;
  int _photoCount = 0;
  bool _showPriceSlider = false;

  // 카테고리별 옷 종류 목록
  static const _clothingTypeMap = {
    '세탁소': ['상의', '아우터', '하의', '신발', '가방', '모자'],
    '수선집': ['상의 수선', '하의 수선', '지퍼 교체', '단추 교체', '기장 수선', '가죽 수선'],
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addrCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('업체명을 입력해주세요');
      return;
    }
    if (_selectedCategory == null) {
      _snack('카테고리를 선택해주세요');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _RegisterCompleteScreen()),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final clothingTypes = _selectedCategory != null
        ? _clothingTypeMap[_selectedCategory!] ?? []
        : <String>[];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1D1B20)),
        centerTitle: true,
        title: const Text('등록하기',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1B20))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 사진 ──────────────────────────────────────
            const _Label('사진'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() {
                if (_photoCount < 10) _photoCount++;
              }),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFBDBDBD)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, size: 28, color: Color(0xFF1D1B20)),
                    Text('$_photoCount/10',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9E9E9E))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── 업체명 ────────────────────────────────────
            Row(
              children: [
                const _Label('업체명'),
                const Spacer(),
                ValueListenableBuilder(
                  valueListenable: _nameCtrl,
                  builder: (_, v, _) => Text('${v.text.length} / 40',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9E9E9E))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _textField(_nameCtrl,
                maxLength: 40, hint: '업체명을 입력하세요'),
            const SizedBox(height: 20),

            // ── 주소 ──────────────────────────────────────
            Row(
              children: [
                Expanded(child: _textField(_addrCtrl)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8FEAFD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, size: 14, color: Color(0xFF1D1B20)),
                      SizedBox(width: 4),
                      Text('위치 검색하기',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF1D1B20))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _textField(_descCtrl, maxLines: 4, hint: '업체 소개를 입력하세요'),
            const SizedBox(height: 24),

            const Divider(height: 1, color: Color(0xFFF0F0F0)),

            // ── 카테고리 드롭다운 ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  const _Label('카테고리'),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    hint: const Text('선택',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF9E9E9E))),
                    underline: const SizedBox.shrink(),
                    icon: const Icon(Icons.chevron_right,
                        size: 18, color: Color(0xFF9E9E9E)),
                    items: ['세탁소', '수선집']
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedCategory = v;
                      _selectedClothingType = null;
                    }),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),

            // ── 옷 종류 드롭다운 (카테고리 선택 시 표시) ───
            if (clothingTypes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    _Label('옷 종류 (${ _selectedCategory ?? ''})'),
                    const Spacer(),
                    DropdownButton<String>(
                      value: _selectedClothingType,
                      hint: const Text('선택',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF9E9E9E))),
                      underline: const SizedBox.shrink(),
                      icon: const Icon(Icons.chevron_right,
                          size: 18, color: Color(0xFF9E9E9E)),
                      items: clothingTypes
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedClothingType = v),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
            ],

            // ── 가격 (탭하면 슬라이더 토글) ───────────────
            InkWell(
              onTap: () =>
                  setState(() => _showPriceSlider = !_showPriceSlider),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    const _Label('가격'),
                    const Spacer(),
                    Text(
                      '${_minPrice.toInt()}원 ~ ${_maxPrice.toInt()}원',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF9E9E9E)),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showPriceSlider
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 18,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ],
                ),
              ),
            ),
            if (_showPriceSlider) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF8FEAFD),
                    inactiveTrackColor: const Color(0xFFE0E0E0),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 12),
                    overlayColor: const Color(0x298FEAFD),
                    trackHeight: 3,
                  ),
                  child: RangeSlider(
                    values: RangeValues(_minPrice, _maxPrice),
                    min: 0,
                    max: 1000000,
                    divisions: 100,
                    onChanged: (v) => setState(() {
                      _minPrice = v.start;
                      _maxPrice = v.end;
                    }),
                  ),
                ),
              ),
            ],
            const Divider(height: 1, color: Color(0xFFF0F0F0)),

            // ── 친절도 ────────────────────────────────────
            _RatingRow(
              label: '친절도',
              value: _kindness,
              onChanged: (v) => setState(() => _kindness = v),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),

            // ── 만족도 ────────────────────────────────────
            _RatingRow(
              label: '만족도',
              value: _satisfaction,
              onChanged: (v) => setState(() => _satisfaction = v),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8FEAFD),
                foregroundColor: const Color(0xFF1D1B20),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('등록하기',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl,
      {int? maxLength, int maxLines = 1, String? hint}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
        border: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
            borderSide:
                const BorderSide(color: Color(0xFF8FEAFD), width: 2),
            borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ─── 라벨 ────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1D1B20)));
}

// ─── 별점 행 ─────────────────────────────────────────────────
class _RatingRow extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  const _RatingRow(
      {required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _Label(label),
          const Spacer(),
          Row(
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => onChanged((i + 1).toDouble()),
              child: Icon(
                i < value ? Icons.star : Icons.star_border,
                size: 22,
                color: const Color(0xFFFFB300),
              ),
            )),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right,
              size: 18, color: Color(0xFF9E9E9E)),
        ],
      ),
    );
  }
}

// ─── 등록 완료 화면 (Figma 08) ────────────────────────────────
class _RegisterCompleteScreen extends StatelessWidget {
  const _RegisterCompleteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8FEAFD),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF1D1B20)),
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
              ),
            ),
            const Spacer(),
            const Text(
              '등록이 완료되었습니다!',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1B20)),
            ),
            const SizedBox(height: 12),
            const Text(
              '관리자가 검토 후 등록될 예정입니다.',
              style: TextStyle(fontSize: 14, color: Color(0xFF546E7A)),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
