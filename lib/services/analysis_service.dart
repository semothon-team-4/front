import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart';

class AnalysisService {
  static Future<Map<String, dynamic>> requestAnalysis({
    required File image,
    required String name,
    required String category,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/analyses?name=${Uri.encodeQueryComponent(name)}&category=${Uri.encodeQueryComponent(category)}',
    );
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(AuthService.authorizedHeaders())
      ..files.add(await http.MultipartFile.fromPath('image', image.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('의류 분석 요청에 실패했습니다.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return _mapAnalysisDetail(
      Map<String, dynamic>.from((body['data'] as Map?) ?? {}),
    );
  }

  static Future<Map<String, dynamic>> fetchMyCloset() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/analyses"),
      headers: AuthService.authorizedHeaders(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("옷장 목록을 불러오지 못했습니다.");
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = Map<String, dynamic>.from((body["data"] as Map?) ?? {});
    final rawItems = (data["items"] as List?) ?? const [];

    final items = rawItems.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      final rawGrade = map["grade"]?.toString().trim();
      final grade = (rawGrade == null || rawGrade.isEmpty)
          ? null
          : rawGrade.toUpperCase();
      return {
        "id": map["id"],
        "name": map["name"] ?? "",
        "category": map["category"] ?? "기타",
        "grade": grade,
        "imageUrl": _resolveImageUrl(map["imageUrl"]),
        "careLabels": (map["careLabels"] as List? ?? const []).map((e) {
          final label = Map<String, dynamic>.from(e as Map);
          label["imageUrl"] = _resolveImageUrl(label["imageUrl"]);
          return label;
        }).toList(),
        "createdAt": map["createdAt"] ?? "",
      };
    }).toList();

    final rawCounts = Map<String, dynamic>.from(
      (data["gradeCounts"] as Map?) ?? {},
    );
    final gradeCounts = <String, int>{"A": 0, "B": 0, "C": 0, "D": 0};
    for (final key in gradeCounts.keys) {
      gradeCounts[key] = (rawCounts[key] as num?)?.toInt() ?? 0;
    }

    final totalCount = (data["totalCount"] as num?)?.toInt() ?? items.length;

    final rawTagCount =
        (rawCounts["TAG"] as num?)?.toInt() ??
        (rawCounts["tag"] as num?)?.toInt();
    final gradeSum =
        (gradeCounts["A"] ?? 0) +
        (gradeCounts["B"] ?? 0) +
        (gradeCounts["C"] ?? 0) +
        (gradeCounts["D"] ?? 0);
    final tagCount =
        rawTagCount ?? (totalCount - gradeSum).clamp(0, totalCount);

    return {
      "items": items,
      "gradeCounts": gradeCounts,
      "totalCount": totalCount,
      "tagCount": tagCount,
    };
  }

  static Future<List<Map<String, dynamic>>> fetchMyAnalyses() async {
    final closet = await fetchMyCloset();
    final items = (closet["items"] as List?) ?? const [];
    return items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  static Future<Map<String, dynamic>> fetchAnalysisDetail(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/analyses/$id'),
      headers: AuthService.authorizedHeaders(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('분석 상세를 불러오지 못했습니다.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return _mapAnalysisDetail(
      Map<String, dynamic>.from((body['data'] as Map?) ?? {}),
    );
  }

  static Future<void> deleteAnalysis(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/analyses/$id'),
      headers: AuthService.authorizedHeaders(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('의류 삭제에 실패했습니다.');
    }
  }

  static Map<String, dynamic> _mapAnalysisDetail(Map<String, dynamic> raw) {
    final condition = Map<String, dynamic>.from(
      (raw['condition'] as Map?) ?? {},
    );
    final stainLevel = (condition['stainLevel'] as num?)?.toInt() ?? 0;
    final damageLevel = (condition['damageLevel'] as num?)?.toInt() ?? 0;
    final grade = (condition['grade'] as String?)?.toUpperCase();

    return {
      'id': raw['id'],
      'name': raw['name'] ?? '스캔한 의류',
      'category': raw['category'] ?? '기타',
      'grade': grade,
      'desc': condition['recommendation'] ?? '분석 결과를 확인해 주세요.',
      'recommendation': condition['recommendation'] ?? '분석 결과를 확인해 주세요.',
      'imageUrl': _resolveImageUrl(raw['imageUrl']),
      'createdAt': raw['createdAt'] ?? '',
      'stainLevel': stainLevel,
      'damageLevel': damageLevel,
      'lastCare': _formatRelative(raw['createdAt']?.toString()),
      'careLabels': ((raw['careLabel'] as Map?)?['labels'] as List? ?? const [])
          .map((e) {
            final label = Map<String, dynamic>.from(e as Map);
            label['imageUrl'] = _resolveImageUrl(label['imageUrl']);
            return label;
          })
          .toList(),
    };
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

  static String _formatRelative(String? iso) {
    if (iso == null || iso.isEmpty) return '방금 전';
    final date = DateTime.tryParse(iso);
    if (date == null) return '방금 전';
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}
