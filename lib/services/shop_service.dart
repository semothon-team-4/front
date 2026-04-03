import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart';

class ShopService {
  static Future<List<Map<String, dynamic>>> fetchNearbyShops({
    required double lat,
    required double lng,
    int radius = 1000,
  }) async {
    final latDelta = radius / 111000;
    final lngDelta = radius / (111000 * cos(lat * pi / 180)).abs();
    final swLat = lat - latDelta;
    final swLng = lng - lngDelta;
    final neLat = lat + latDelta;
    final neLng = lng + lngDelta;

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/shops/map'
      '?swLat=$swLat&swLng=$swLng&neLat=$neLat&neLng=$neLng&lat=$lat&lng=$lng',
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
        ...map,
        'id': (map['id'] as num?)?.toInt() ?? map['id'],
        'placeId': map['placeId'],
        'name': map['name'] ?? '',
        'address': map['address'] ?? '',
        'imageUrl': map['imageUrl'] ?? map['imagePath'] ?? '',
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

  static Future<Map<String, dynamic>> fetchShopDetail(int shopId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/shops/$shopId'),
      headers: AuthService.authorizedHeaders(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractMessage(response.body, '업체 상세를 불러오지 못했습니다.'));
    }

    return _decodeMapData(response.body);
  }

  static Future<List<Map<String, dynamic>>> fetchShopPrices(int shopId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/shops/$shopId/prices'),
      headers: AuthService.authorizedHeaders(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractMessage(response.body, '가격 정보를 불러오지 못했습니다.'));
    }

    return _decodeListData(response.body);
  }

  static Future<List<Map<String, dynamic>>> fetchShopReviews(int shopId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/shops/$shopId/reviews'),
      headers: AuthService.authorizedHeaders(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractMessage(response.body, '리뷰를 불러오지 못했습니다.'));
    }

    return _decodeListData(response.body);
  }

  static Future<Map<String, dynamic>> uploadReceipt({
    required int shopId,
    required File image,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('${ApiConfig.baseUrl}/receipts?shopId=$shopId'),
          )
          ..headers.addAll(AuthService.authorizedHeaders())
          ..files.add(await http.MultipartFile.fromPath('image', image.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractMessage(response.body, '영수증 업로드에 실패했습니다.'));
    }

    return _decodeMapData(response.body);
  }

  static Future<Map<String, dynamic>> writeReview({
    required int shopId,
    int? receiptId,
    required int rating,
    required String content,
    List<File> images = const [],
  }) async {
    final query = <String, String>{
      "rating": rating.toString(),
      "content": content,
      if (receiptId != null) "receiptId": receiptId.toString(),
    };
    final uri = Uri.parse(
      "${ApiConfig.baseUrl}/shops/$shopId/reviews",
    ).replace(queryParameters: query);

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(AuthService.authorizedHeaders());

    for (final image in images) {
      request.files.add(
        await http.MultipartFile.fromPath('images', image.path),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractMessage(response.body, '리뷰 등록에 실패했습니다.'));
    }

    return _decodeMapData(response.body);
  }

  static Map<String, dynamic> _decodeMapData(String body) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    return Map<String, dynamic>.from((decoded['data'] as Map?) ?? {});
  }

  static List<Map<String, dynamic>> _decodeListData(String body) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final data = (decoded['data'] as List?) ?? const [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static String _extractMessage(String body, String fallback) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return decoded['message']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}
