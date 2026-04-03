import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart';

class CommunityService {
  static Future<List<Map<String, dynamic>>> fetchPosts() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/posts'),
      headers: _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractMessage(response.body, fallback: '게시글 목록을 불러오지 못했습니다.'),
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (body['data'] as List?) ?? const [];
    return items
        .map((item) => _mapPostList(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> fetchPopularPosts() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/posts/popular'),
      headers: _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractMessage(response.body, fallback: '인기글을 불러오지 못했습니다.'),
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (body['data'] as List?) ?? const [];
    return items
        .map((item) => _mapPostList(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  static Future<Map<String, dynamic>> fetchPostDetail(int postId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId'),
      headers: _headers(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractMessage(response.body, fallback: '게시글 상세를 불러오지 못했습니다.'),
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = Map<String, dynamic>.from((body['data'] as Map?) ?? {});
    return _mapPostDetail(data);
  }

  static Future<int> createPost({
    required String title,
    required String content,
    bool isPublic = true,
    int? analysisId,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'content': content,
      'public': isPublic,
    };
    if (analysisId != null) {
      payload['analysisId'] = analysisId;
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/posts'),
      headers: _headers(
        requireAuth: true,
        extra: {'Content-Type': 'application/json'},
      ),
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractMessage(response.body, fallback: '게시글 작성에 실패했습니다.'),
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['data'] as num?)?.toInt() ?? 0;
  }

  static Future<bool> toggleLike(int postId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId/like'),
      headers: _headers(requireAuth: true),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractMessage(response.body, fallback: '좋아요 처리에 실패했습니다.'),
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] == true;
  }

  static Future<void> addComment(int postId, String content) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/posts/$postId/comments'),
      headers: _headers(
        requireAuth: true,
        extra: {'Content-Type': 'application/json'},
      ),
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractMessage(response.body, fallback: '댓글 작성에 실패했습니다.'),
      );
    }
  }

  static Map<String, dynamic> _mapPostList(Map<String, dynamic> raw) {
    final title = raw['title']?.toString() ?? '';
    final content = raw['content']?.toString() ?? '';
    final analysisName = raw['analysisName']?.toString() ?? '';
    final imageUrl = _resolveImageUrl(raw['analysisImageUrl']);

    return {
      'id': raw['id'],
      'user': raw['authorNickname']?.toString() ?? '사용자',
      'avatar': '🙋',
      'time': _formatRelative(raw['createdAt']?.toString()),
      'createdAt': raw['createdAt']?.toString() ?? '',
      'category': _inferCategory(
        analysisName: analysisName,
        title: title,
        content: content,
      ),
      'title': title,
      'content': content,
      'likes': (raw['likeCount'] as num?)?.toInt() ?? 0,
      'comments': (raw['commentCount'] as num?)?.toInt() ?? 0,
      'hasImage': imageUrl.isNotEmpty,
      'imagePath': imageUrl,
      'imageUrl': imageUrl,
      'analysisName': analysisName,
      'authorProfileImage': _resolveImageUrl(raw['authorProfileImage']),
      'isLiked': raw['liked'] == true,
    };
  }

  static Map<String, dynamic> _mapPostDetail(Map<String, dynamic> raw) {
    final mapped = _mapPostList(raw);
    final comments = (raw['comments'] as List?) ?? const [];

    mapped['comments'] =
        (raw['commentCount'] as num?)?.toInt() ?? comments.length;
    mapped['commentsList'] = comments
        .map((item) => _mapComment(Map<String, dynamic>.from(item as Map)))
        .toList();
    return mapped;
  }

  static Map<String, dynamic> _mapComment(Map<String, dynamic> raw) {
    return {
      'id': raw['id'],
      'user': raw['authorNickname']?.toString() ?? '사용자',
      'avatar': '🙋',
      'text': raw['content']?.toString() ?? '',
      'time': _formatRelative(raw['createdAt']?.toString()),
      'createdAt': raw['createdAt']?.toString() ?? '',
      'authorProfileImage': _resolveImageUrl(raw['authorProfileImage']),
    };
  }

  static Map<String, String> _headers({
    bool requireAuth = false,
    Map<String, String>? extra,
  }) {
    if (requireAuth) {
      return AuthService.authorizedHeaders(extra: extra);
    }

    final token = AuthService.accessToken;
    if (token == null || token.isEmpty) {
      return {...?extra};
    }

    return {'Authorization': 'Bearer $token', ...?extra};
  }

  static String _resolveImageUrl(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '';

    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) return raw;

    if (raw.startsWith('/')) {
      return '${ApiConfig.baseUrl}$raw';
    }
    if (!raw.contains('/')) {
      return '${ApiConfig.baseUrl}/images/$raw';
    }
    return '${ApiConfig.baseUrl}/$raw';
  }

  static String _inferCategory({
    required String analysisName,
    required String title,
    required String content,
  }) {
    final source = '$analysisName $title $content'.toLowerCase();

    if (source.contains('수선') ||
        source.contains('기장') ||
        source.contains('지퍼')) {
      return '수선';
    }
    if (source.contains('세제') ||
        source.contains('추천') ||
        source.contains('제품') ||
        source.contains('섬유유연제')) {
      return '제품추천';
    }
    if (source.contains('등급') ||
        source.contains('오염') ||
        source.contains('얼룩') ||
        source.contains('손상') ||
        source.contains('보풀') ||
        source.contains('상태')) {
      return '의류상태';
    }
    return '세탁팁';
  }

  static String _formatRelative(String? iso) {
    if (iso == null || iso.isEmpty) return '방금 전';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return '방금 전';

    final diff = DateTime.now().difference(parsed.toLocal());
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';

    final local = parsed.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}.$month.$day';
  }

  static String _extractMessage(String body, {required String fallback}) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return decoded['message']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}
