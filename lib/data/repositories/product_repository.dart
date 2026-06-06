import '../../config/supabase_config.dart';
import '../../domain/models/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<Product>> getAll({
    String? search,
    String? categoryId,
    String? brandId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client.from('products').select();

    if (search != null && search.isNotEmpty) {
      final codeValue = int.tryParse(search);
      if (codeValue != null) {
        query = query.or('name.ilike.%$search%,code.eq.$codeValue,barcode.eq.$search');
      } else {
        query = query.or('name.ilike.%$search%,barcode.eq.$search');
      }
    }

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    if (brandId != null) {
      query = query.eq('brand_id', brandId);
    }

    if (status != null) {
      query = query.eq('status', status);
    }

    final data = await query
        .order('name')
        .range(offset, offset + limit - 1);

    return data.map((json) => Product.fromJson(json)).toList();
  }

  Future<Product?> getById(String id) async {
    try {
      final data = await _client
          .from('products')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) return null;
      return Product.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<Product?> getByBarcode(String barcode) async {
    try {
      final data = await _client
          .from('products')
          .select()
          .eq('barcode', barcode)
          .maybeSingle();

      if (data == null) return null;
      return Product.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<Product?> getByCode(int code) async {
    try {
      final data = await _client
          .from('products')
          .select()
          .eq('code', code)
          .maybeSingle();

      if (data == null) return null;
      return Product.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<Product> create(Product product) async {
    final data = product.toSupabaseJson()..remove('id');
    
    final result = await _client
        .from('products')
        .insert(data)
        .select()
        .single();

    return Product.fromJson(result);
  }

  Future<Product> update(Product product) async {
    final data = product.toSupabaseJson();
    
    final result = await _client
        .from('products')
        .update(data)
        .eq('id', product.id)
        .select()
        .single();

    return Product.fromJson(result);
  }

  Future<void> delete(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  Future<int> getNextCode() async {
    try {
      final data = await _client
          .from('products')
          .select('code')
          .order('code', ascending: false)
          .limit(1);

      if (data.isEmpty) {
        return 1000;
      }

      return (data.first['code'] as int) + 1;
    } catch (e) {
      return 1000;
    }
  }

  Future<void> updateStock(String productId, int quantityChange) async {
    await _client
        .from('products')
        .update({'stock_current': _client.rpc(
          'increment_stock',
          params: {'product_id': productId, 'quantity': quantityChange},
        )})
        .eq('id', productId);
  }
}
