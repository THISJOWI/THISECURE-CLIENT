import 'dart:async';
import 'package:flutter/material.dart';

class SearchDebounce {
  Timer? _timer;
  final Duration duration;

  SearchDebounce({this.duration = const Duration(milliseconds: 300)});

  void debounce(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
