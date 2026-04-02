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

  static Future<List<Map<String, dynamic>>> fetchMyAnalyses() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/analyses'),
      headers: AuthService.authorizedHeaders(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('옷장 목록을 불러오지 못했습니다.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] as List?) ?? const [];

    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return {
        'id': map['id'],
        'name': map['name'] ?? '',
        'category': map['category'] ?? '기타',
        'imageUrl': map['imageUrl'] ?? '',
        'createdAt': map['createdAt'] ?? '',
      };
    }).toList();
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
    final grade = (condition['grade'] as String?)?.toUpperCase() ?? 'B';

    return {
      'id': raw['id'],
      'name': raw['name'] ?? '스캔한 의류',
      'category': raw['category'] ?? '기타',
      'grade': grade,
      'desc': condition['recommendation'] ?? '분석 결과를 확인해 주세요.',
      'recommendation': condition['recommendation'] ?? '분석 결과를 확인해 주세요.',
      'imageUrl': raw['imageUrl'] ?? '',
      'createdAt': raw['createdAt'] ?? '',
      'stainLevel': stainLevel,
      'damageLevel': damageLevel,
      'lastCare': _formatRelative(raw['createdAt']?.toString()),
      'careLabels': ((raw['careLabel'] as Map?)?['labels'] as List? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    };
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
