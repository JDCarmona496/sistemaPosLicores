// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'window_size_service.dart';

class WindowSizeServiceImpl implements WindowSizeService {
  static const _widthKey = 'window_width';
  static const _heightKey = 'window_height';
  Timer? _debounce;

  @override
  Future<void> initialize() async {
    final lastSize = await getLastSize();
    if (lastSize != null) {
      try {
        html.window.resizeTo(
          lastSize.width.toInt(),
          lastSize.height.toInt(),
        );
      } catch (_) {
        // Ignorar si el navegador no permite redimensionar.
      }
    }

    html.window.onResize.listen((_) => _onResize());
  }

  void _onResize() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final width = html.window.innerWidth;
      final height = html.window.innerHeight;
      if (width != null && height != null) {
        await saveSize(Size(width.toDouble(), height.toDouble()));
      }
    });
  }

  @override
  Future<void> saveSize(Size size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_widthKey, size.width);
    await prefs.setDouble(_heightKey, size.height);
  }

  @override
  Future<Size?> getLastSize() async {
    final prefs = await SharedPreferences.getInstance();
    final width = prefs.getDouble(_widthKey);
    final height = prefs.getDouble(_heightKey);
    if (width == null || height == null) return null;

    const minWidth = 800.0;
    const minHeight = 600.0;
    return Size(
      math.max(width, minWidth),
      math.max(height, minHeight),
    );
  }
}
