import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia local híbrida.
///
/// En escritorio (Windows/Linux/macOS) la configuración se guarda en el
/// directorio donde está el ejecutable de la app (`Platform.resolvedExecutable`).
/// Esto permite que la configuración viaje con la app, se lea de forma
/// síncrona antes de arrancar y no dependa de carpetas de usuario ni de
/// SharedPreferences, que en Windows/desktop tiene historial de no flushear
/// correctamente al cerrar la app.
///
/// En móvil (Android/iOS) se usa `getApplicationSupportDirectory()` más
/// SharedPreferences como respaldo.
///
/// La lectura prioriza el directorio del ejecutable en escritorio; si no hay
/// nada, cae a SharedPreferences y luego a los directorios de soporte/documentos.
class LocalStorageService {
  final String key;

  LocalStorageService(this.key);

  // ---------------------------------------------------------------------------
  // Rutas
  // ---------------------------------------------------------------------------

  /// Directorio raíz de la aplicación: donde se encuentra el ejecutable.
  /// Disponible solo en escritorio.
  String? get _appRootPath {
    if (kIsWeb) return null;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        return File(Platform.resolvedExecutable).parent.path;
      } catch (e) {
        debugPrint('[LocalStorageService:$key] No se pudo obtener raíz de app: $e');
        return null;
      }
    }
    return null;
  }

  File? get _rootFile {
    final root = _appRootPath;
    if (root == null) return null;
    return File('$root/$key.json');
  }

  Future<File> get _supportFile async {
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

  // ---------------------------------------------------------------------------
  // Lectura síncrona (escritorio)
  // ---------------------------------------------------------------------------

  /// Lee el archivo de configuración ubicado junto al ejecutable.
  /// Retorna null si no existe, está vacío o no estamos en escritorio.
  String? readSync() {
    final file = _rootFile;
    if (file == null) {
      debugPrint('[LocalStorageService:$key] readSync: no disponible en esta plataforma');
      return null;
    }

    try {
      debugPrint('[LocalStorageService:$key] readSync buscando: ${file.path}');
      if (file.existsSync()) {
        final value = file.readAsStringSync();
        if (value.isNotEmpty) {
          debugPrint('[LocalStorageService:$key] readSync: valor encontrado (${value.length} chars)');
          return value;
        }
      }
      debugPrint('[LocalStorageService:$key] readSync: archivo no existe o vacío');
    } catch (e, stack) {
      debugPrint('[LocalStorageService:$key] readSync error: $e');
      debugPrint(stack.toString());
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Escritura síncrona (escritorio)
  // ---------------------------------------------------------------------------

  /// Escribe el archivo de configuración junto al ejecutable.
  /// Retorna true si pudo verificar que el archivo quedó guardado.
  bool writeSync(String value) {
    final file = _rootFile;
    if (file == null) {
      debugPrint('[LocalStorageService:$key] writeSync: no disponible en esta plataforma');
      return false;
    }

    try {
      debugPrint('[LocalStorageService:$key] writeSync escribiendo: ${file.path}');
      file.writeAsStringSync(value, flush: true);
      final saved = file.readAsStringSync();
      if (saved == value) {
        debugPrint('[LocalStorageService:$key] writeSync: guardado y verificado');
        return true;
      }
      debugPrint('[LocalStorageService:$key] writeSync: verificación falló');
    } catch (e, stack) {
      debugPrint('[LocalStorageService:$key] writeSync error: $e');
      debugPrint(stack.toString());
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Escritura asíncrona (todas las plataformas)
  // ---------------------------------------------------------------------------

  Future<bool> write(String value) async {
    var success = false;

    // 1) Escritorio: archivo junto al ejecutable (síncrono, más confiable).
    if (writeSync(value)) {
      success = true;
    }

    // 2) SharedPreferences
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

    // 3) Archivo de soporte de la app
    try {
      final file = await _supportFile;
      debugPrint('[LocalStorageService:$key] Escribiendo archivo de soporte: ${file.path}');
      await file.writeAsString(value, flush: true);
      final saved = await file.readAsString();
      if (saved == value) {
        debugPrint('[LocalStorageService:$key] Guardado en archivo de soporte');
        success = true;
      }
    } catch (e, stack) {
      debugPrint('[LocalStorageService:$key] Error guardando archivo de soporte: $e');
      debugPrint(stack.toString());
    }

    // 4) Archivo legado en Documentos (redundancia adicional)
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

  // ---------------------------------------------------------------------------
  // Lectura asíncrona (todas las plataformas)
  // ---------------------------------------------------------------------------

  Future<String?> read() async {
    // 1) Escritorio: intentar archivo junto al ejecutable.
    final syncValue = readSync();
    if (syncValue != null) {
      // Restaurar en SharedPreferences para coherencia en otras rutas.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, syncValue);
      } catch (e) {
        debugPrint('[LocalStorageService:$key] No se pudo restaurar en SharedPreferences: $e');
      }
      return syncValue;
    }

    // 2) SharedPreferences
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

    // 3) Archivo de soporte
    try {
      final file = await _supportFile;
      debugPrint('[LocalStorageService:$key] Buscando archivo de soporte: ${file.path}');
      if (await file.exists()) {
        final value = await file.readAsString();
        if (value.isNotEmpty) {
          debugPrint('[LocalStorageService:$key] Leído de archivo de soporte');
          return value;
        }
      }
    } catch (e, stack) {
      debugPrint('[LocalStorageService:$key] Error leyendo archivo de soporte: $e');
      debugPrint(stack.toString());
    }

    // 4) Archivo legado
    try {
      final file = await _legacyFile;
      if (file != null) {
        debugPrint('[LocalStorageService:$key] Buscando archivo legado: ${file.path}');
        if (await file.exists()) {
          final value = await file.readAsString();
          if (value.isNotEmpty) {
            debugPrint('[LocalStorageService:$key] Leído de archivo legado');
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

  // ---------------------------------------------------------------------------
  // Eliminación
  // ---------------------------------------------------------------------------

  Future<bool> delete() async {
    var success = false;

    final root = _rootFile;
    if (root != null) {
      try {
        if (root.existsSync()) {
          root.deleteSync();
          success = true;
        }
      } catch (e) {
        debugPrint('[LocalStorageService:$key] Error eliminando archivo raíz: $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      if (await prefs.remove(key)) success = true;
    } catch (e) {
      debugPrint('[LocalStorageService:$key] Error eliminando SharedPreferences: $e');
    }

    try {
      final support = await _supportFile;
      if (await support.exists()) {
        await support.delete();
        success = true;
      }
    } catch (e) {
      debugPrint('[LocalStorageService:$key] Error eliminando archivo de soporte: $e');
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
}
