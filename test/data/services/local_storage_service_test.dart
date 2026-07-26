import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:applicoresestacion/data/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportDir;
  late Directory documentsDir;
  final rootFiles = <File>[];

  setUp(() async {
    final baseDir = await Directory.systemTemp.createTemp('local_storage_test_');
    supportDir = Directory('${baseDir.path}/support');
    documentsDir = Directory('${baseDir.path}/documents');
    await supportDir.create();
    await documentsDir.create();
    rootFiles.clear();

    // Mockear path_provider para que cada método apunte a su propia carpeta.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (methodCall) async {
        switch (methodCall.method) {
          case 'getApplicationSupportDirectory':
            return supportDir.path;
          case 'getApplicationDocumentsDirectory':
            return documentsDir.path;
          default:
            return null;
        }
      },
    );

    // Mockear SharedPreferences con valores vacíos.
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    final baseDir = supportDir.parent;
    if (await baseDir.exists()) {
      await baseDir.delete(recursive: true);
    }
    // En escritorio, writeSync escribe junto al ejecutable del test.
    // Limpiamos esos archivos para no contaminar el directorio de Flutter.
    for (final file in rootFiles) {
      try {
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {
        // Ignorar errores de limpieza.
      }
    }
    rootFiles.clear();
  });

  File? rootFileFor(String key) {
    if (kIsWeb) return null;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return File('${File(Platform.resolvedExecutable).parent.path}/$key.json');
    }
    return null;
  }

  group('LocalStorageService', () {
    test('writeSync y readSync guardan y leen en escritorio', () {
      if (kIsWeb ||
          !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        return;
      }

      const value = '{"sync":"true"}';
      const key = 'sync_test_key';
      final service = LocalStorageService(key);
      final rootFile = rootFileFor(key);
      if (rootFile != null) rootFiles.add(rootFile);

      final saved = service.writeSync(value);
      expect(saved, isTrue);

      final read = service.readSync();
      expect(read, equals(value));
    });

    test('write guarda y read recupera el valor', () async {
      const value = '{"key":"value"}';
      const key = 'test_key';
      final service = LocalStorageService(key);
      final rootFile = rootFileFor(key);
      if (rootFile != null) rootFiles.add(rootFile);

      final saved = await service.write(value);
      expect(saved, isTrue);

      final read = await service.read();
      expect(read, equals(value));
    });

    test('read recupera desde archivo cuando SharedPreferences está vacío', () async {
      const value = '{"only":"file"}';
      const key = 'file_only_key';
      final service = LocalStorageService(key);
      final rootFile = rootFileFor(key);
      if (rootFile != null) rootFiles.add(rootFile);

      // Escribir sin SharedPreferences (usando write, que llena ambos).
      await service.write(value);
      // Limpiar SharedPreferences para simular que falló.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final read = await service.read();
      expect(read, equals(value));
    });

    test('read recupera desde archivo legado cuando no existe el primario', () async {
      const value = '{"legacy":"true"}';
      const key = 'legacy_key';
      final service = LocalStorageService(key);
      final rootFile = rootFileFor(key);
      if (rootFile != null) rootFiles.add(rootFile);

      // Guardar usando el nuevo servicio (llena primario y legado).
      await service.write(value);
      // Borrar el primario para simular que solo queda el legado.
      final primaryFile = File('${supportDir.path}/applicoresestacion/$key.json');
      if (await primaryFile.exists()) {
        await primaryFile.delete();
      }
      // Limpiar SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final read = await service.read();
      expect(read, equals(value));
    });

    test('delete elimina el valor de todos los almacenamientos', () async {
      const value = '{"delete":"me"}';
      const key = 'delete_key';
      final service = LocalStorageService(key);
      final rootFile = rootFileFor(key);
      if (rootFile != null) rootFiles.add(rootFile);

      await service.write(value);
      final deleted = await service.delete();
      expect(deleted, isTrue);

      final read = await service.read();
      expect(read, isNull);
    });
  });
}
