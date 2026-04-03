import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'wardrobe_screen.dart';
import 'scan_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _wardrobeRefresh = 0;
  // 한 번이라도 방문한 탭 인덱스 추적 → 방문 전 탭은 아예 빌드 안 함
  final Set<int> _visited = {0};

  void _navigateTo(int index) {
    setState(() {
      if (index == 1) _wardrobeRefresh++;
      _currentIndex = index;
      _visited.add(index);
    });
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0: return const MapScreen();
      case 1: return WardrobeScreen(onNavigate: _navigateTo, refreshSignal: _wardrobeRefresh);
      case 2: return CareLabelScanScreen(onNavigate: _navigateTo);
      case 3: return const CommunityScreen();
      case 4: return const ProfileScreen();
      default: return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: List.generate(5, (index) {
          // 한 번도 방문 안 한 탭은 렌더링 자체를 안 함
          if (!_visited.contains(index)) return const SizedBox.shrink();
          return Offstage(
            offstage: _currentIndex != index,
            child: TickerMode(
              enabled: _currentIndex == index,
              child: _buildScreen(index),
            ),
          );
        }),
      ),
      bottomNavigationBar: _FigmaBottomNav(
        currentIndex: _currentIndex,
        onTap: _navigateTo,
      ),
    );
  }
}

class _FigmaBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _FigmaBottomNav({required this.currentIndex, required this.onTap});

  static const _navItems = [
    (icon: Icons.location_on_rounded,  label: '지도',    index: 0),
    (icon: Icons.dry_cleaning_rounded, label: '옷장',    index: 1),
    (icon: Icons.camera_alt_rounded,   label: '스캔',    index: 2),
    (icon: Icons.group_rounded,        label: '커뮤니티', index: 3),
    (icon: Icons.person_rounded,       label: '프로필',  index: 4),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF8FEAFD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      height: 64 + bottomPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _navItems.map((item) {
          final isActive = currentIndex == item.index;
          return GestureDetector(
            onTap: () => onTap(item.index),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: 24,
                    color: isActive
                        ? const Color(0xFF1D1B20)
                        : const Color(0xFF1D1B20).withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive
                          ? const Color(0xFF1D1B20)
                          : const Color(0xFF1D1B20).withValues(alpha: 0.45),
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
