import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart';

class ShopService {
  static Future<List<Map<String, dynamic>>> fetchNearbyShops({
    required double lat,
    required double lng,
    int radius = 1000,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/shops?lat=$lat&lng=$lng&radius=$radius',
    );
    final response = await http.get(
      uri,
      headers: AuthService.authorizedHeaders(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('주변 매장 목록을 불러오지 못했습니다.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] as List?) ?? const [];

    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return {
        'id': map['id'],
        'placeId': map['placeId'],
        'name': map['name'] ?? '',
        'address': map['address'] ?? '',
        'lat': (map['lat'] as num?)?.toDouble() ?? lat,
        'lng': (map['lng'] as num?)?.toDouble() ?? lng,
      };
    }).toList();
  }

  static Future<Map<String, dynamic>> registerShop({
    required String name,
    required String address,
    required double lat,
    required double lng,
    String? placeId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/shops'),
      headers: AuthService.authorizedHeaders(
        extra: {'Content-Type': 'application/json'},
      ),
      body: jsonEncode({
        'placeId': placeId ?? '',
        'name': name,
        'address': address,
        'lat': lat,
        'lng': lng,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('매장 등록에 실패했습니다.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from((body['data'] as Map?) ?? {});
  }
}
