import '../../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Brand {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final bool isActive;

  Brand({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.isActive = true,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      logoUrl: json['logo_url'],
      isActive: json['is_active'] ?? true,
    );
  }
}

class BrandRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<Brand>> getAll({bool activeOnly = true}) async {
    var query = _client.from('brands').select();

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final data = await query.order('name');
    return data.map((json) => Brand.fromJson(json)).toList();
  }

  Future<Brand> create(Brand brand) async {
    final data = await _client
        .from('brands')
        .insert({
          'name': brand.name,
          'slug': brand.slug,
          'description': brand.description,
          'logo_url': brand.logoUrl,
        })
        .select()
        .single();

    return Brand.fromJson(data);
  }

  Future<Brand> update(Brand brand) async {
    final data = await _client
        .from('brands')
        .update({
          'name': brand.name,
          'slug': brand.slug,
          'description': brand.description,
          'logo_url': brand.logoUrl,
          'is_active': brand.isActive,
        })
        .eq('id', brand.id)
        .select()
        .single();

    return Brand.fromJson(data);
  }
}
