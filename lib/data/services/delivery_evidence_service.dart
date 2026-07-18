import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../config/supabase_config.dart';

/// Gestiona la subida de evidencias de entrega (firma y foto) a Supabase
/// Storage. Requiere un bucket público llamado `delivery-evidence`.
class DeliveryEvidenceService {
  static const _bucket = 'delivery-evidence';
  static const _uuid = Uuid();

  SupabaseClient get _client => SupabaseConfig.client;

  /// Sube una firma digital (PNG) y devuelve su URL pública.
  Future<String> uploadSignature({
    required String orderId,
    required Uint8List bytes,
  }) async {
    final path = 'orders/$orderId/signatures/${_uuid.v4()}.png';
    return _uploadBinary(path, bytes, 'image/png');
  }

  /// Sube una foto de entrega y devuelve su URL pública.
  Future<String> uploadPhoto({
    required String orderId,
    required Uint8List bytes,
    String? fileExtension,
  }) async {
    final ext = (fileExtension?.isNotEmpty ?? false) ? fileExtension! : 'jpg';
    final path = 'orders/$orderId/photos/${_uuid.v4()}.$ext';
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    return _uploadBinary(path, bytes, mime);
  }

  Future<String> _uploadBinary(
    String path,
    Uint8List bytes,
    String contentType,
  ) async {
    try {
      await _client.storage
          .from(_bucket)
          .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: contentType));

      final url = _client.storage.from(_bucket).getPublicUrl(path);
      return url;
    } on StorageException catch (e) {
      if (e.message.toLowerCase().contains('bucket not found') ||
          e.message.toLowerCase().contains('does not exist')) {
        throw Exception(
          'No existe el bucket "$_bucket" en Supabase Storage. '
          'Ejecuta el SQL de configuración del módulo de domicilios.',
        );
      }
      throw Exception('Error al subir evidencia: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al subir evidencia: $e');
    }
  }
}
