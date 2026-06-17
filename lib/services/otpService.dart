import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Service for generating TOTP codes (Time-based One-Time Password)
/// Implementation according to RFC 6238 (TOTP) and RFC 4226 (HOTP)
class OtpService {
  /// Generates a TOTP code based on the provided secret
  /// 
  /// [secret] - Secret key in Base32
  /// [digits] - Number of code digits (default 6)
  /// [period] - Validity period in seconds (default 30)
  /// [algorithm] - Hash algorithm (SHA1, SHA256, SHA512)
  /// [timestamp] - Optional timestamp to generate code at specific moment
  String generateTotp({
    required String secret,
    int digits = 6,
    int period = 30,
    String algorithm = 'SHA1',
    DateTime? timestamp,
  }) {
    final time = timestamp ?? DateTime.now();
    final counter = time.millisecondsSinceEpoch ~/ 1000 ~/ period;
    
    return _generateHotp(
      secret: secret,
      counter: counter,
      digits: digits,
      algorithm: algorithm,
    );
  }

  /// Generates an HOTP code (HMAC-based One-Time Password)
  String _generateHotp({
    required String secret,
    required int counter,
    int digits = 6,
    String algorithm = 'SHA1',
  }) {
    // Decode Base32 secret
    final key = _base32Decode(secret);
    
    // Convert counter to bytes (8 bytes, big-endian)
    final counterBytes = _intToBytes(counter);
    
    // Calculate HMAC
    final hmacResult = _calculateHmac(key, counterBytes, algorithm);
    
    // Dynamic truncation
    final offset = hmacResult[hmacResult.length - 1] & 0x0f;
    final binary = ((hmacResult[offset] & 0x7f) << 24) |
        ((hmacResult[offset + 1] & 0xff) << 16) |
        ((hmacResult[offset + 2] & 0xff) << 8) |
        (hmacResult[offset + 3] & 0xff);
    
    // Generate code with specified number of digits
    final otp = binary % _pow10(digits);
    
    return otp.toString().padLeft(digits, '0');
  }

  /// Calculates the remaining time before the code expires
  int getRemainingSeconds({int period = 30}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return period - (now % period);
  }

  /// Calculates the progress of the current period (0.0 to 1.0)
  double getProgress({int period = 30}) {
    final remaining = getRemainingSeconds(period: period);
    return remaining / period;
  }

  /// Decodes a Base32 string to bytes
  Uint8List _base32Decode(String input) {
    const base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    
    // Clean input (uppercase, remove spaces and hyphens)
    final cleaned = input.toUpperCase().replaceAll(RegExp(r'[\s=-]'), '');
    
    if (cleaned.isEmpty) {
      throw const FormatException('Empty Base32 string');
    }
    
    // Validate characters
    for (final char in cleaned.split('')) {
      if (!base32Chars.contains(char)) {
        throw FormatException('Invalid Base32 character: $char');
      }
    }
    
    final bits = StringBuffer();
    for (final char in cleaned.split('')) {
      final value = base32Chars.indexOf(char);
      bits.write(value.toRadixString(2).padLeft(5, '0'));
    }
    
    final bitString = bits.toString();
    final bytes = <int>[];
    
    for (var i = 0; i + 8 <= bitString.length; i += 8) {
      bytes.add(int.parse(bitString.substring(i, i + 8), radix: 2));
    }
    
    return Uint8List.fromList(bytes);
  }

  /// Converts an integer to bytes (8 bytes, big-endian)
  Uint8List _intToBytes(int value) {
    final bytes = Uint8List(8);
    for (var i = 7; i >= 0; i--) {
      bytes[i] = value & 0xff;
      value >>= 8;
    }
    return bytes;
  }

  /// Calculates HMAC using the specified algorithm
  List<int> _calculateHmac(Uint8List key, Uint8List data, String algorithm) {
    Hmac hmac;
    
    switch (algorithm.toUpperCase()) {
      case 'SHA256':
        hmac = Hmac(sha256, key);
        break;
      case 'SHA512':
        hmac = Hmac(sha512, key);
        break;
      case 'SHA1':
      default:
        hmac = Hmac(sha1, key);
        break;
    }
    
    return hmac.convert(data).bytes;
  }

  /// Calculates 10^n
  int _pow10(int n) {
    var result = 1;
    for (var i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }

  /// Generates a cryptographically secure random secret in Base32
  String generateSecret({int length = 32}) {
    const base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = Random.secure();
    final buffer = StringBuffer();
    
    for (var i = 0; i < length; i++) {
      buffer.write(base32Chars[random.nextInt(32)]);
    }
    
    return buffer.toString();
  }

  /// Validates if a Base32 secret is valid
  bool isValidSecret(String secret) {
    const base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final cleaned = secret.toUpperCase().replaceAll(RegExp(r'[\s=-]'), '');
    
    if (cleaned.isEmpty) return false;
    
    for (final char in cleaned.split('')) {
      if (!base32Chars.contains(char)) {
        return false;
      }
    }
    
    return true;
  }

  /// Formats the OTP code for display (e.g.: "123 456")
  String formatCode(String code) {
    if (code.length <= 3) return code;
    
    final mid = code.length ~/ 2;
    return '${code.substring(0, mid)} ${code.substring(mid)}';
  }
}
