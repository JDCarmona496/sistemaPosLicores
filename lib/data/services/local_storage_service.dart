import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia local híbrida: escribe simultáneamente en SharedPreferences y
/// en un archivo JSON en el directorio de documentos de la app.
///
/// Context7 (shared_preferences docs) indica que SharedPreferences no garantiza
/// escrituras inmediatas a disco y no debe usarse para datos críticos. Por eso
/// este servicio siempre deja una copia en archivo y, al leer, prefiere
/// SharedPreferences pero cae al archivo si el primero está vacío.
///
/// Esto resuelve problemas de SharedPreferences en Windows/desktop donde a
/// veces no se escribe correctamente o se pierde al cerrar la app.
class LocalStorageService {
  final String key;

  LocalStorageService(this.key);

  Future<String?> read() async {
    // Primero intentar SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(key);
      if (value != null && value.isNotEmpty) {
        debugPrint('[LocalStorageService:$key] Leído de SharedPreferences');
        return value;
      }
    } catch (e, stack) {
      debugPrint('[LocalStorageService:$key] Error leyendo SharedPreferences: $e');
      debugPrint(stack.toString());
    }

    // Fallback a archivo
    try {
      final file = await _file;
      if (await file.exists()) {
        final value = await file.readAsString();
        if (value.isNotEmpty) {
          debugPrint('[LocalStorageService:$key] Leído de archivo');
          return value;
        }
      }
    } catch (e, stack) {
      debugPrint('[LocalStorageService:$key] Error leyendo archivo: $e');
      debugPrint(stack.toString());
    }

    return null;
  }

  Future<bool> write(String value) async {
    var success = false;

    // Intentar SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final ok = await prefs.setString(key, value);
      final saved = prefs.getString(key);
      if (ok && saved == value) {
        debugPrint('[LocalStorageService:$key] Guardado en SharedPreferences');
        success = true;
      }
    } catch (e, stack) {
      debugPrint('[LocalStorageService:$key] Error guardando SharedPreferences: $e');
      debugPrint(stack.toString());
    }

    // También guardar en archivo como respaldo
    try {
      final file = await _file;
      await file.writeAsString(value, flush: true);
      final saved = await file.readAsString();
      if (saved == value) {
        debugPrint('[LocalStorageService:$key] Guardado en archivo');
        success = true;
      }
    } catch (e, stack) {
      debugPrint('[LocalStorageService:$key] Error guardando archivo: $e');
      debugPrint(stack.toString());
    }

    return success;
  }

  Future<bool> delete() async {
    var success = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      success = await prefs.remove(key);
    } catch (e) {
      debugPrint('[LocalStorageService:$key] Error eliminando SharedPreferences: $e');
    }
    try {
      final file = await _file;
      if (await file.exists()) {
        await file.delete();
        success = true;
      }
    } catch (e) {
      debugPrint('[LocalStorageService:$key] Error eliminando archivo: $e');
    }
    return success;
  }

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/applicoresestacion');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return File('${appDir.path}/$key.json');
  }
}
