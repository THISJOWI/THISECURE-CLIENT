import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:thisjowi/i18n/translations.dart';

class NoteContentUtils {
  NoteContentUtils._();

  static String preview(String content) {
    if (content.isEmpty) return 'No Content'.i18n;
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        final doc = Document.fromJson(decoded);
        return doc.toPlainText().replaceAll('\n', ' ').trim();
      }
      return content.replaceAll('\n', ' ').trim();
    } catch (_) {
      return content.replaceAll('\n', ' ').trim();
    }
  }
}
