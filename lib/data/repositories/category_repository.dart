import '../../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Category {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? parentId;
  final String? iconUrl;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.parentId,
    this.iconUrl,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      parentId: json['parent_id'],
      iconUrl: json['icon_url'],
      isActive: json['is_active'] ?? true,
    );
  }
}

class CategoryRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<Category>> getAll({bool activeOnly = true}) async {
    var query = _client.from('categories').select();

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final data = await query.order('name');
    return data.map((json) => Category.fromJson(json)).toList();
  }

  Future<Category> create(Category category) async {
    final data = await _client
        .from('categories')
        .insert({
          'name': category.name,
          'slug': category.slug,
          'description': category.description,
          'parent_id': category.parentId,
          'icon_url': category.iconUrl,
        })
        .select()
        .single();

    return Category.fromJson(data);
  }
}
