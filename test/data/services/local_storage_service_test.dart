import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:applicoresestacion/data/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportDir;
  late Directory documentsDir;

  setUp(() async {
    final baseDir = await Directory.systemTemp.createTemp('local_storage_test_');
    supportDir = Directory('${baseDir.path}/support');
    documentsDir = Directory('${baseDir.path}/documents');
    await supportDir.create();
    await documentsDir.create();

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
  });

  group('LocalStorageService', () {
    test('write guarda y read recupera el valor', () async {
      const value = '{"key":"value"}';
      final service = LocalStorageService('test_key');

      final saved = await service.write(value);
      expect(saved, isTrue);

      final read = await service.read();
      expect(read, equals(value));
    });

    test('read recupera desde archivo cuando SharedPreferences está vacío', () async {
      const value = '{"only":"file"}';
      final service = LocalStorageService('file_only_key');

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
      final service = LocalStorageService('legacy_key');

      // Guardar usando el nuevo servicio (llena primario y legado).
      await service.write(value);
      // Borrar el primario para simular que solo queda el legado.
      final primaryFile = File('${supportDir.path}/applicoresestacion/legacy_key.json');
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
      final service = LocalStorageService('delete_key');

      await service.write(value);
      final deleted = await service.delete();
      expect(deleted, isTrue);

      final read = await service.read();
      expect(read, isNull);
    });
  });
}
