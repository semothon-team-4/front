import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  static final _picker = ImagePicker();

  /// 카메라 또는 갤러리에서 이미지를 선택합니다.
  static Future<File?> pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// 이미지를 앱 로컬 저장소에 저장하고 경로를 반환합니다.
  static Future<String?> saveImageLocally(File imageFile, String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final savedPath = '${appDir.path}/$fileName';
      await imageFile.copy(savedPath);
      return savedPath;
    } catch (e) {
      return null;
    }
  }

  /// Uint8List를 파일로 저장합니다 (결과 이미지 캡처용).
  static Future<String?> saveBytesLocally(Uint8List bytes, String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final savedPath = '${appDir.path}/$fileName';
      await File(savedPath).writeAsBytes(bytes);
      return savedPath;
    } catch (e) {
      return null;
    }
  }

  /// 저장 성공 스낵바를 표시합니다.
  static void showSaveSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// 소스 선택 바텀시트를 표시하고 이미지를 반환합니다.
  static Future<File?> showPickerSheet(BuildContext context) async {
    File? result;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF1565C0)),
                ),
                title: const Text('카메라로 촬영',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () async {
                  Navigator.pop(context);
                  result = await pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: Color(0xFF43A047)),
                ),
                title: const Text('갤러리에서 선택',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () async {
                  Navigator.pop(context);
                  result = await pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    return result;
  }
}
