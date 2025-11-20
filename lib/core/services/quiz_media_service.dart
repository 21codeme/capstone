import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class QuizMediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImageBytes({
    required Uint8List bytes,
    required String folderId,
    String? contentType,
    String? fileName,
  }) async {
    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final name = fileName != null && fileName.isNotEmpty ? fileName : 'img_$ts.jpg';
      final ref = _storage.ref().child('quizzes/$folderId/$name');
      final metadata = SettableMetadata(contentType: contentType ?? 'image/jpeg');
      final task = await ref.putData(bytes, metadata);
      return await task.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadXFile({
    required XFile file,
    required String folderId,
    String? contentType,
    String? fileName,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      return await uploadImageBytes(
        bytes: bytes,
        folderId: folderId,
        contentType: contentType ?? _guessContentType(file.path),
        fileName: fileName,
      );
    } catch (_) {
      return null;
    }
  }

  String _guessContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}