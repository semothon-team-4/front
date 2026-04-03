import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../services/business_store_service.dart';
import '../services/image_service.dart';
import '../services/shop_service.dart';
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
  final _sheetCtrl = DraggableScrollableController();
  final _compactSheetCtrl = DraggableScrollableController();
  double _compactSheetExtent = 0.35;
  NaverMapController? _mapController;
  bool _isLoadingShops = true;
  double _currentCenterLat = _fixedLat;
  double _currentCenterLng = _fixedLng;
  int _shopRequestId = 0;
  bool _suppressNextCameraIdle = false;

  @override
  void initState() {
    super.initState();
    _compactSheetCtrl.addListener(() {
      if (mounted) setState(() => _compactSheetExtent = _compactSheetCtrl.size);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _sheetCtrl.dispose();
    _compactSheetCtrl.dispose();
    super.dispose();
  }

  // 경희대학교 국제캠퍼스 / 영통역 기준 고정 좌표
  static const _fixedLat = 37.2430;
  static const _fixedLng = 127.0760;

  List<Map<String, dynamic>> get _businesses =>
      BusinessStoreService.getBusinesses();

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

  Future<void> _onBusinessSelected(Map<String, dynamic> business) async {
    setState(() {
      _selectedBusiness = business;
      _compactSheetExtent = 0.35; // 상태 즉시 초기화
    });
    await _refreshMapMarkers();
    _suppressNextCameraIdle = true;

    // 지도 카메라 이동
    await _mapController?.updateCamera(
      NCameraUpdate.withParams(
        target: NLatLng(business['lat'] as double, business['lng'] as double),
        zoom: 16,
      ),
    );

    // 다음 프레임에서 시트 컨트롤러 위치 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_compactSheetCtrl.isAttached) {
        _compactSheetCtrl.jumpTo(0.35);
      }
    });
  }

  Future<void> _loadNearbyShops({
    required double lat,
    required double lng,
  }) async {
    final requestId = ++_shopRequestId;
    if (mounted) {
      setState(() {
        _isLoadingShops = true;
        _currentCenterLat = lat;
        _currentCenterLng = lng;
      });
    }

    try {
      final shops = await ShopService.fetchNearbyShops(lat: lat, lng: lng);

      if (requestId != _shopRequestId) return;

      final mapped = shops.map((shop) {
        final shopLat = (shop['lat'] as num?)?.toDouble() ?? lat;
        final shopLng = (shop['lng'] as num?)?.toDouble() ?? lng;
        final distanceM = _distanceBetweenMeters(
          lat,
          lng,
          shopLat,
          shopLng,
        ).round();

        return {
          ...shop,
          'id': (shop['id'] as num?)?.toInt() ?? shop['id'],
          'placeId': shop['placeId'] ?? '',
          'name': shop['name'] ?? '',
          'type': _inferType(
            (shop['category'] as String?) ?? (shop['name'] as String? ?? ''),
          ),
          'rating': (shop['rate'] as num?)?.toDouble() ?? 0.0,
          'reviews': (shop['reviewCount'] as num?)?.toInt() ?? 0,
          'likes': (shop['likeCount'] as num?)?.toInt() ?? 0,
          'isLiked': false,
          'isVerified': false,
          'distance': _formatDistance(distanceM),
          'distanceM': distanceM,
          'address': shop['address'] ?? '',
          'phone':
              (shop['phone'] as String?) ??
              (shop['telephone'] as String?) ??
              '',
          'website':
              (shop['website'] as String?) ??
              (shop['homepageUrl'] as String?) ??
              (shop['siteUrl'] as String?) ??
              '',
          'addressDetail':
              (shop['addressDetail'] as String?) ??
              (shop['detailAddress'] as String?) ??
              '',
          'imageUrl': shop['imageUrl'] ?? '',
          'tags': <String>[],
          'isOpen': (shop['isOpen'] as bool?) ?? true,
          'hours': _buildHoursText(shop),
          'lat': shopLat,
          'lng': shopLng,
          'imagePath': null,
        };
      }).toList();

      BusinessStoreService.syncBusinesses(mapped);
      await _refreshMapMarkers();

      if (!mounted || requestId != _shopRequestId) return;
      setState(() {
        if (_selectedBusiness != null) {
          final selectedName = _selectedBusiness!['name'];
          final selected = _businesses.where((b) => b['name'] == selectedName);
          _selectedBusiness = selected.isEmpty ? null : selected.first;
        }
      });
    } catch (e) {
      if (!mounted || requestId != _shopRequestId) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted && requestId == _shopRequestId) {
        setState(() => _isLoadingShops = false);
      }
    }
  }

  Future<void> _refreshMapMarkers() async {
    final controller = _mapController;
    if (controller == null || !mounted) return;

    await controller.clearOverlays(type: NOverlayType.marker);
    if (!mounted) return;

    final myLocIcon = await NOverlayImage.fromWidget(
      context: context,
      size: const Size(26, 26),
      widget: const _MyLocationDot(),
    );
    if (!mounted) return;

    await controller.addOverlay(
      NMarker(
        id: 'my_location',
        position: const NLatLng(_fixedLat, _fixedLng),
        icon: myLocIcon,
      ),
    );

    for (final business in _businesses) {
      if (!mounted) return;
      final isLaundry = business['type'] == '세탁소';
      final isVerified = business['isVerified'] ?? false;
      final isSelected =
          _selectedBusiness?['name'] != null &&
          _selectedBusiness!['name'] == business['name'];
      final icon = await NOverlayImage.fromWidget(
        context: context,
        size: Size(isSelected ? 58 : 46, isSelected ? 72 : 46),
        widget: _BusinessMarkerIcon(
          isLaundry: isLaundry,
          isVerified: isVerified,
          isSelected: isSelected,
        ),
      );
      if (!mounted) return;

      final marker = NMarker(
        id: business['name'] as String,
        position: NLatLng(
          (business['lat'] as num).toDouble(),
          (business['lng'] as num).toDouble(),
        ),
        icon: icon,
      );
      marker.setOnTapListener((_) => _onBusinessSelected(business));
      await controller.addOverlay(marker);
    }
  }

  Future<void> _handleCameraIdle() async {
    if (_suppressNextCameraIdle) {
      _suppressNextCameraIdle = false;
      return;
    }

    final controller = _mapController;
    if (controller == null) return;

    final position = await controller.getCameraPosition();
    final target = position.target;
    final movedDistance = _distanceBetweenMeters(
      _currentCenterLat,
      _currentCenterLng,
      target.latitude,
      target.longitude,
    );

    if (movedDistance < 30) return;

    await _loadNearbyShops(lat: target.latitude, lng: target.longitude);
  }

  String _inferType(String name) {
    if (name.contains('수선')) {
      return '수선집';
    }
    return '세탁소';
  }

  String _buildHoursText(Map<String, dynamic> shop) {
    final open = shop['openTime']?.toString() ?? '';
    final close = shop['closeTime']?.toString() ?? '';
    if (open.isNotEmpty && close.isNotEmpty) {
      return '$open - $close';
    }
    if (open.isNotEmpty) return open;
    if (close.isNotEmpty) return close;
    return '영업 정보 없음';
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

  double _degToRad(double degree) => degree * pi / 180.0;

  @override
  Widget build(BuildContext context) {
    final sorted = _filteredAndSorted;
    return Scaffold(
      body: Stack(
        children: [
          if (_isLoadingShops)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A39FF)),
            ),
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
              _mapController = controller;
              await controller.updateCamera(
                NCameraUpdate.withParams(
                  target: const NLatLng(_fixedLat, _fixedLng),
                  zoom: 15,
                ),
              );
              await _loadNearbyShops(lat: _fixedLat, lng: _fixedLng);
            },
            onCameraIdle: _handleCameraIdle,
          ),

          // ── 우측 플로팅 버튼 (내 위치) ──
          // 하단 시트의 상단을 따라 다님 (AnimatedBuilder로 성능 최적화)
          if (_selectedBusiness == null)
            AnimatedBuilder(
              animation: _sheetCtrl,
              builder: (context, _) {
                final extent = _sheetCtrl.isAttached ? _sheetCtrl.size : 0.35;
                final screenH = MediaQuery.of(context).size.height;
                final fabBottom = screenH * extent + 16;
                final searchBarBottom = 112.0;
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
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _selectedBusiness == null
                  ? 1.0
                  : (_compactSheetExtent > 0.8 ? 0.0 : 1.0),
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
                    const Icon(
                      Icons.search,
                      color: Color(0xFF1D1B20),
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          ),

          // ── 선택된 가게 스냅 시트 ────────────────────────
          if (_selectedBusiness != null)
            DraggableScrollableSheet(
              controller: _compactSheetCtrl,
              initialChildSize: 0.35,
              minChildSize: 0.12,
              maxChildSize: 1.0,
              snap: true,
              snapSizes: const [0.12, 0.35, 1.0],
              builder: (context, scrollCtrl) => _BusinessCompactCard(
                key: ValueKey(
                  _selectedBusiness!['id'] ?? _selectedBusiness!['name'],
                ),
                business: _selectedBusiness!,
                scrollCtrl: scrollCtrl,
                compactSheetCtrl: _compactSheetCtrl,
                currentExtent: _compactSheetExtent,
                onClose: () async {
                  setState(() => _selectedBusiness = null);
                  await _refreshMapMarkers();
                },
                onLike: () => _toggleLike(_selectedBusiness!['name'] as String),
                onWriteReview: () async {
                  final posted = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          _ReviewWriteScreen(business: _selectedBusiness!),
                    ),
                  );
                  if (posted == true && mounted && _selectedBusiness != null) {
                    setState(() {
                      _selectedBusiness = {
                        ..._selectedBusiness!,
                        'reviewRefreshKey':
                            DateTime.now().millisecondsSinceEpoch,
                      };
                    });
                    await _refreshMapMarkers();
                  }
                },
                onCommunity: () => showCommunityWriteSheet(context),
              ),
            ),

          // ── 하단 드래그 시트 (가게 선택 시 숨김) ──────────
          if (_selectedBusiness == null)
            DraggableScrollableSheet(
              controller: _sheetCtrl,
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
                              (_sheetCtrl.size - (delta / screenH)).clamp(
                                0.12,
                                0.75,
                              );
                          _sheetCtrl.jumpTo(newExtent);
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
                          separatorBuilder: (_, index) => const Divider(
                            height: 32,
                            color: Color(0xFFEEEEEE),
                          ),
                          itemBuilder: (context, i) => _BusinessCard(
                            business: sorted[i],
                            onLike: () =>
                                _toggleLike(sorted[i]['name'] as String),
                            onTap: () => _onBusinessSelected(sorted[i]),
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
              child: SizedBox(
                width: 72,
                height: 72,
                child: _BusinessThumbnail(
                  imageUrl: business['imageUrl'] as String?,
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

class _BusinessThumbnail extends StatelessWidget {
  final String? imageUrl;

  const _BusinessThumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty) {
      return _BusinessThumbnailFallback();
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const _BusinessThumbnailFallback(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Stack(
          fit: StackFit.expand,
          children: const [
            _BusinessThumbnailFallback(),
            Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BusinessThumbnailFallback extends StatelessWidget {
  const _BusinessThumbnailFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A39FF),
      child: const Center(
        child: Icon(Icons.cloud, color: Colors.white, size: 36),
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
  final bool isSelected;
  const _BusinessMarkerIcon({
    required this.isLaundry,
    required this.isVerified,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final markerColor = isSelected
        ? const Color(0xFF1A39FF)
        : const Color(0xFF00E5FF);

    return SizedBox(
      width: isSelected ? 58 : 46,
      height: isSelected ? 72 : 46,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (isSelected)
            Positioned(
              top: 50,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            width: isSelected ? 58 : 46,
            height: isSelected ? 58 : 46,
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: isSelected ? 3 : 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isSelected ? 0.28 : 0.2,
                  ),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                isLaundry ? Icons.local_laundry_service : Icons.content_cut,
                color: Colors.white,
                size: isSelected ? 28 : 24,
              ),
            ),
          ),
          if (isVerified)
            Positioned(
              right: isSelected ? 2 : 0,
              bottom: isSelected ? 16 : 0,
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
      ),
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

// ─── 가게 선택 시 하단 컴팩트 카드 (스냅 방식) ───────────────────
class _BusinessCompactCard extends StatefulWidget {
  final Map<String, dynamic> business;
  final ScrollController scrollCtrl;
  final DraggableScrollableController compactSheetCtrl;
  final double currentExtent;
  final VoidCallback onClose;
  final VoidCallback onLike;
  final VoidCallback onWriteReview;
  final VoidCallback onCommunity;

  const _BusinessCompactCard({
    super.key,
    required this.business,
    required this.scrollCtrl,
    required this.compactSheetCtrl,
    required this.currentExtent,
    required this.onClose,
    required this.onLike,
    required this.onWriteReview,
    required this.onCommunity,
  });

  @override
  State<_BusinessCompactCard> createState() => _BusinessCompactCardState();
}

class _BusinessCompactCardState extends State<_BusinessCompactCard> {
  int _selectedTab = 0;
  bool _isLoadingDetail = false;
  String? _detailError;
  Map<String, dynamic>? _shopDetail;
  List<Map<String, dynamic>> _shopPrices = const [];
  List<Map<String, dynamic>> _shopReviews = const [];
  int _detailRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadShopDetailData();
  }

  @override
  void didUpdateWidget(covariant _BusinessCompactCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.business['id'];
    final newId = widget.business['id'];
    final oldRefreshKey = oldWidget.business['reviewRefreshKey'];
    final newRefreshKey = widget.business['reviewRefreshKey'];
    if (oldId != newId || oldRefreshKey != newRefreshKey) {
      _loadShopDetailData();
    }
  }

  Future<void> _loadShopDetailData() async {
    final shopId = widget.business['id'];
    if (shopId is! int) return;
    final requestId = ++_detailRequestId;

    setState(() {
      _selectedTab = 0;
      _isLoadingDetail = true;
      _detailError = null;
      _shopDetail = null;
      _shopPrices = const [];
      _shopReviews = const [];
    });

    try {
      final results = await Future.wait([
        ShopService.fetchShopDetail(shopId),
        ShopService.fetchShopPrices(shopId),
        ShopService.fetchShopReviews(shopId),
      ]);

      if (!mounted || requestId != _detailRequestId) return;
      setState(() {
        _shopDetail = results[0] as Map<String, dynamic>;
        _shopPrices = List<Map<String, dynamic>>.from(results[1] as List);
        _shopReviews = List<Map<String, dynamic>>.from(results[2] as List);
      });
    } catch (e) {
      if (!mounted || requestId != _detailRequestId) return;
      setState(
        () => _detailError = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted && requestId == _detailRequestId) {
        setState(() => _isLoadingDetail = false);
      }
    }
  }

  List<Map<String, String>> _priceItems(String type) {
    if (type == '수선집') {
      return const [
        {'name': '기장 수선', 'price': '8,000원'},
        {'name': '지퍼 교체', 'price': '15,000원'},
        {'name': '단추 교체', 'price': '5,000원'},
      ];
    }

    return const [
      {'name': '셔츠 다림질', 'price': '3,000원'},
      {'name': '패딩 드라이 클리닝', 'price': '30,000원'},
      {'name': '신발 얼룩 제거', 'price': '40,000원'},
    ];
  }

  List<Map<String, String>> _resolvedPriceItems(Map<String, dynamic> business) {
    if (_shopPrices.isNotEmpty) {
      return _shopPrices
          .map(
            (item) => {
              'name': item['category']?.toString() ?? '가격 정보',
              'price': _formatPrice(item['price']),
            },
          )
          .toList();
    }

    final raw = business['priceItems'];
    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map(
            (item) => {
              'name': item['name']?.toString() ?? '',
              'price': item['price']?.toString() ?? '',
            },
          )
          .where(
            (item) => item['name']!.isNotEmpty || item['price']!.isNotEmpty,
          )
          .toList();
    }
    return _priceItems(business['type'] as String);
  }

  List<Map<String, String>> _reviewItems(String businessName) {
    return [
      {
        'user': '세탁왕',
        'badge': '영수증 인증 완료!',
        'text': '친절하고 깨끗하게 세탁해주세요',
        'imageUrl': '',
      },
      {
        'user': 'rlaalswn1234',
        'badge': '',
        'text': '사장님이 쾌끗하고 가격이 친절해요~',
        'imageUrl': '',
      },
    ];
  }

  List<Map<String, String>> _resolvedReviewItems(
    Map<String, dynamic> business,
    String businessName,
  ) {
    if (_shopReviews.isNotEmpty) {
      return _shopReviews
          .map(
            (item) => {
              'user': item['nickname']?.toString() ?? '사용자',
              'badge': (item['receiptId'] ?? item['verifiedReceipt']) != null
                  ? '영수증 인증 완료!'
                  : '',
              'text': item['content']?.toString() ?? '',
              'imageUrl': _firstImage(item),
              'rating': item['rating']?.toString() ?? '',
            },
          )
          .toList();
    }

    final raw = business['reviewItems'];
    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map(
            (item) => {
              'user': item['user']?.toString() ?? '사용자',
              'badge': item['badge']?.toString() ?? '',
              'text': item['text']?.toString() ?? '',
              'imageUrl': item['imageUrl']?.toString() ?? '',
            },
          )
          .toList();
    }
    return _reviewItems(businessName);
  }

  List<String> _resolvedPhotoUrls(
    Map<String, dynamic> business,
    String? imageUrl,
  ) {
    if (_shopReviews.isNotEmpty) {
      final reviewPhotos = _shopReviews
          .expand((item) => _imageList(item))
          .where((url) => url.isNotEmpty)
          .toList();
      if (reviewPhotos.isNotEmpty) return reviewPhotos;
    }

    final raw = business['photoUrls'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if ((imageUrl ?? '').isNotEmpty) {
      return [imageUrl!];
    }
    return const [];
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '';
    final number = price is num
        ? price.toInt()
        : int.tryParse(price.toString());
    if (number == null) return price.toString();
    final digits = number.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return '${buffer.toString()}원';
  }

  String _firstImage(Map<String, dynamic> item) {
    final images = _imageList(item);
    if (images.isNotEmpty) return images.first;
    return item['imageUrl']?.toString() ?? '';
  }

  List<String> _imageList(Map<String, dynamic> item) {
    final raw = item['images'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    final single = item['imageUrl']?.toString() ?? '';
    return single.isEmpty ? const [] : [single];
  }

  String _resolveText(List<dynamic> values, String fallback) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  double _resolvedRating(Map<String, dynamic> business) {
    if (_shopReviews.isNotEmpty) {
      final total = _shopReviews.fold<double>(
        0,
        (sum, item) => sum + ((item['rating'] as num?)?.toDouble() ?? 0),
      );
      return total / _shopReviews.length;
    }
    if ((_shopDetail?['rate'] as num?) != null) {
      return (_shopDetail!['rate'] as num).toDouble();
    }
    return (business['rating'] as double?) ?? 0;
  }

  int _resolvedReviewCount(Map<String, dynamic> business) {
    if (_shopReviews.isNotEmpty) return _shopReviews.length;
    if ((_shopDetail?['reviewCount'] as num?) != null) {
      return (_shopDetail!['reviewCount'] as num).toInt();
    }
    return (business['reviews'] as int?) ?? 0;
  }

  void _collapseSheet() {
    widget.compactSheetCtrl.animateTo(
      0.35,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Widget _buildTabButton(String label, int index) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? const Color(0xFF1D1B20) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected
                  ? const Color(0xFF1D1B20)
                  : const Color(0xFF6D6D6D),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGallery(List<String> photoUrls, String? imageUrl) {
    final primaryUrl = photoUrls.isNotEmpty ? photoUrls.first : imageUrl;
    final secondaryUrl = photoUrls.length > 1 ? photoUrls[1] : null;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 160,
              child: _BusinessThumbnail(imageUrl: primaryUrl),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 160,
              child: secondaryUrl != null
                  ? _BusinessThumbnail(imageUrl: secondaryUrl)
                  : Container(color: const Color(0xFFD9D9D9)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeTab({
    required String address,
    required String addressDetail,
    required String hours,
    required String phone,
    required String website,
  }) {
    final resolvedAddress = addressDetail.isNotEmpty
        ? '$address $addressDetail'
        : address;
    final resolvedPhone = phone.isNotEmpty ? phone : '031-205-8059';
    final resolvedWebsite = website.isNotEmpty
        ? website
        : 'https://www.cleantopia.com/kr/main.do';

    return Column(
      children: [
        const SizedBox(height: 18),
        _DetailLine(icon: Icons.location_on, text: resolvedAddress),
        const SizedBox(height: 26),
        _DetailLine(icon: Icons.access_time_filled, text: '$hours 영업'),
        const SizedBox(height: 26),
        _DetailLine(icon: Icons.call, text: resolvedPhone),
        const SizedBox(height: 26),
        _DetailLine(
          icon: Icons.link,
          text: resolvedWebsite,
          textColor: Color(0xFF5B7BFF),
        ),
      ],
    );
  }

  Widget _buildPriceTab(Map<String, dynamic> business) {
    final items = _resolvedPriceItems(business);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFD8F5FF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Best 3',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF335CFF),
                ),
              ),
              const SizedBox(height: 10),
              ...items.asMap().entries.map((entry) {
                final item = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: entry.key == items.length - 1
                            ? Colors.transparent
                            : const Color(0xFFAAC9D8),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['name']!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                      ),
                      Text(
                        item['price']!,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D1B20),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          '실제 영수증 / 최근순',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4C4C4C),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE4E4E4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  Icon(Icons.account_circle_outlined, size: 38),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '세탁왕',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '2026.03.31',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9A9A9A)),
                  ),
                ],
              ),
              SizedBox(height: 14),
              _ReceiptLine(name: '패딩 드라이 클리닝', price: '30,000원'),
              SizedBox(height: 6),
              _ReceiptLine(name: '운동화 세탁', price: '3,000원'),
              Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '합계',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '33,000원',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF335CFF),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '영수증 인증 완료',
                style: TextStyle(fontSize: 13, color: Color(0xFF7F7F7F)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewTab({
    required Map<String, dynamic> business,
    required double rating,
    required int reviews,
    required String businessName,
  }) {
    final items = _resolvedReviewItems(business, businessName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(
          '리뷰 $reviews',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        const Text(
          '• 최신순',
          style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D1B20),
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(
              5,
              (index) => Icon(
                index < rating.round() ? Icons.star : Icons.star_border_rounded,
                color: const Color(0xFFFFD233),
                size: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...items.map(
          (item) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 14),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE6E6E6)),
                bottom: BorderSide(color: Color(0xFFE6E6E6)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_circle_outlined, size: 34),
                    const SizedBox(width: 8),
                    Text(
                      item['user']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item['badge']!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9BEAFF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item['badge']!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2B7B92),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                if ((item['imageUrl'] ?? '').isNotEmpty ||
                    item['user'] == 'rlaalswn1234') ...[
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 112,
                          height: 112,
                          child: (item['imageUrl'] ?? '').isNotEmpty
                              ? _BusinessThumbnail(imageUrl: item['imageUrl'])
                              : Container(
                                  color: const Color(0xFFD9D9D9),
                                  child: const Icon(
                                    Icons.storefront,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  item['text']!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4F4F4F),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoTab(List<String> photoUrls, String? imageUrl) {
    final photos = photoUrls.isEmpty && (imageUrl ?? '').isNotEmpty
        ? [imageUrl!]
        : photoUrls;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
        children: photos.isEmpty
            ? [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ]
            : photos
                  .map(
                    (url) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _BusinessThumbnail(imageUrl: url),
                    ),
                  )
                  .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final business = widget.business;
    final name = _resolveText([_shopDetail?['name'], business['name']], '세탁소');
    final type = business['type'] as String? ?? '세탁소';
    final rating = _resolvedRating(business);
    final reviews = _resolvedReviewCount(business);
    final likes =
        (_shopDetail?['likeCount'] as num?)?.toInt() ??
        (business['likes'] as int? ?? 0);
    final isLiked = business['isLiked'] as bool? ?? false;
    final hours = _resolveText([
      (() {
        final open = _shopDetail?['openTime']?.toString() ?? '';
        final close = _shopDetail?['closeTime']?.toString() ?? '';
        if (open.isNotEmpty && close.isNotEmpty) return '$open - $close';
        return '';
      })(),
      business['hours'],
    ], '영업 정보 없음');
    final distance = business['distance'] as String? ?? '';
    final address = _resolveText([
      _shopDetail?['address'],
      business['address'],
    ], '주소 정보 없음');
    final addressDetail = _resolveText([
      _shopDetail?['addressDetail'],
      business['addressDetail'],
    ], '');
    final phone = _resolveText([
      _shopDetail?['phone'],
      business['phone'],
      _shopDetail?['telephone'],
    ], '');
    final website = _resolveText([
      _shopDetail?['website'],
      _shopDetail?['homepageUrl'],
      _shopDetail?['siteUrl'],
      business['website'],
    ], '');
    final imageUrl = _resolveText([
      _shopDetail?['imageUrl'],
      business['imageUrl'],
    ], '');
    final photoUrls = _resolvedPhotoUrls(business, imageUrl);
    final isCollapsed = widget.currentExtent < 0.2;
    final isExpanded = widget.currentExtent > 0.8;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
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
      child: Column(
        children: [
          if (!isExpanded)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (details) {
                final delta = details.primaryDelta ?? 0;
                final screenH = MediaQuery.of(context).size.height;
                final newExtent = (widget.currentExtent - (delta / screenH))
                    .clamp(0.12, 1.0);
                widget.compactSheetCtrl.jumpTo(newExtent);
              },
              onVerticalDragEnd: (details) {
                const snapSizes = [0.12, 0.35, 1.0];
                double closest = snapSizes.reduce(
                  (a, b) =>
                      (a - widget.currentExtent).abs() <
                          (b - widget.currentExtent).abs()
                      ? a
                      : b,
                );

                widget.compactSheetCtrl.animateTo(
                  closest,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

          Expanded(
            child: ListView(
              controller: widget.scrollCtrl,
              padding: EdgeInsets.fromLTRB(16, isExpanded ? 8 : 0, 16, 20),
              children: [
                if (isExpanded) ...[
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _collapseSheet,
                        child: const Icon(
                          Icons.arrow_back,
                          size: 28,
                          color: Color(0xFF1D1B20),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: widget.onLike,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFD4D4D4)),
                          ),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: const Color(0xFFFF7B8F),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFD4D4D4)),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 22,
                            color: Color(0xFF8F8F8F),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],

                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: isCollapsed ? 18 : 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1D1B20),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (!isExpanded)
                            const Icon(
                              Icons.check_circle,
                              size: 18,
                              color: Color(0xFF43A047),
                            ),
                        ],
                      ),
                    ),
                    if (!isCollapsed) ...[
                      GestureDetector(
                        onTap: widget.onLike,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked
                                ? Colors.red
                                : const Color(0xFFBDBDBD),
                            size: 24,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.close,
                            size: 24,
                            color: Color(0xFF9E9E9E),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      type,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                    const _Dot(),
                    Text(
                      '리뷰 $reviews',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, size: 14, color: Color(0xFFFFB300)),
                    Text(
                      ' ${rating.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.favorite, size: 14, color: Colors.red),
                    Text(
                      ' $likes',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                    if (isCollapsed) const Spacer(),
                    if (isCollapsed)
                      GestureDetector(
                        onTap: widget.onClose,
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                  ],
                ),

                if (!isCollapsed) ...[
                  const SizedBox(height: 12),
                  if (!isExpanded) ...[
                    Row(
                      children: [
                        Text(
                          distance,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D1B20),
                          ),
                        ),
                        const _Dot(),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7C7C7C),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: 122,
                              child: _BusinessThumbnail(imageUrl: imageUrl),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 122,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD9D9D9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _RoundActionButton(
                              label: '리뷰 쓰기',
                              icon: Icons.add,
                              onTap: widget.onWriteReview,
                            ),
                            const SizedBox(height: 10),
                            _RoundActionButton(
                              label: '커뮤니티 공유',
                              icon: Icons.share,
                              onTap: widget.onCommunity,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    _buildGallery(photoUrls, imageUrl),
                    const SizedBox(height: 18),
                    if (_isLoadingDetail)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          color: Color(0xFF8FEAFD),
                          backgroundColor: Color(0xFFEAFBFF),
                        ),
                      ),
                    if (_detailError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _detailError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFD14A4A),
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        _buildTabButton('홈', 0),
                        _buildTabButton('가격', 1),
                        _buildTabButton('리뷰', 2),
                        _buildTabButton('사진', 3),
                      ],
                    ),
                    const Divider(height: 1, color: Color(0xFFE1E1E1)),
                    if (_selectedTab == 0)
                      _buildHomeTab(
                        address: address,
                        addressDetail: addressDetail,
                        hours: hours,
                        phone: phone,
                        website: website,
                      ),
                    if (_selectedTab == 1) _buildPriceTab(business),
                    if (_selectedTab == 2)
                      _buildReviewTab(
                        business: business,
                        rating: rating,
                        reviews: reviews,
                        businessName: name,
                      ),
                    if (_selectedTab == 3) _buildPhotoTab(photoUrls, imageUrl),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _RoundActionButton(
                        label: '리뷰 쓰기',
                        icon: Icons.add,
                        onTap: widget.onWriteReview,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color textColor;

  const _DetailLine({
    required this.icon,
    required this.text,
    this.textColor = const Color(0xFF4F4F4F),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: const Color(0xFF5D5D5D)),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 15, height: 1.5, color: textColor),
          ),
        ),
      ],
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  final String name;
  final String price;

  const _ReceiptLine({required this.name, required this.price});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 15, color: Color(0xFF444444)),
          ),
        ),
        Text(
          price,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D1B20),
          ),
        ),
      ],
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _RoundActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF8FEAFD),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1D1B20)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1B20),
              ),
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
  final Map<String, dynamic> business;
  const _ReviewWriteScreen({required this.business});

  @override
  State<_ReviewWriteScreen> createState() => _ReviewWriteScreenState();
}

class _ReviewWriteScreenState extends State<_ReviewWriteScreen> {
  int _rating = 5;
  final _textCtrl = TextEditingController();
  File? _receiptImage;
  final List<File> _photos = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final shopId = widget.business['id'];
    if (shopId is! int) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('업체 정보를 찾지 못했습니다.')));
      return;
    }
    if (_receiptImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('영수증 이미지를 먼저 추가해 주세요')));
      return;
    }
    if (_textCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('리뷰 내용을 입력해 주세요')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final receipt = await ShopService.uploadReceipt(
        shopId: shopId,
        image: _receiptImage!,
      );
      final receiptId = (receipt['id'] as num?)?.toInt();
      if (receiptId == null) {
        throw Exception('영수증 업로드 응답이 올바르지 않습니다.');
      }

      await ShopService.writeReview(
        shopId: shopId,
        receiptId: receiptId,
        rating: _rating,
        content: _textCtrl.text.trim(),
        images: _photos,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('리뷰가 등록되었습니다!'),
          backgroundColor: const Color(0xFF1A39FF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickReceipt() async {
    final file = await ImageService.showPickerSheet(context);
    if (file == null || !mounted) return;
    setState(() => _receiptImage = file);
  }

  Future<void> _pickPhoto() async {
    final file = await ImageService.showPickerSheet(context);
    if (file == null || !mounted) return;
    setState(() => _photos.add(file));
  }

  @override
  Widget build(BuildContext context) {
    final businessName = (widget.business['name'] as String?) ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              businessName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D1B20),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: const [
                Text(
                  '영수증',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1B20),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.receipt_long_outlined, color: Color(0xFF666666)),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickReceipt,
              child: Container(
                width: 102,
                height: 102,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF8FEAFD),
                    style: BorderStyle.solid,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _receiptImage != null
                    ? Image.file(_receiptImage!, fit: BoxFit.cover)
                    : const Center(
                        child: Icon(
                          Icons.add_circle,
                          size: 38,
                          color: Colors.black,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: Color(0xFFE7E7E7)),
            const SizedBox(height: 18),
            Row(
              children: [
                const Text(
                  '평점',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1B20),
                  ),
                ),
                const Spacer(),
                ...List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Icon(
                      i < _rating ? Icons.star : Icons.star_border,
                      size: 24,
                      color: const Color(0xFFFFD233),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF8FEAFD), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFF808080),
                      ),
                      SizedBox(width: 4),
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
                  Text(
                    '$businessName에서의 경험은 어땠나요?\n욕설, 비방, 명예훼손성 표현은 누군가에게 상처가 될 수 있습니다.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _textCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: '후기를 입력해 주세요',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFBDBDBD),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFD1D1D1),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      '사진/영상 추가',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    if (_photos.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _photos
                            .map(
                              (file) => ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  file,
                                  width: 74,
                                  height: 74,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
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
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8FEAFD),
                foregroundColor: const Color(0xFF1D1B20),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Color(0xFF1D1B20),
                      ),
                    )
                  : const Text(
                      '완료!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
