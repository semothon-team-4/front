class ProfileActivityService {
  static final List<Map<String, dynamic>> _recentViewedPosts = [];
  static final List<Map<String, dynamic>> _myReviews = [];

  static void addRecentViewedPost(Map<String, dynamic> post) {
    final normalized = Map<String, dynamic>.from(post);
    final key = _postKey(normalized);
    _recentViewedPosts.removeWhere((item) => _postKey(item) == key);
    _recentViewedPosts.insert(0, normalized);
    if (_recentViewedPosts.length > 30) {
      _recentViewedPosts.removeRange(30, _recentViewedPosts.length);
    }
  }

  static List<Map<String, dynamic>> getRecentViewedPosts() {
    return _recentViewedPosts
        .map((post) => Map<String, dynamic>.from(post))
        .toList();
  }

  static void addMyReview(Map<String, dynamic> review) {
    _myReviews.insert(0, Map<String, dynamic>.from(review));
  }

  static List<Map<String, dynamic>> getMyReviews() {
    return _myReviews
        .map((review) => Map<String, dynamic>.from(review))
        .toList();
  }

  static String _postKey(Map<String, dynamic> post) {
    final id = post['id']?.toString() ?? '';
    final title = post['title']?.toString() ?? '';
    final user = post['user']?.toString() ?? '';
    return '$id|$title|$user';
  }
}
