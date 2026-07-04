import 'package:flutter/material.dart';

import 'window_size_service_stub.dart'
    if (dart.library.html) 'window_size_service_web.dart';

/// Servicio para guardar y restaurar el tamaño de la ventana.
///
/// En web intenta restaurar el tamaño al iniciar y guarda los cambios.
/// En otras plataformas no hace nada.
class WindowSizeService {
  static final WindowSizeService _instance = WindowSizeServiceImpl();
  static WindowSizeService get instance => _instance;

  factory WindowSizeService() => _instance;

  Future<void> initialize() async {}

  Future<void> saveSize(Size size) async {}

  Future<Size?> getLastSize() async => null;
}
