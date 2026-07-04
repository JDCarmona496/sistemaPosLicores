import 'package:flutter/material.dart';

import 'window_size_service.dart';

class WindowSizeServiceImpl implements WindowSizeService {
  @override
  Future<void> initialize() async {
    // No-op en plataformas no-web.
  }

  @override
  Future<void> saveSize(Size size) async {
    // No-op en plataformas no-web.
  }

  @override
  Future<Size?> getLastSize() async => null;
}
