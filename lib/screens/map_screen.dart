import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../services/business_store_service.dart';
import '../services/shop_service.dart';
import 'register_screen.dart';
import 'community_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _selectedType = 0; // 0=전체, 1=세탁소, 2=수선집
  int _sortMode = 0; // 0=거리순, 1=인기순, 2=평점순
  Map<String, dynamic>? _selectedBusiness; // 선택된 가게
  String _searchQuery = '';
  bool _showOnlyLiked = false;
  final _searchCtrl = TextEditingController();
  final _sheetController = DraggableScrollableController();
  bool _isLoadingShops = true;

  @override
  void initState() {
    super.initState();
    _loadNearbyShops();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  // 경희대학교 국제캠퍼스 / 영통역 기준 고정 좌표
  static const _fixedLat = 37.2430;
  static const _fixedLng = 127.0760;

  List<Map<String, dynamic>> get _businesses =>
      BusinessStoreService.getBusinesses();

  Future<void> _loadNearbyShops() async {
    try {
      final shops = await ShopService.fetchNearbyShops(
        lat: _fixedLat,
        lng: _fixedLng,
      );
      final mapped = shops.map((shop) {
        final lat = (shop['lat'] as num?)?.toDouble() ?? _fixedLat;
        final lng = (shop['lng'] as num?)?.toDouble() ?? _fixedLng;
        final distanceM = (_distanceBetweenMeters(
          _fixedLat,
          _fixedLng,
          lat,
          lng,
        )).round();
        return {
          'id': shop['id'],
          'placeId': shop['placeId'] ?? '',
          'name': shop['name'],
          'type': _inferType(shop['name'] as String? ?? ''),
          'rating': 0.0,
          'reviews': 0,
          'likes': 0,
          'isLiked': false,
          'isVerified': false,
          'distance': _formatDistance(distanceM),
          'distanceM': distanceM,
          'address': shop['address'] ?? '',
          'tags': <String>[],
          'isOpen': true,
          'hours': '영업 정보 없음',
          'lat': lat,
          'lng': lng,
          'imagePath': null,
        };
      }).toList();
      BusinessStoreService.syncBusinesses(mapped);
    } catch (_) {
      // Fallback to local seed data when API is unavailable.
    } finally {
      if (mounted) {
        setState(() => _isLoadingShops = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredAndSorted {
    var list = _selectedType == 0
        ? List<Map<String, dynamic>>.from(_businesses)
        : _businesses
              .where((b) => b['type'] == (_selectedType == 1 ? '세탁소' : '수선집'))
              .toList();
    // 좋아요 필터
    if (_showOnlyLiked) {
      list = list.where((b) => b['isLiked'] == true).toList();
    }
    // 검색어 필터
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (b) =>
                (b['name'] as String).toLowerCase().contains(q) ||
                (b['address'] as String).toLowerCase().contains(q) ||
                (b['tags'] as List).any(
                  (t) => t.toString().toLowerCase().contains(q),
                ),
          )
          .toList();
    }
    switch (_sortMode) {
      case 1: // 인기순
        list.sort((a, b) => (b['likes'] as int).compareTo(a['likes'] as int));
      case 2: // 평점순
        list.sort(
          (a, b) => (b['rating'] as double).compareTo(a['rating'] as double),
        );
      default: // 거리순
        list.sort(
          (a, b) => (a['distanceM'] as int).compareTo(b['distanceM'] as int),
        );
    }
    return list;
  }

  void _toggleLike(String name) {
    setState(() {
      BusinessStoreService.toggleLike(name);
      if (_selectedBusiness != null && _selectedBusiness!['name'] == name) {
        _selectedBusiness = _businesses.firstWhere((x) => x['name'] == name);
      }
    });
  }

  String _inferType(String name) {
    if (name.contains('수선')) return '수선집';
    return '세탁소';
  }

  String _formatDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
    return '${meters}m';
  }

  double _distanceBetweenMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            (sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double degree) => degree * 3.141592653589793 / 180.0;

  @override
  Widget build(BuildContext context) {
    final sorted = _filteredAndSorted;
    return Scaffold(
      body: Stack(
        children: [
          if (_isLoadingShops)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A39FF)),
            )
          else
            // ── 네이버 지도 ────────────────────────────────────
            NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: NLatLng(_fixedLat, _fixedLng),
                  zoom: 15,
                ),
                mapType: NMapType.basic,
                activeLayerGroups: [NLayerGroup.building, NLayerGroup.transit],
              ),
              onMapReady: (controller) async {
                if (!context.mounted) return;
                await controller.updateCamera(
                  NCameraUpdate.withParams(
                    target: const NLatLng(_fixedLat, _fixedLng),
                    zoom: 15,
                  ),
                );
                if (!context.mounted) return;

                // ── 내 위치 마커 ──
                final myLocIcon = await NOverlayImage.fromWidget(
                  context: context,
                  size: const Size(26, 26),
                  widget: const _MyLocationDot(),
                );
                if (!context.mounted) return;
                await controller.addOverlay(
                  NMarker(
                    id: 'my_location',
                    position: const NLatLng(_fixedLat, _fixedLng),
                    icon: myLocIcon,
                  ),
                );

                // ── 업체 마커 ──
                for (final b in _businesses) {
                  if (!context.mounted) return;
                  final isLaundry = b['type'] == '세탁소';
                  final isVerified = b['isVerified'] ?? false;
                  final icon = await NOverlayImage.fromWidget(
                    context: context,
                    size: const Size(46, 46),
                    widget: _BusinessMarkerIcon(
                      isLaundry: isLaundry,
                      isVerified: isVerified,
                    ),
                  );
                  if (!context.mounted) return;
                  final marker = NMarker(
                    id: b['name'] as String,
                    position: NLatLng(b['lat'] as double, b['lng'] as double),
                    icon: icon,
                  );
                  marker.setOnTapListener(
                    (_) => setState(() => _selectedBusiness = b),
                  );
                  await controller.addOverlay(marker);
                }
              },
            ),

          // ── 상단 정보 바 (영통1동) ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.black, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    '영통1동',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.menu, color: Colors.black, size: 28),
                ],
              ),
            ),
          ),

          // ── 우측 플로팅 버튼 (내 위치) ──
          // 하단 시트의 상단을 따라 다님 (AnimatedBuilder로 성능 최적화)
          if (_selectedBusiness == null)
            AnimatedBuilder(
              animation: _sheetController,
              builder: (context, _) {
                final extent = _sheetController.isAttached
                    ? _sheetController.size
                    : 0.35;
                final screenH = MediaQuery.of(context).size.height;
                final fabBottom = screenH * extent + 16;
                final searchBarBottom = 172.0;
                final fabTop = screenH - fabBottom - 44;
                final isCollision = fabTop < searchBarBottom + 60;

                return Positioned(
                  right: 16,
                  bottom: fabBottom,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isCollision ? 0 : 1,
                    child: _FloatingMapButton(icon: Icons.my_location_outlined),
                  ),
                );
              },
            ),

          // ── 상단 검색바 ────────────────────────────────────
          Positioned(
            top: 120, // 위치 조정
            left: 16,
            right: 16,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.menu, color: Color(0xFF1D1B20), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: const InputDecoration(
                        hintText: '세탁소, 수선집 검색',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF9E9E9E),
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                  ),
                  const Icon(Icons.search, color: Color(0xFF1D1B20), size: 24),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),

          // ── 선택된 가게 컴팩트 카드 ────────────────────────
          if (_selectedBusiness != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BusinessCompactCard(
                business: _selectedBusiness!,
                onClose: () => setState(() => _selectedBusiness = null),
                onLike: () => _toggleLike(_selectedBusiness!['name'] as String),
                onWriteReview: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _ReviewWriteScreen(
                      businessName: _selectedBusiness!['name'] as String,
                    ),
                  ),
                ),
                onRegister: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                onCommunity: () => showCommunityWriteSheet(context),
              ),
            ),

          // ── 하단 드래그 시트 (가게 선택 시 숨김) ──────────
          if (_selectedBusiness == null)
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.35,
              minChildSize: 0.12,
              maxChildSize: 0.75,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 16,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // GestureDetector를 통해 헤더 영역 드래그 시 시트 조절 가능하게 수정
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: (details) {
                          final delta = details.primaryDelta ?? 0;
                          final screenH = MediaQuery.of(context).size.height;
                          final newExtent =
                              (_sheetController.size - (delta / screenH)).clamp(
                                0.12,
                                0.75,
                              );
                          _sheetController.jumpTo(newExtent);
                        },
                        child: Column(
                          children: [
                            // 핸들
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E0E0),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // 헤더 행 (개수 + 등록 + 정렬)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                              child: Row(
                                children: [
                                  _SortChip(
                                    label: '거리순',
                                    selected: _sortMode == 0,
                                    onTap: () => setState(() => _sortMode = 0),
                                  ),
                                  const SizedBox(width: 8),
                                  _SortChip(
                                    label: '인기순',
                                    selected: _sortMode == 1,
                                    onTap: () => setState(() => _sortMode = 1),
                                  ),
                                  const SizedBox(width: 8),
                                  _SortChip(
                                    label: '평점순',
                                    selected: _sortMode == 2,
                                    onTap: () => setState(() => _sortMode = 2),
                                  ),
                                  const SizedBox(width: 8),
                                  _HeartChip(
                                    selected: _showOnlyLiked,
                                    onTap: () => setState(
                                      () => _showOnlyLiked = !_showOnlyLiked,
                                    ),
                                  ),
                                  const Spacer(),
                                  // 드롭다운
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _selectedType,
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.black,
                                      ),
                                      onChanged: (v) =>
                                          setState(() => _selectedType = v!),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 0,
                                          child: Text('전체'),
                                        ),
                                        DropdownMenuItem(
                                          value: 1,
                                          child: Text('세탁소'),
                                        ),
                                        DropdownMenuItem(
                                          value: 2,
                                          child: Text('수선집'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      // 업체 리스트
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: sorted.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 32,
                            color: Color(0xFFEEEEEE),
                          ),
                          itemBuilder: (context, i) => _BusinessCard(
                            business: sorted[i],
                            onLike: () =>
                                _toggleLike(sorted[i]['name'] as String),
                            onTap: () =>
                                setState(() => _selectedBusiness = sorted[i]),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ─── 정렬 칩 ──────────────────────────────────────────────────
class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF8FEAFD).withValues(alpha: 0.5)
              : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? const Color(0xFF8FEAFD) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? const Color(0xFF1A39FF) : const Color(0xFF9E9E9E),
          ),
        ),
      ),
    );
  }
}

class _HeartChip extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const _HeartChip({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.red.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? Colors.red : const Color(0xFFE0E0E0),
          ),
        ),
        child: Icon(
          Icons.favorite,
          size: 16,
          color: selected ? Colors.red : const Color(0xFFE0E0E0),
        ),
      ),
    );
  }
}

// ─── 업체 카드 ────────────────────────────────────────────────
class _BusinessCard extends StatelessWidget {
  final Map<String, dynamic> business;
  final VoidCallback onLike;
  final VoidCallback onTap;
  const _BusinessCard({
    required this.business,
    required this.onLike,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rating = business['rating'] as double;
    final likes = business['likes'] as int;
    final isVerified = business['isVerified'] ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 또는 아이콘
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 72,
                height: 72,
                color: const Color(0xFF1A39FF),
                child: const Center(
                  child: Icon(Icons.cloud, color: Colors.white, size: 36),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        business['name'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1B20),
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFF8BC34A),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    business['hours'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 14,
                        color: Colors.red.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$likes',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Color(0xFFFFC107),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$rating',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF757575),
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

// ─── 내 위치 파란 원 마커 ──────────────────────────────────────
class _MyLocationDot extends StatelessWidget {
  const _MyLocationDot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4).withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFF4285F4),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessMarkerIcon extends StatelessWidget {
  final bool isLaundry;
  final bool isVerified;
  const _BusinessMarkerIcon({
    required this.isLaundry,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.local_laundry_service,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        if (isVerified)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFF8BC34A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 12),
            ),
          ),
      ],
    );
  }
}

class _FloatingMapButton extends StatelessWidget {
  final IconData icon;
  const _FloatingMapButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.black54, size: 22),
    );
  }
}

// ─── 가게 선택 시 하단 컴팩트 카드 (Figma 화면3) ─────────────────
class _BusinessCompactCard extends StatelessWidget {
  final Map<String, dynamic> business;
  final VoidCallback onClose;
  final VoidCallback onLike;
  final VoidCallback onWriteReview;
  final VoidCallback onRegister;
  final VoidCallback onCommunity;

  const _BusinessCompactCard({
    required this.business,
    required this.onClose,
    required this.onLike,
    required this.onWriteReview,
    required this.onRegister,
    required this.onCommunity,
  });

  @override
  Widget build(BuildContext context) {
    final name = business['name'] as String;
    final type = business['type'] as String;
    final rating = business['rating'] as double;
    final reviews = business['reviews'] as int;
    final likes = business['likes'] as int;
    final isLiked = business['isLiked'] as bool;
    final isOpen = business['isOpen'] as bool;
    final hours = business['hours'] as String;
    final distance = business['distance'] as String;
    final address = business['address'] as String;

    return GestureDetector(
      onTap: onWriteReview,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 가게 이름 + 버튼 ──
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D1B20),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Color(0xFF43A047),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onLike,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : const Color(0xFFBDBDBD),
                      size: 22,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.close,
                      size: 22,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // ── 타입 · 리뷰 · 평점 · 좋아요 ──
            Row(
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                const _Dot(),
                Text(
                  '리뷰 $reviews',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 12, color: Color(0xFFFFB300)),
                Text(
                  ' $rating',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1B20),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.favorite, size: 12, color: Colors.red),
                Text(
                  ' $likes',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // ── 영업 · 시간 ──
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isOpen
                        ? const Color(0xFF43A047)
                        : const Color(0xFFEF5350),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOpen ? '영업중' : '영업종료',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOpen
                        ? const Color(0xFF43A047)
                        : const Color(0xFFEF5350),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const _Dot(),
                Text(
                  '$hours 영업',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // ── 거리 · 주소 ──
            Row(
              children: [
                Text(
                  distance,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                const _Dot(),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ── 이미지 + 액션 버튼 ──
            Row(
              children: [
                // 이미지 박스 1 (파란 배경)
                Container(
                  width: 80,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A39FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_laundry_service,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 이미지 박스 2 (회색)
                Container(
                  width: 80,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Color(0xFF9E9E9E),
                      size: 28,
                    ),
                  ),
                ),
                const Spacer(),
                // 액션 버튼들
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: onRegister,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8FEAFD),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 13, color: Color(0xFF1D1B20)),
                            SizedBox(width: 3),
                            Text(
                              '업체 등록',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D1B20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onCommunity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8FEAFD),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.share,
                              size: 13,
                              color: Color(0xFF1D1B20),
                            ),
                            SizedBox(width: 3),
                            Text(
                              '커뮤니티 공유',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D1B20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 6),
    width: 3,
    height: 3,
    decoration: const BoxDecoration(
      color: Color(0xFFD0D0D0),
      shape: BoxShape.circle,
    ),
  );
}

// ─── 리뷰 작성 화면 (Figma 리뷰 화면) ────────────────────────────
class _ReviewWriteScreen extends StatefulWidget {
  final String businessName;
  const _ReviewWriteScreen({required this.businessName});

  @override
  State<_ReviewWriteScreen> createState() => _ReviewWriteScreenState();
}

class _ReviewWriteScreenState extends State<_ReviewWriteScreen> {
  int _rating = 0;
  final _textCtrl = TextEditingController();
  final List<String> _photos = [];

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('별점을 선택해 주세요')));
      return;
    }
    if (_textCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('리뷰 내용을 입력해 주세요')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('리뷰가 등록되었습니다!'),
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
          '리뷰',
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
            // ── 카드 1: 가게 이름 ──
            _ReviewCard(
              child: Text(
                widget.businessName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1B20),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── 카드 2: 평점 ──
            _ReviewCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '평점',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(
                      5,
                      (i) => GestureDetector(
                        onTap: () => setState(() => _rating = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            i < _rating ? Icons.star : Icons.star_border,
                            size: 40,
                            color: const Color(0xFFFFB300),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 카드 3: 사진/영상 추가 ──
            _ReviewCard(
              child: Column(
                children: [
                  const Text(
                    '사진/영상을 추가해 주세요',
                    style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF616161),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_photos.length}/10',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 카드 4: 텍스트 입력 ──
            _ReviewCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('✏️ ', style: TextStyle(fontSize: 14)),
                      Text(
                        '경험을 공유해 주세요!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1B20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _textCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText:
                          '${widget.businessName}에서의 경험은 어땠나요?\n욕설, 비방, 명예훼손성 표현은 누군가에게 상처가 될 수 있습니다.',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFBDBDBD),
                        height: 1.5,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '등록하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Widget child;
  const _ReviewCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
