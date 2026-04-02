import 'package:flutter/material.dart';

const _kWriteCategories = ['세탁팁', '수선', '제품추천', '의류상태'];

/// 스캔 화면 등 외부에서도 게시글 작성 바텀시트를 열 수 있도록 공개 함수 제공
void showCommunityWriteSheet(BuildContext context) {
  final messenger = ScaffoldMessenger.of(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CommunityWriteSheet(messenger: messenger),
  );
}

class _CommunityWriteSheet extends StatefulWidget {
  final ScaffoldMessengerState messenger;
  final void Function(String title, String content, String category)? onPosted;
  const _CommunityWriteSheet({required this.messenger, this.onPosted});

  @override
  State<_CommunityWriteSheet> createState() => _CommunityWriteSheetState();
}

class _CommunityWriteSheetState extends State<_CommunityWriteSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _selectedCategory = _kWriteCategories.first;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('게시글 작성',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1B20))),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _kWriteCategories.map((cat) {
                  final sel = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF1A39FF)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(cat,
                          style: TextStyle(
                              fontSize: 13,
                              color: sel ? Colors.white : Colors.grey[600])),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: '제목을 입력하세요',
                hintStyle: const TextStyle(color: Color(0xFFB0BEC5)),
                filled: true,
                fillColor: const Color(0xFFF8FAFF),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '내용을 입력하세요',
                hintStyle: const TextStyle(color: Color(0xFFB0BEC5)),
                filled: true,
                fillColor: const Color(0xFFF8FAFF),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_titleCtrl.text.trim().isEmpty) return;
                  final title = _titleCtrl.text.trim();
                  final content = _contentCtrl.text.trim();
                  final category = _selectedCategory;
                  Navigator.pop(context);
                  widget.onPosted?.call(title, content, category);
                  widget.messenger.showSnackBar(
                    SnackBar(
                      content: const Text('게시글이 등록되었습니다!'),
                      backgroundColor: const Color(0xFF1A39FF),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A39FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('등록하기',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['전체', '세탁팁', '수선', '제품추천', '의류상태'];
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _sortMode = 0; // 0=추천순, 1=인기순, 2=최신순

  final List<Map<String, dynamic>> _posts = [
    {
      'user': '세탁왕김씨',
      'avatar': '🧺',
      'time': '5분 전',
      'category': '세탁팁',
      'title': '청바지 색 빠짐 방지하는 비법 공유해요!',
      'content': '청바지 처음 세탁할 때 소금물에 30분 담가두면 색이 훨씬 덜 빠져요.',
      'likes': 128,
      'comments': 23,
      'hasImage': true,
      'isLiked': false,
    },
    {
      'user': '옷수선마스터',
      'avatar': '✂️',
      'time': '1시간 전',
      'category': '수선',
      'title': '강남 00수선집 강추해요',
      'content': '지퍼 교체부터 기장 수선까지 정말 깔끔하게 해주시고 가격도 합리적이에요.',
      'likes': 56,
      'comments': 12,
      'hasImage': false,
      'isLiked': true,
    },
    {
      'user': '깔끔생활',
      'avatar': '🫧',
      'time': '3시간 전',
      'category': '제품추천',
      'title': '울 전용 세제 써봤는데 대박이에요',
      'content': '이번에 새로 나온 울 전용 세제 써봤는데 부드럽고 냄새도 없어요.',
      'likes': 89,
      'comments': 31,
      'hasImage': true,
      'isLiked': false,
    },
    {
      'user': '패션피플',
      'avatar': '👗',
      'time': '5시간 전',
      'category': '세탁팁',
      'title': '실크 세탁, 이렇게 하니까 망하지 않았어요',
      'content': '실크는 미지근한 물에 중성세제, 손으로 살살 세탁했더니 결이 살아있어요.',
      'likes': 204,
      'comments': 45,
      'hasImage': false,
      'isLiked': false,
    },
    {
      'user': '옷장관리자',
      'avatar': '👔',
      'time': '어제',
      'category': '의류상태',
      'title': '울 스웨터 상태 공유 (D등급)',
      'content': '필링이 너무 심해서 공유해요. 세탁 전후 비교해볼게요!',
      'likes': 34,
      'comments': 8,
      'hasImage': true,
      'isLiked': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openWriteSheet() {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommunityWriteSheet(
        messenger: messenger,
        onPosted: (title, content, category) {
          if (!mounted) return;
          setState(() {
            _posts.insert(0, {
              'user': '닉네임1',
              'avatar': '🙋',
              'time': '방금 전',
              'category': category,
              'title': title,
              'content': content,
              'likes': 0,
              'comments': 0,
              'hasImage': false,
              'isLiked': false,
            });
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('커뮤니티',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1B20))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1D1B20)),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off : Icons.search,
              color: const Color(0xFF1A39FF),
            ),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) _searchCtrl.clear();
            }),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_showSearch ? 100 : 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _showSearch
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextField(
                          controller: _searchCtrl,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: '제목, 내용 검색...',
                            hintStyle: const TextStyle(
                                color: Color(0xFFB0BEC5), fontSize: 14),
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xFF90A4AE), size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close,
                                        size: 18, color: Color(0xFF90A4AE)),
                                    onPressed: () => _searchCtrl.clear(),
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFFF8FAFF),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              TabBar(
                controller: _tabController,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
                labelColor: const Color(0xFF1A39FF),
                unselectedLabelColor: const Color(0xFF90A4AE),
                indicatorColor: const Color(0xFF1A39FF),
                indicatorWeight: 2.5,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          // 탭 + 검색어 동시 필터
          var filtered = tab == '전체'
              ? List<Map<String, dynamic>>.from(_posts)
              : _posts.where((p) => p['category'] == tab).toList();
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            filtered = filtered
                .where((p) =>
                    (p['title'] as String).toLowerCase().contains(q) ||
                    (p['content'] as String).toLowerCase().contains(q))
                .toList();
          }
          // 정렬 적용
          final sorted = List<Map<String, dynamic>>.from(filtered);
          if (_sortMode == 1) {
            sorted.sort((a, b) => (b['likes'] as int).compareTo(a['likes'] as int));
          } else if (_sortMode == 2) {
            // 최신순은 기본 순서 유지
          } else {
            // 추천순: likes + comments 합산
            sorted.sort((a, b) =>
                ((b['likes'] as int) + (b['comments'] as int))
                    .compareTo((a['likes'] as int) + (a['comments'] as int)));
          }

          if (sorted.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off, size: 48, color: Color(0xFFCFD8DC)),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isNotEmpty
                        ? '"$_searchQuery" 검색 결과가 없어요'
                        : '아직 게시글이 없어요',
                    style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // 인기글 상위 2개 (likes 기준)
          final topPosts = List<Map<String, dynamic>>.from(filtered)
            ..sort((a, b) => (b['likes'] as int).compareTo(a['likes'] as int));
          final hotPosts = topPosts.take(2).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
            children: [
              // ── 정렬 칩 ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    _SortChip(label: '추천순', active: _sortMode == 0,
                        onTap: () => setState(() => _sortMode = 0)),
                    const SizedBox(width: 8),
                    _SortChip(label: '인기순', active: _sortMode == 1,
                        onTap: () => setState(() => _sortMode = 1)),
                    const SizedBox(width: 8),
                    _SortChip(label: '최신순', active: _sortMode == 2,
                        onTap: () => setState(() => _sortMode = 2)),
                  ],
                ),
              ),

              // ── 실시간 인기글 ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: const [
                    Icon(Icons.local_fire_department, size: 16, color: Color(0xFF1A39FF)),
                    SizedBox(width: 4),
                    Text('실시간 인기글',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold,
                            color: Color(0xFF1A39FF))),
                  ],
                ),
              ),
              ...hotPosts.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F8FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE3EAFF)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events_outlined,
                              size: 16, color: Color(0xFF1A39FF)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(p['title'] as String,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500,
                                    color: Color(0xFF1D1B20)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(Icons.favorite, size: 12,
                                  color: Color(0xFFFF6161)),
                              const SizedBox(width: 3),
                              Text('${p['likes']}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF9E9E9E))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Divider(height: 1, color: Color(0xFFEEEEEE)),
              ),

              // ── 전체 게시글 ───────────────────────────────
              ...sorted.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: _PostCard(post: p),
                  )),
            ],
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openWriteSheet,
        backgroundColor: const Color(0xFF8FEAFD),
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        icon: const Icon(Icons.edit),
        label: const Text('글쓰기',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late bool _isLiked;
  late int _likes;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post['isLiked'] as bool;
    _likes = widget.post['likes'] as int;
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case '세탁팁': return const Color(0xFF1A39FF);
      case '수선': return const Color(0xFFE91E63);
      case '제품추천': return const Color(0xFF43A047);
      case '의류상태': return const Color(0xFFFB8C00);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.post['category'] as String;
    final catColor = _categoryColor(cat);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _PostDetailScreen(
            post: widget.post,
            isLiked: _isLiked,
            likes: _likes,
            onLikeChanged: (liked, count) => setState(() {
              _isLiked = liked;
              _likes = count;
            }),
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                            color: Color(0xFFE8F4FD), shape: BoxShape.circle),
                        child: Center(
                          child: Text(widget.post['avatar'],
                              style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.post['user'],
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF37474F))),
                          Text(widget.post['time'],
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFFB0BEC5))),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(cat,
                            style: TextStyle(
                                fontSize: 11, color: catColor, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(widget.post['title'],
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1B20))),
                  const SizedBox(height: 6),
                  Text(widget.post['content'],
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF78909C), height: 1.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (widget.post['hasImage'] as bool)
              Container(
                height: 150,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.image_outlined, size: 38, color: Color(0xFFB0BEC5)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      _isLiked = !_isLiked;
                      _likes += _isLiked ? 1 : -1;
                    }),
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(_isLiked),
                            size: 19,
                            color: _isLiked ? Colors.red : const Color(0xFFB0BEC5),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('$_likes',
                            style: TextStyle(
                                fontSize: 13,
                                color: _isLiked ? Colors.red : const Color(0xFF90A4AE),
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 17, color: Color(0xFFB0BEC5)),
                      const SizedBox(width: 4),
                      Text('${widget.post['comments']}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF90A4AE))),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${widget.post['title']}" 링크가 복사되었습니다'),
                          backgroundColor: const Color(0xFF1A39FF),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Icon(Icons.share_outlined, size: 18, color: Color(0xFFB0BEC5)),
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

// ─── 정렬 칩 ─────────────────────────────────────────────────
class _SortChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SortChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF8FEAFD) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF8FEAFD) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: const Color(0xFF494545))),
      ),
    );
  }
}

// ─── 게시글 상세 화면 ─────────────────────────────────────────
class _PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool isLiked;
  final int likes;
  final void Function(bool, int) onLikeChanged;

  const _PostDetailScreen({
    required this.post,
    required this.isLiked,
    required this.likes,
    required this.onLikeChanged,
  });

  @override
  State<_PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<_PostDetailScreen> {
  late bool _isLiked;
  late int _likes;
  final _commentCtrl = TextEditingController();
  final List<Map<String, dynamic>> _comments = [
    {'user': '세탁마니아', 'avatar': '🧼', 'text': '정말 도움이 됐어요!', 'time': '1분 전'},
    {'user': '옷관리왕', 'avatar': '👕', 'text': '저도 이 방법 써봤는데 효과 있어요', 'time': '5분 전'},
  ];

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likes = widget.likes;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case '세탁팁': return const Color(0xFF1A39FF);
      case '수선': return const Color(0xFFE91E63);
      case '제품추천': return const Color(0xFF43A047);
      case '의류상태': return const Color(0xFFFB8C00);
      default: return Colors.grey;
    }
  }

  void _submitComment() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.insert(0, {
        'user': '나',
        'avatar': '🙋',
        'text': text,
        'time': '방금 전',
      });
    });
    _commentCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.post['category'] as String;
    final catColor = _categoryColor(cat);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1D1B20),
        centerTitle: true,
        title: Text(cat,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: catColor)),
        actions: [
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${widget.post['title']}" 링크가 복사되었습니다'),
                  backgroundColor: const Color(0xFF1A39FF),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.share_outlined, size: 20, color: Color(0xFF9E9E9E)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 작성자 정보
                  Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: const BoxDecoration(
                            color: Color(0xFFE8F4FD), shape: BoxShape.circle),
                        child: Center(
                          child: Text(widget.post['avatar'],
                              style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.post['user'],
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF37474F))),
                          Text(widget.post['time'],
                              style: const TextStyle(fontSize: 12, color: Color(0xFFB0BEC5))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 제목
                  Text(widget.post['title'],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D1B20))),
                  const SizedBox(height: 12),
                  // 본문
                  Text(widget.post['content'],
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF546E7A), height: 1.7)),
                  // 이미지
                  if (widget.post['hasImage'] as bool) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity, height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FD),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(Icons.image_outlined, size: 48, color: Color(0xFFB0BEC5)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // 좋아요 / 댓글 수
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isLiked = !_isLiked;
                            _likes += _isLiked ? 1 : -1;
                          });
                          widget.onLikeChanged(_isLiked, _likes);
                        },
                        child: Row(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                _isLiked ? Icons.favorite : Icons.favorite_border,
                                key: ValueKey(_isLiked),
                                size: 20,
                                color: _isLiked ? Colors.red : const Color(0xFFB0BEC5),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('$_likes',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: _isLiked ? Colors.red : const Color(0xFF90A4AE))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFFB0BEC5)),
                      const SizedBox(width: 4),
                      Text('${_comments.length}',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF90A4AE))),
                    ],
                  ),
                  const Divider(height: 32, color: Color(0xFFEEEEEE)),
                  // 댓글 목록
                  Text('댓글 ${_comments.length}개',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1D1B20))),
                  const SizedBox(height: 12),
                  ..._comments.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34, height: 34,
                          decoration: const BoxDecoration(
                              color: Color(0xFFE8F4FD), shape: BoxShape.circle),
                          child: Center(
                              child: Text(c['avatar'], style: const TextStyle(fontSize: 16))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(c['user'],
                                      style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.bold,
                                          color: Color(0xFF37474F))),
                                  const SizedBox(width: 6),
                                  Text(c['time'],
                                      style: const TextStyle(
                                          fontSize: 11, color: Color(0xFFB0BEC5))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(c['text'],
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF546E7A), height: 1.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          // 댓글 입력창
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: InputDecoration(
                      hintText: '댓글을 입력하세요',
                      hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFF),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submitComment,
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(
                        color: Color(0xFF1A39FF), shape: BoxShape.circle),
                    child: const Icon(Icons.send, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
