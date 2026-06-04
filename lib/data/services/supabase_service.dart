import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';

class SupabaseService {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<Map<String, dynamic>>> select(
    String table, {
    String columns = '*',
    Map<String, dynamic>? filters,
    int? limit,
    String? orderBy,
    bool ascending = true,
  }) async {
    var query = _client.from(table).select(columns);

    if (filters != null) {
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
    }

    if (orderBy != null) {
      query = query.order(orderBy, ascending: ascending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return await query;
  }

  Future<Map<String, dynamic>> selectOne(
    String table, {
    String columns = '*',
    required Map<String, dynamic> filters,
  }) async {
    var query = _client.from(table).select(columns);

    filters.forEach((key, value) {
      query = query.eq(key, value);
    });

    return await query.single();
  }

  Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    return await _client.from(table).insert(data).select().single();
  }

  Future<List<Map<String, dynamic>>> insertMany(
    String table,
    List<Map<String, dynamic>> dataList,
  ) async {
    return await _client.from(table).insert(dataList).select();
  }

  Future<Map<String, dynamic>> update(
    String table,
    Map<String, dynamic> data, {
    required Map<String, dynamic> filters,
  }) async {
    var query = _client.from(table).update(data);

    filters.forEach((key, value) {
      query = query.eq(key, value);
    });

    return await query.select().single();
  }

  Future<void> delete(
    String table, {
    required Map<String, dynamic> filters,
  }) async {
    var query = _client.from(table).delete();

    filters.forEach((key, value) {
      query = query.eq(key, value);
    });

    await query;
  }

  Future<List<Map<String, dynamic>>> rpc(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    final response = await _client.rpc(functionName, params: params);
    return response as List<Map<String, dynamic>>;
  }

  Stream<List<Map<String, dynamic>>> subscribe(
    String table, {
    String? filter,
  }) {
    return _client
        .channel(table)
        .postgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: filter != null ? PostgresChangeFilter.from(filter) : null,
          callback: (payload) {},
        )
        .stream
        .map((_) => []);
  }
}
