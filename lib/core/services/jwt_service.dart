import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class JwtService {
  static const String _secretKey = 'pathfit-student-verification-2024';
  static const Duration _tokenExpiry = Duration(hours: 24);

  // Generate JWT token for email verification
  static String generateEmailVerificationToken(String email, String studentId) {
    final now = DateTime.now();
    final expiry = now.add(_tokenExpiry);
    
    final payload = {
      'email': email,
      'studentId': studentId,
      'type': 'email_verification',
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': expiry.millisecondsSinceEpoch ~/ 1000,
    };

    final header = jsonEncode({'alg': 'HS256', 'typ': 'JWT'});
    final payloadJson = jsonEncode(payload);
    
    final encodedHeader = base64Url.encode(utf8.encode(header));
    final encodedPayload = base64Url.encode(utf8.encode(payloadJson));
    
    final signature = _generateSignature(encodedHeader, encodedPayload);
    
    return '$encodedHeader.$encodedPayload.$signature';
  }

  // Verify JWT token
  static Map<String, dynamic>? verifyEmailToken(String token) {
    try {
      if (JwtDecoder.isExpired(token)) {
        return null;
      }

      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final expectedSignature = _generateSignature(parts[0], parts[1]);
      if (expectedSignature != parts[2]) {
        return null;
      }

      final payload = jsonDecode(utf8.decode(base64Url.decode(parts[1])));
      if (payload['type'] != 'email_verification') {
        return null;
      }

      return payload;
    } catch (e) {
      return null;
    }
  }

  // Generate signature for token validation
  static String _generateSignature(String header, String payload) {
    final key = utf8.encode(_secretKey);
    final message = utf8.encode('$header.$payload');
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(message);
    return base64Url.encode(digest.bytes);
  }

  // Extract email from token
  static String? getEmailFromToken(String token) {
    final payload = verifyEmailToken(token);
    return payload?['email']?.toString();
  }

  // Extract student ID from token
  static String? getStudentIdFromToken(String token) {
    final payload = verifyEmailToken(token);
    return payload?['studentId']?.toString();
  }
}