import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/services/token_manager.dart';

class UserAvatar extends StatefulWidget {
  final String? userId;
  final String? avatarUrl;
  final String initial;
  final double size;
  final double borderWidth;

  const UserAvatar({
    super.key,
    this.userId,
    this.avatarUrl,
    required this.initial,
    this.size = 48,
    this.borderWidth = 0,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  static final Map<String, Uint8List> _cache = {};
  static final Set<String> _notFound = {};

  Uint8List? _bytes;
  String? _activeUrl;

  String? _resolveUrl() {
    final url = widget.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url';
    }
    final id = widget.userId;
    if (id != null && id.isNotEmpty) {
      return '${ApiConfig.baseUrl}/v1/profiles/$id/avatar';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId || oldWidget.avatarUrl != widget.avatarUrl) {
      _load();
    }
  }

  void _load() {
    final url = _resolveUrl();
    _activeUrl = url;
    if (url == null) {
      setState(() => _bytes = null);
      return;
    }
    if (_notFound.contains(url)) {
      setState(() => _bytes = null);
      return;
    }
    final cached = _cache[url];
    if (cached != null) {
      setState(() => _bytes = cached);
      return;
    }
    setState(() => _bytes = null);
    _fetch(url);
  }

  Future<void> _fetch(String url) async {
    try {
      final token = await TokenManager().getToken();
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final res = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        _cache[url] = res.bodyBytes;
        if (kDebugMode) {
          debugPrint('🖼️ Avatar OK: $url (${res.bodyBytes.length}B)');
        }
        if (_activeUrl == url) {
          setState(() => _bytes = res.bodyBytes);
        }
      } else {
        if (res.statusCode == 404) {
          _notFound.add(url);
        }
        if (kDebugMode) {
          debugPrint('🖼️ Avatar fail: $url status=${res.statusCode}');
        }
      }
    } on TimeoutException {
      if (kDebugMode) debugPrint('🖼️ Avatar timeout: $url');
    } catch (e) {
      if (kDebugMode) debugPrint('🖼️ Avatar error: $url ($e)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _buildInitials(context);
    if (_bytes == null) return initials;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        border: widget.borderWidth > 0
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                width: widget.borderWidth,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.memory(
        _bytes!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => initials,
      ),
    );
  }

  Widget _buildInitials(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        border: widget.borderWidth > 0
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                width: widget.borderWidth,
              )
            : null,
      ),
      child: Text(
        widget.initial,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: widget.size * 0.4,
        ),
      ),
    );
  }
}
