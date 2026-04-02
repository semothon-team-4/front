import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// 현재 위치를 가져옵니다. 권한 요청 포함.
  static Future<Position?> getCurrentPosition(BuildContext context) async {
    // 위치 서비스 활성화 여부 확인
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        _showDialog(context, '위치 서비스 꺼짐', '기기의 위치 서비스를 켜주세요.');
      }
      return null;
    }

    // 권한 확인
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        _showDialog(
          context,
          '위치 권한 필요',
          '설정에서 위치 권한을 허용해주세요.',
          showSettings: true,
        );
      }
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// 두 좌표 사이의 거리(m)를 계산합니다.
  static double distanceBetween(
    double startLat, double startLng,
    double endLat, double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// 거리를 사람이 읽기 좋은 형태로 변환합니다.
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  static void _showDialog(
    BuildContext context,
    String title,
    String message, {
    bool showSettings = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          if (showSettings)
            TextButton(
              onPressed: () {
                Geolocator.openAppSettings();
                Navigator.pop(context);
              },
              child: const Text('설정 열기',
                  style: TextStyle(color: Color(0xFF1565C0))),
            ),
        ],
      ),
    );
  }
}
