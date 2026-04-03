import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

class AiScanService {
  static const String baseUrl = String.fromEnvironment(
    'AI_API_BASE_URL',
    defaultValue: 'https://incondite-lorena-nonerosive.ngrok-free.dev',
  );

  static Future<Map<String, dynamic>> requestCareLabelScan({
    required File image,
  }) async {
    final decoded = await _postMultipart(
      path: '/predict/care-label',
      image: image,
    );
    return {
      'id': 'care_${DateTime.now().millisecondsSinceEpoch}',
      'careLabels': _normalizeCareLabels(decoded),
      'raw': decoded,
    };
  }

  static Future<Map<String, dynamic>> requestClothGradeScan({
    required File image,
  }) async {
    final decoded = await _postMultipart(
      path: '/predict/cloth-grade',
      image: image,
    );

    return {
      'id': 'cloth_${DateTime.now().millisecondsSinceEpoch}',
      'name': _asString(decoded['clothing'], fallback: '스캔한 의류'),
      'category': _inferCategory(decoded['clothing']),
      'grade': _asString(decoded['grade']).toUpperCase(),
      'imagePath': image.path,
      'stainLevel': _asInt(decoded['stain']),
      'damageLevel': _asInt(decoded['damage']),
      'recommendation': _buildRecommendation(decoded),
      'guideTitle': _buildGuideTitle(decoded),
      'guideTip': _asString(
        decoded['storage_tip'],
        fallback: '통풍이 잘 되는 곳에 보관해 주세요.',
      ),
      'lastCare': '방금 전',
      'photoQuality': _asString(decoded['photo_quality']),
      'photoWarn': _asNullableString(decoded['photo_warn']),
      'fabric': _asNullableString(decoded['fabric']),
      'isVintage': decoded['is_vintage'] == true,
      'vintageReason': _asNullableString(decoded['vintage_reason']),
      'needWash': decoded['need_wash'] == true,
      'needRepair': decoded['need_repair'] == true,
      'action': _asNullableString(decoded['action']),
      'reason': _asNullableString(decoded['reason']),
      'totalScore': _asNum(decoded['total_score']),
      'raw': decoded,
    };
  }

  static Future<Map<String, dynamic>> _postMultipart({
    required String path,
    required File image,
  }) async {
    final bytes = await image.readAsBytes();
    final fileName = _normalizedFileName(image.path);
    final contentType = _contentTypeForPath(image.path);

    final response = await _sendMultipart(
      path: path,
      file: http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: contentType,
      ),
    );
    var decoded = _decodeBody(response.body);

    if (response.statusCode >= 500 &&
        contentType.subtype != 'jpeg' &&
        contentType.subtype != 'jpg') {
      final fallbackResponse = await _sendMultipart(
        path: path,
        file: http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '${p.basenameWithoutExtension(fileName)}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      decoded = _decodeBody(fallbackResponse.body);
      if (fallbackResponse.statusCode >= 200 &&
          fallbackResponse.statusCode < 300) {
        return decoded;
      }
      _logFailedUpload(
        path: path,
        imagePath: image.path,
        fileName: '${p.basenameWithoutExtension(fileName)}.jpg',
        contentType: MediaType('image', 'jpeg'),
        body: fallbackResponse.body,
        statusCode: fallbackResponse.statusCode,
      );
      throw Exception(_extractMessage(decoded, fallbackResponse.statusCode));
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      _logFailedUpload(
        path: path,
        imagePath: image.path,
        fileName: fileName,
        contentType: contentType,
        body: response.body,
        statusCode: response.statusCode,
      );
      throw Exception(_extractMessage(decoded, response.statusCode));
    }

    return decoded;
  }

  static Future<http.Response> _sendMultipart({
    required String path,
    required http.MultipartFile file,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$path'),
    )
      ..headers['Accept'] = 'application/json'
      ..files.add(file);

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  static Map<String, dynamic> _decodeBody(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is List) return {'items': decoded};
      return {'value': decoded};
    } catch (_) {
      return {'rawBody': body};
    }
  }

  static String _extractMessage(Map<String, dynamic> body, int statusCode) {
    final detail = body['detail'];
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] != null) {
        return 'AI 분석 요청 실패 ($statusCode): ${first['msg']}';
      }
    }

    final message = body['message']?.toString().trim();
    if (message != null && message.isNotEmpty) {
      return 'AI 분석 요청 실패 ($statusCode): $message';
    }

    return 'AI 분석 요청 실패 ($statusCode)';
  }

  static void _logFailedUpload({
    required String path,
    required String imagePath,
    required String fileName,
    required MediaType contentType,
    required String body,
    required int statusCode,
  }) {
    final preview = body.length > 500 ? '${body.substring(0, 500)}...' : body;
    print(
      'AI upload failed: status=$statusCode path=$path imagePath=$imagePath '
      'fileName=$fileName contentType=$contentType body=$preview',
    );
  }

  static List<Map<String, dynamic>> _normalizeCareLabels(
    Map<String, dynamic> decoded,
  ) {
    final candidates = <dynamic>[
      decoded['data'],
      decoded['careLabels'],
      decoded['labels'],
      decoded['symbols'],
      decoded['results'],
      decoded['items'],
    ];

    for (final candidate in candidates) {
      if (candidate is List) {
        return candidate
            .map((item) {
              if (item is Map) {
                final map = Map<String, dynamic>.from(item);
                return {
                  'name': _asString(
                    map['name'] ?? map['label'] ?? map['symbol'],
                    fallback: '케어 정보',
                  ),
                  'icon': _asNullableString(map['icon'] ?? map['code']),
                  'desc': _asNullableString(
                    map['desc'] ?? map['description'] ?? map['meaning'],
                  ),
                };
              }
              return {
                'name': item.toString(),
                'icon': null,
                'desc': null,
              };
            })
            .toList();
      }
    }

    return const [];
  }

  static String _buildRecommendation(Map<String, dynamic> decoded) {
    final action = _asNullableString(decoded['action']);
    final reason = _asNullableString(decoded['reason']);
    final warn = _asNullableString(decoded['photo_warn']);

    return [
      if (action != null && action.isNotEmpty) action,
      if (reason != null && reason.isNotEmpty) reason,
      if (warn != null && warn.isNotEmpty) warn,
    ].join(' ').trim().isNotEmpty
        ? [
            if (action != null && action.isNotEmpty) action,
            if (reason != null && reason.isNotEmpty) reason,
            if (warn != null && warn.isNotEmpty) warn,
          ].join(' ')
        : '분석 결과를 확인해 주세요.';
  }

  static String _buildGuideTitle(Map<String, dynamic> decoded) {
    final reason = _asNullableString(decoded['reason']);
    if (reason != null && reason.isNotEmpty) return reason;

    final quality = _asString(decoded['photo_quality'], fallback: 'unknown');
    final warn = _asNullableString(decoded['photo_warn']);
    if (warn != null && warn.isNotEmpty) {
      return '사진 품질: $quality. $warn';
    }
    return '사진 품질은 $quality 수준으로 판정되었어요.';
  }

  static String _inferCategory(dynamic clothing) {
    final text = _asString(clothing).toLowerCase();
    if (text.contains('shirt') || text.contains('tee') || text.contains('top')) {
      return '상의';
    }
    if (text.contains('pants') || text.contains('jean') || text.contains('skirt')) {
      return '하의';
    }
    if (text.contains('coat') ||
        text.contains('jacket') ||
        text.contains('outer')) {
      return '아우터';
    }
    return '기타';
  }

  static String _normalizedFileName(String path) {
    final baseName = p.basename(path).trim();
    if (baseName.isEmpty) return 'upload.jpg';

    final extension = p.extension(baseName).toLowerCase();
    if (extension == '.jpg' ||
        extension == '.jpeg' ||
        extension == '.png' ||
        extension == '.webp') {
      return baseName;
    }
    return '${p.basenameWithoutExtension(baseName)}.jpg';
  }

  static MediaType _contentTypeForPath(String path) {
    switch (p.extension(path).toLowerCase()) {
      case '.png':
        return MediaType('image', 'png');
      case '.webp':
        return MediaType('image', 'webp');
      case '.jpg':
      case '.jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _asNullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value.clamp(0, 100);
    if (value is num) return value.round().clamp(0, 100);
    return 0;
  }

  static num? _asNum(dynamic value) {
    if (value is num) return value;
    return null;
  }
}
