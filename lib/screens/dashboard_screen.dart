import 'package:flutter/material.dart';
import 'community_screen.dart';
import '../widgets/seal_mascot.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int index) onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _tips = [
    '흰 옷은 세탁 후 직사광선에 말리면 누래질 수 있어요. 그늘에서 말려보세요!',
    '청바지는 뒤집어 세탁하면 색 빠짐을 줄일 수 있어요.',
    '니트류는 절대 비틀지 말고 눌러 짜서 건조하세요.',
    '세탁망 사용 시 옷감 손상을 80% 줄일 수 있어요.',
    '실크는 미지근한 물 + 중성세제로 손세탁이 최선이에요.',
    '드라이클리닝 표시가 있어도 손세탁 가능한 경우가 많아요. 라벨 꼭 확인!',
    '세탁기 찬물 코스가 색 유지에 가장 좋아요.',
  ];

  String get _todayTip => _tips[DateTime.now().day % _tips.length];

  Map<String, dynamic> get _weather {
    switch (DateTime.now().weekday) {
      case 6:
      case 7:
        return {
          'icon': Icons.wb_sunny_rounded,
          'temp': '22°C',
          'desc': '맑음',
          'laundry': '세탁하기 완벽한 날이에요!',
          'good': true,
        };
      case 3:
        return {
          'icon': Icons.water_drop_rounded,
          'temp': '14°C',
          'desc': '비',
          'laundry': '오늘은 세탁을 미뤄보세요',
          'good': false,
        };
      case 1:
      case 4:
        return {
          'icon': Icons.cloud_rounded,
          'temp': '18°C',
          'desc': '흐림',
          'laundry': '실내 건조를 권장해요',
          'good': false,
        };
      default:
        return {
          'icon': Icons.wb_cloudy_rounded,
          'temp': '20°C',
          'desc': '구름 조금',
          'laundry': '오전에 세탁하면 저녁엔 건조 완료!',
          'good': true,
        };
    }
  }

  final _hotPosts = const [
    {
      'user': '세탁왕김씨',
      'title': '청바지 색 빠짐 방지하는 비법 공유해요!',
      'content': '청바지 처음 세탁할 때 소금물에 30분 담가두면 색이 훨씬 덜 빠져요.',
      'likes': 128,
      'comments': 23,
      'category': '세탁팁',
      'time': '5분 전',
      'hasImage': true,
      'isLiked': false,
      'avatar': '🧺',
    },
    {
      'user': '패션피플',
      'title': '실크 세탁, 이렇게 하니까 망하지 않았어요',
      'content': '실크는 미지근한 물에 중성세제, 손으로 살살 세탁했더니 결이 살아있어요.',
      'likes': 204,
      'comments': 45,
      'category': '세탁팁',
      'time': '5시간 전',
      'hasImage': false,
      'isLiked': false,
      'avatar': '👗',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final weather = _weather;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? '좋은 아침이에요'
        : (hour < 18 ? '안녕하세요' : '좋은 저녁이에요');

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 헤더 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF90A4AE),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '닉네임1',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            SizedBox(width: 3),
                            Text(
                              '님',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF546E7A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            color: Color(0xFF546E7A),
                            size: 26,
                          ),
                          Positioned(
                            right: -1,
                            top: -1,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF5350),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFF0F7FF),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const _ProfileQuickView(),
                        ),
                      ),
                      child: Container(
                        width: 42,
                        height: 42,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF1565C0,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '닉',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 날씨 배너 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: weather['good'] as bool
                          ? [const Color(0xFF0D47A1), const Color(0xFF42A5F5)]
                          : [const Color(0xFF546E7A), const Color(0xFF90A4AE)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (weather['good'] as bool
                                    ? const Color(0xFF1565C0)
                                    : const Color(0xFF546E7A))
                                .withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  weather['icon'] as IconData,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${weather['desc']}  ${weather['temp']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              weather['laundry'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () => widget.onNavigate(1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.map_outlined,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      '근처 세탁소 찾기',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SealMascot(
                        helpText:
                            '날씨에 따라 최적 세탁일을 알려드려요!\n맑은 날 세탁 + 야외 건조가 최고예요',
                        size: 64,
                      ),
                    ],
                  ),
                ),
              ),

              // ── 빠른 실행 ──
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Text(
                  '빠른 실행',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    _QuickAction(
                      icon: Icons.qr_code_scanner_rounded,
                      label: '케어라벨\n스캔',
                      color: const Color(0xFF1565C0),
                      onTap: () => widget.onNavigate(2),
                    ),
                    const SizedBox(width: 10),
                    _QuickAction(
                      icon: Icons.location_on_rounded,
                      label: '세탁소\n지도',
                      color: const Color(0xFF0288D1),
                      onTap: () => widget.onNavigate(1),
                    ),
                    const SizedBox(width: 10),
                    _QuickAction(
                      icon: Icons.checkroom_rounded,
                      label: '내\n옷장',
                      color: const Color(0xFF3949AB),
                      onTap: () => widget.onNavigate(3),
                    ),
                    const SizedBox(width: 10),
                    _QuickAction(
                      icon: Icons.forum_rounded,
                      label: '커뮤\n니티',
                      color: const Color(0xFF00897B),
                      onTap: () => widget.onNavigate(4),
                    ),
                  ],
                ),
              ),

              // ── 옷장 현황 ──
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Text(
                  '내 옷장 현황',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: GestureDetector(
                  onTap: () => widget.onNavigate(3),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF1565C0,
                          ).withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.checkroom_rounded,
                              color: Color(0xFF1565C0),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '총 6벌 등록됨',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            Spacer(),
                            Text(
                              '전체보기',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF90A4AE),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: Color(0xFF90A4AE),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _GradePill(
                              label: 'A',
                              value: 2,
                              color: const Color(0xFF43A047),
                            ),
                            const SizedBox(width: 8),
                            _GradePill(
                              label: 'B',
                              value: 2,
                              color: const Color(0xFF1E88E5),
                            ),
                            const SizedBox(width: 8),
                            _GradePill(
                              label: 'C',
                              value: 1,
                              color: const Color(0xFFFB8C00),
                            ),
                            const SizedBox(width: 8),
                            _GradePill(
                              label: 'D',
                              value: 1,
                              color: const Color(0xFFE53935),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFFFFCC02,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFFB8C00),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '세탁이 필요한 옷이 2벌 있어요',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFE65100),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Spacer(),
                              Text(
                                '확인하기',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFFB8C00),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── 오늘의 세탁 팁 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF90CAF9).withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1565C0,
                          ).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lightbulb_rounded,
                          color: Color(0xFF1565C0),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '오늘의 세탁 팁',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _todayTip,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF37474F),
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 커뮤니티 인기 글 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: Row(
                  children: [
                    const Text(
                      '커뮤니티 인기 글',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => widget.onNavigate(4),
                      child: const Row(
                        children: [
                          Text(
                            '더보기',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF90A4AE),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Color(0xFF90A4AE),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  children: _hotPosts
                      .map(
                        (post) => _HotPostCard(
                          post: post,
                          onTap: () => openCommunityPostDetail(context, post),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 빠른 실행 버튼 ──────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF546E7A),
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 등급 pill ───────────────────────────────────────────────
class _GradePill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _GradePill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value벌',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '$label등급',
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 핫 포스트 카드 ──────────────────────────────────────────
class _HotPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;
  const _HotPostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const catColors = {
      '세탁팁': Color(0xFF1565C0),
      '수선': Color(0xFFE91E63),
      '제품추천': Color(0xFF43A047),
      '의류상태': Color(0xFFFB8C00),
    };
    final cat = post['category'] as String;
    final catColor = catColors[cat] ?? Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  post['avatar'] as String,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 10,
                            color: catColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          post['user'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFB0BEC5),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: onTap,
                    child: Text(
                      post['title'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A237E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 14,
                  color: Color(0xFFEF5350),
                ),
                const SizedBox(width: 3),
                Text(
                  '${post['likes']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFEF5350),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 프로필 간단 뷰 ──────────────────────────────────────────
class _ProfileQuickView extends StatelessWidget {
  const _ProfileQuickView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: const Text('프로필'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A237E),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '닉',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '닉네임1',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'nickname1@caretag.com',
                    style: TextStyle(fontSize: 13, color: Color(0xFF90A4AE)),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      _StatItem(label: '등록 의류', value: '6'),
                      _Divider(),
                      _StatItem(label: '스캔 횟수', value: '12'),
                      _Divider(),
                      _StatItem(label: '작성 글', value: '3'),
                      _Divider(),
                      _StatItem(label: '받은 좋아요', value: '48'),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _ProfileMenuIcon(
                      icon: Icons.favorite_outline,
                      label: '찜 매장',
                    ),
                    _ProfileMenuIcon(
                      icon: Icons.chat_bubble_outline,
                      label: '리뷰 내역',
                    ),
                    _ProfileMenuIcon(
                      icon: Icons.bookmark_outline,
                      label: '저장 매장',
                    ),
                    _ProfileMenuIcon(
                      icon: Icons.article_outlined,
                      label: '최근 본 글',
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

class _ProfileMenuIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileMenuIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFDCF9FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 22, color: const Color(0xFF1D1B20)),
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
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF90A4AE)),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: const Color(0xFFECEFF1));
  }
}
