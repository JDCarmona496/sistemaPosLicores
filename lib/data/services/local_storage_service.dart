import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia local híbrida: escribe simultáneamente en SharedPreferences y
/// en un archivo JSON en el directorio de soporte de la app.
///
/// Context7 (shared_preferences docs) indica que SharedPreferences no garantiza
/// escrituras inmediatas a disco y no debe usarse para datos críticos. Por eso
/// este servicio deja siempre una copia en archivo y, al leer, prefiere
/// SharedPreferences pero cae al archivo si el primero está vacío.
///
/// El directorio principal es [getApplicationSupportDirectory] porque es el
/// lugar correcto para configuración de la app y no depende de la carpeta
/// Documentos del usuario (que puede estar sincronizada con OneDrive o tener
/// permisos restrictivos). Se conserva la carpeta legada en Documentos como
/// fallback de migración.
class LocalStorageService {
  final String key;

  LocalStorageService(this.key);

  Future<String?> read() async {
    // 1) Intentar SharedPreferences primero (rápido).
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

    // 2) Fallback a archivo en el directorio de soporte de la app.
    try {
      final file = await _primaryFile;
      debugPrint('[LocalStorageService:$key] Buscando archivo en: ${file.path}');
      if (await file.exists()) {
        final value = await file.readAsString();
        if (value.isNotEmpty) {
          debugPrint('[LocalStorageService:$key] Leído de archivo primario');
          // Restaurar en SharedPreferences para futuras lecturas.
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(key, value);
          } catch (e) {
            debugPrint('[LocalStorageService:$key] No se pudo restaurar en SharedPreferences: $e');
          }
          return value;
        }
      }
    } catch (e, stack) {
      debugPrint('[LocalStorageService:$key] Error leyendo archivo primario: $e');
      debugPrint(stack.toString());
    }

    // 3) Fallback a archivo legado en Documentos (migración silenciosa).
    try {
      final file = await _legacyFile;
      if (file == null) {
        debugPrint('[LocalStorageService:$key] No se pudo obtener archivo legado');
      } else {
        debugPrint('[LocalStorageService:$key] Buscando archivo legado en: ${file.path}');
        if (await file.exists()) {
          final value = await file.readAsString();
          if (value.isNotEmpty) {
            debugPrint('[LocalStorageService:$key] Leído de archivo legado');
            // Migrar al nuevo almacenamiento en segundo plano.
            write(value).ignore();
            return value;
          }
        }
      }
    } catch (e, stack) {
      debugPrint('[LocalStorageService:$key] Error leyendo archivo legado: $e');
      debugPrint(stack.toString());
    }

    debugPrint('[LocalStorageService:$key] No se encontró valor guardado');
    return null;
  }

  Future<bool> write(String value) async {
    var success = false;

    // 1) SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final ok = await prefs.setString(key, value);
      final saved = prefs.getString(key);
      if (ok && saved == value) {
        debugPrint('[LocalStorageService:$key] Guardado en SharedPreferences');
        success = true;
      } else {
        debugPrint('[LocalStorageService:$key] SharedPreferences no verificó el guardado');
      }
    } catch (e, stack) {
      debugPrint('[LocalStorageService:$key] Error guardando SharedPreferences: $e');
      debugPrint(stack.toString());
    }

    // 2) Archivo primario en directorio de soporte
    try {
      final file = await _primaryFile;
      debugPrint('[LocalStorageService:$key] Escribiendo archivo en: ${file.path}');
      await file.writeAsString(value, flush: true);
      final saved = await file.readAsString();
      if (saved == value) {
        debugPrint('[LocalStorageService:$key] Guardado en archivo primario');
        success = true;
      } else {
        debugPrint('[LocalStorageService:$key] Archivo primario no verificó el guardado');
      }
    } catch (e, stack) {
      debugPrint('[LocalStorageService:$key] Error guardando archivo primario: $e');
      debugPrint(stack.toString());
    }

    // 3) Archivo legado en Documentos (redundancia adicional)
    try {
      final file = await _legacyFile;
      if (file != null) {
        await file.writeAsString(value, flush: true);
        debugPrint('[LocalStorageService:$key] Guardado en archivo legado');
      }
    } catch (e, stack) {
      debugPrint('[LocalStorageService:$key] Error guardando archivo legado: $e');
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
      final primary = await _primaryFile;
      if (await primary.exists()) {
        await primary.delete();
        success = true;
      }
    } catch (e) {
      debugPrint('[LocalStorageService:$key] Error eliminando archivo primario: $e');
    }
    try {
      final legacy = await _legacyFile;
      if (legacy != null && await legacy.exists()) {
        await legacy.delete();
        success = true;
      }
    } catch (e) {
      debugPrint('[LocalStorageService:$key] Error eliminando archivo legado: $e');
    }
    return success;
  }

  Future<File> get _primaryFile async {
    final dir = await getApplicationSupportDirectory();
    final appDir = Directory('${dir.path}/applicoresestacion');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return File('${appDir.path}/$key.json');
  }

  Future<File?> get _legacyFile async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final appDir = Directory('${dir.path}/applicoresestacion');
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      return File('${appDir.path}/$key.json');
    } catch (e) {
      debugPrint('[LocalStorageService:$key] No se pudo obtener archivo legado: $e');
      return null;
    }
  }
}

