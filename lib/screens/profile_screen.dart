import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _nickname = 'rlaalswn12340';
  File? _profileImage;
  bool _pushEnabled = true;
  bool _laundryAlarm = true;
  bool _communityAlarm = false;
  late final TextEditingController _nicknameCtrl;

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController(text: _nickname);
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  // ── 프로필 사진 변경 ──────────────────────────────────────────
  Future<void> _pickProfileImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
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
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: Color(0xFF1A39FF),
              ),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_profileImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('사진 삭제', style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() => _profileImage = null);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  // ── 닉네임 수정 다이얼로그 ────────────────────────────────────
  Future<void> _editNickname() async {
    _nicknameCtrl
      ..text = _nickname
      ..selection = TextSelection.collapsed(offset: _nickname.length);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('닉네임 수정'),
        content: TextField(
          controller: _nicknameCtrl,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(
            hintText: '닉네임을 입력하세요',
            filled: true,
            fillColor: const Color(0xFFF8FAFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final nextNickname = _nicknameCtrl.text.trim();
              Navigator.pop(ctx, nextNickname);
            },
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
    if (!mounted) return;
    if (result != null && result.isNotEmpty) {
      setState(() => _nickname = result);
    }
  }

  // ── 탈퇴 확인 다이얼로그 ─────────────────────────────────────
  Future<void> _confirmWithdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('탈퇴하기'),
        content: const Text('정말 탈퇴하시겠어요?\n탈퇴 시 모든 데이터가 삭제되며\n복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('탈퇴가 완료되었습니다.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCF9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1D1B20), size: 22),
          onPressed: () {},
        ),
        centerTitle: true,
        title: const Text(
          '프로필',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1B20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            // ── 프로필 카드 ──
            // 아바타가 카드 상단에서 절반 튀어나오도록 Stack 사용
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // 흰 카드 (아바타 절반 높이만큼 상단 패딩)
                Container(
                  margin: const EdgeInsets.only(top: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.only(top: 50, bottom: 20),
                  child: Center(
                    child: GestureDetector(
                      onTap: _editNickname,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _nickname,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D1B20),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.edit,
                            size: 14,
                            color: Color(0xFF9E9E9E),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 아바타 (카드 상단에서 절반 튀어나옴)
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDBF4F9),
                          shape: BoxShape.circle,
                        ),
                        child: _profileImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _profileImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : ClipOval(
                                child: Image.asset(
                                  'assets/images/profile_default.png',
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                ),
                              ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFF8FEAFD),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 13,
                            color: Color(0xFF1D1B20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── 빠른 메뉴 ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickMenu(
                    imagePath: 'assets/images/profile_quick_favorite.png',
                    label: '찜 매장',
                    onTap: () {},
                  ),
                  _QuickMenu(
                    imagePath: 'assets/images/profile_quick_review.png',
                    label: '리뷰 내역',
                    onTap: () {},
                  ),
                  _QuickMenu(
                    imagePath: 'assets/images/profile_quick_saved.png',
                    label: '저장 매장',
                    onTap: () {},
                  ),
                  _QuickMenu(
                    imagePath: 'assets/images/profile_quick_recent.png',
                    label: '최근 본 글',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 계정 관리 메뉴 카드 ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Text(
                      '내 계정 관리',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                  ),
                  _item(
                    '알림 설정',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _NotificationScreen(
                          pushEnabled: _pushEnabled,
                          laundryAlarm: _laundryAlarm,
                          communityAlarm: _communityAlarm,
                          onChanged: (push, laundry, community) => setState(() {
                            _pushEnabled = push;
                            _laundryAlarm = laundry;
                            _communityAlarm = community;
                          }),
                        ),
                      ),
                    ),
                  ),
                  _item(
                    '1:1 문의하기',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _InquiryScreen()),
                    ),
                  ),
                  _item(
                    '앱 버전',
                    trailing: const Text(
                      'v1.0.0',
                      style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                    ),
                    onTap: null,
                  ),
                  _item(
                    '이용약관',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _TermsScreen()),
                    ),
                  ),
                  _item(
                    '자주 묻는 질문',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const _FaqScreen()),
                    ),
                  ),
                  _item('탈퇴하기', isRed: true, onTap: _confirmWithdraw),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    String label, {
    VoidCallback? onTap,
    Widget? trailing,
    bool isRed = false,
  }) {
    return Column(
      children: [
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 2,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isRed ? const Color(0xFFEF5350) : const Color(0xFF1D1B20),
            ),
          ),
          trailing:
              trailing ??
              Icon(
                Icons.chevron_right,
                size: 20,
                color: isRed
                    ? const Color(0xFFEF5350)
                    : const Color(0xFF9E9E9E),
              ),
          onTap: onTap,
        ),
      ],
    );
  }
}

// ─── 알림 설정 화면 ───────────────────────────────────────────
class _NotificationScreen extends StatefulWidget {
  final bool pushEnabled;
  final bool laundryAlarm;
  final bool communityAlarm;
  final void Function(bool push, bool laundry, bool community) onChanged;

  const _NotificationScreen({
    required this.pushEnabled,
    required this.laundryAlarm,
    required this.communityAlarm,
    required this.onChanged,
  });

  @override
  State<_NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<_NotificationScreen> {
  late bool _push;
  late bool _laundry;
  late bool _community;

  @override
  void initState() {
    super.initState();
    _push = widget.pushEnabled;
    _laundry = widget.laundryAlarm;
    _community = widget.communityAlarm;
  }

  @override
  void dispose() {
    widget.onChanged(_push, _laundry, _community);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCF9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1D1B20)),
        centerTitle: true,
        title: const Text(
          '알림 설정',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1B20),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToggleTile(
                icon: Icons.notifications_outlined,
                label: '푸시 알림',
                subtitle: '모든 알림을 켜거나 끕니다',
                value: _push,
                onChanged: (v) => setState(() => _push = v),
              ),
              const Divider(height: 1, indent: 20, endIndent: 20),
              _ToggleTile(
                icon: Icons.local_laundry_service_outlined,
                label: '세탁 리마인더',
                subtitle: '세탁이 필요한 의류 알림',
                value: _push ? _laundry : false,
                onChanged: _push ? (v) => setState(() => _laundry = v) : null,
              ),
              const Divider(height: 1, indent: 20, endIndent: 20),
              _ToggleTile(
                icon: Icons.people_outline,
                label: '커뮤니티 알림',
                subtitle: '댓글, 좋아요 알림',
                value: _push ? _community : false,
                onChanged: _push ? (v) => setState(() => _community = v) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(
        icon,
        color: onChanged != null
            ? const Color(0xFF1A39FF)
            : const Color(0xFFBDBDBD),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: onChanged != null
              ? const Color(0xFF1D1B20)
              : const Color(0xFF9E9E9E),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF1A39FF),
        activeTrackColor: const Color(0xFF8FEAFD),
      ),
    );
  }
}

// ─── 1:1 문의하기 화면 ────────────────────────────────────────
class _InquiryScreen extends StatefulWidget {
  const _InquiryScreen();

  @override
  State<_InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<_InquiryScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _category = '서비스 문의';

  static const _categories = ['서비스 문의', '버그 신고', '계정 문제', '결제 문의', '기타'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제목과 내용을 모두 입력해 주세요')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('문의가 접수되었습니다. 빠른 시일 내 답변드리겠습니다.'),
        backgroundColor: const Color(0xFF1A39FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCF9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1D1B20)),
        centerTitle: true,
        title: const Text(
          '1:1 문의하기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1B20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 카테고리
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: '문의 유형',
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
            ),
            const SizedBox(height: 12),
            // 제목
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: '제목',
                  hintText: '문의 제목을 입력하세요',
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 내용
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _contentCtrl,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: '내용',
                  hintText: '문의 내용을 자세히 입력해 주세요\n\n답변은 이메일로 전달드립니다.',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8FEAFD),
                  foregroundColor: const Color(0xFF1D1B20),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '문의 접수',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 이용약관 화면 ─────────────────────────────────────────────
class _TermsScreen extends StatelessWidget {
  const _TermsScreen();

  static const _terms = '''
제1조 (목적)
본 약관은 clothesUp(이하 "서비스")의 이용 조건 및 절차, 이용자와 서비스 간의 권리·의무 및 책임 사항을 규정함을 목적으로 합니다.

제2조 (정의)
① "서비스"란 의류 케어라벨 스캔, 세탁소 탐색, 커뮤니티 등 제공되는 모든 기능을 말합니다.
② "이용자"란 본 약관에 동의하고 서비스를 이용하는 자를 말합니다.

제3조 (약관의 효력 및 변경)
① 본 약관은 서비스 화면에 게시함으로써 효력이 발생합니다.
② 서비스는 필요한 경우 약관을 변경할 수 있으며, 변경 시 앱 내 공지합니다.

제4조 (서비스 이용)
① 서비스는 연중무휴 24시간 제공을 원칙으로 합니다.
② 시스템 점검 등 불가피한 사유로 서비스가 일시 중단될 수 있습니다.

제5조 (개인정보 보호)
서비스는 이용자의 개인정보를 관련 법령에 따라 보호합니다. 자세한 내용은 개인정보처리방침을 참고하세요.

제6조 (이용자 의무)
① 이용자는 타인의 개인정보를 무단으로 수집·이용하여서는 안 됩니다.
② 서비스의 정상적인 운영을 방해하는 행위를 하여서는 안 됩니다.

제7조 (서비스 이용 제한)
서비스는 이용자가 본 약관을 위반한 경우 서비스 이용을 제한할 수 있습니다.

제8조 (면책 조항)
서비스는 천재지변, 불가항력적 사유로 인한 서비스 중단에 대해 책임을 지지 않습니다.

부칙
본 약관은 2025년 1월 1일부터 시행합니다.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCF9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1D1B20)),
        centerTitle: true,
        title: const Text(
          '이용약관',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1B20),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Text(
              _terms,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF616161),
                height: 1.7,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 자주 묻는 질문 화면 ──────────────────────────────────────
class _FaqScreen extends StatefulWidget {
  const _FaqScreen();

  @override
  State<_FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<_FaqScreen> {
  static const _faqs = [
    (
      q: '케어라벨 스캔이 제대로 안 됩니다.',
      a: '조명이 밝은 곳에서 라벨이 화면 프레임 안에 완전히 들어오도록 맞춰주세요. 구겨진 라벨은 펴서 촬영하면 인식률이 높아집니다.',
    ),
    (
      q: '내 옷장에 등록한 의류가 사라졌어요.',
      a: '앱을 재설치하면 로컬 데이터가 초기화될 수 있습니다. 중요한 데이터는 정기적으로 백업하는 것을 권장합니다.',
    ),
    (
      q: '지도에서 세탁소 정보가 최신이 아닌 것 같아요.',
      a: '등록된 정보와 실제 정보가 다를 수 있습니다. "+ 업체 등록" 또는 "리뷰" 기능으로 최신 정보를 공유해 주시면 감사합니다.',
    ),
    (q: '닉네임은 어떻게 변경하나요?', a: '프로필 화면에서 닉네임 옆 편집 아이콘을 탭하면 변경할 수 있습니다.'),
    (q: '커뮤니티 게시글을 삭제하고 싶어요.', a: '내 게시글을 길게 누르거나 상세 화면에서 삭제 옵션을 선택하세요.'),
    (
      q: '알림이 오지 않아요.',
      a: '프로필 → 알림 설정에서 알림이 켜져 있는지 확인하고, 기기의 앱 알림 허용 설정도 확인해 주세요.',
    ),
  ];

  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCF9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1D1B20)),
        centerTitle: true,
        title: const Text(
          '자주 묻는 질문',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1B20),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.white,
            child: ListView.separated(
              itemCount: _faqs.length,
              separatorBuilder: (_, x) =>
                  const Divider(height: 1, indent: 20, endIndent: 20),
              itemBuilder: (_, i) {
                final faq = _faqs[i];
                final open = _expanded.contains(i);
                return Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 20),
                    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    title: Text(
                      faq.q,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: open
                            ? const Color(0xFF1A39FF)
                            : const Color(0xFF1D1B20),
                      ),
                    ),
                    trailing: Icon(
                      open ? Icons.remove : Icons.add,
                      size: 18,
                      color: open
                          ? const Color(0xFF1A39FF)
                          : const Color(0xFF9E9E9E),
                    ),
                    onExpansionChanged: (v) => setState(
                      () => v ? _expanded.add(i) : _expanded.remove(i),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCF9FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          faq.a,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF616161),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 빠른 메뉴 아이템 ─────────────────────────────────────────
class _QuickMenu extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const _QuickMenu({
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF1D1B20),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
