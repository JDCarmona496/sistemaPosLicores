import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/supabase_config.dart';
import '../../data/services/auth_service.dart';
import '../../domain/models/user.dart';

/// Usuario autenticado actual con su perfil extendido.
final currentUserProvider = FutureProvider<User>((ref) async {
  return AuthService().getCurrentUser();
});

final deliveryUsersProvider = FutureProvider<List<User>>((ref) async {
  final client = SupabaseConfig.client;
  final data = await client
      .from('profiles')
      .select()
      .eq('role', 'delivery')
      .eq('is_active', true)
      .order('full_name');

  return data.map((json) => User.fromJson(json)).toList();
});
