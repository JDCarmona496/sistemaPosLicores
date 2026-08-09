import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/providers/shift_providers.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../domain/models/user.dart';
import '../../cash_count/views/widgets/close_shift_dialog.dart';
import '../../cash_count/views/widgets/start_shift_dialog.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  final _authService = AuthService();
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.getCurrentUser();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('[DashboardView] Error cargando usuario: $e');
      debugPrint(st.toString());
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final shiftState = ref.read(currentShiftProvider);

    if (shiftState.shift != null) {
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CloseShiftDialog(),
      );
    }

    await _authService.signOut();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error al cargar usuario',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'No se pudo obtener la información del usuario.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUser,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final shiftState = ref.watch(currentShiftProvider);
    final modulesEnabled = shiftState.shift != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      _user!.fullName.isNotEmpty
                          ? _user!.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user!.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _user!.email,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(_user!.role),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getRoleName(_user!.role),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildShiftStatusButton(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Módulos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (!modulesEnabled)
                Chip(
                  label: const Text('Bloqueado'),
                  backgroundColor: Colors.red.shade100,
                  side: BorderSide.none,
                ),
            ],
          ),
          if (!modulesEnabled) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Abre un turno desde el botón del header para habilitar los módulos.',
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          IgnorePointer(
            ignoring: !modulesEnabled,
            child: Opacity(
              opacity: modulesEnabled ? 1.0 : 0.5,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 900
                      ? 4
                      : constraints.maxWidth > 600
                          ? 3
                          : 2;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: constraints.maxWidth < 360 ? 0.9 : 1.0,
                    children: [
                  _buildModuleCard(
                    context,
                    icon: Icons.shopping_cart,
                    title: 'Pedidos',
                    route: '/orders',
                    color: Colors.blue,
                    enabled: modulesEnabled,
                  ),
                  _buildModuleCard(
                    context,
                    icon: Icons.inventory,
                    title: 'Productos',
                    route: '/products',
                    color: Colors.green,
                    enabled: modulesEnabled,
                  ),
                  _buildModuleCard(
                    context,
                    icon: Icons.people,
                    title: 'Clientes',
                    route: '/customers',
                    color: Colors.orange,
                    enabled: modulesEnabled,
                  ),
                  _buildModuleCard(
                    context,
                    icon: Icons.delivery_dining,
                    title: 'Domicilios',
                    route: '/delivery',
                    color: Colors.purple,
                    enabled: modulesEnabled,
                  ),
                  _buildModuleCard(
                    context,
                    icon: Icons.credit_card,
                    title: 'Créditos',
                    route: '/credits',
                    color: Colors.indigo,
                    enabled: modulesEnabled,
                  ),
                  _buildModuleCard(
                    context,
                    icon: Icons.bar_chart,
                    title: 'Reportes',
                    route: '/reports',
                    color: Colors.red,
                    enabled: modulesEnabled,
                  ),
                  if (_user?.role == UserRole.admin)
                    _buildModuleCard(
                      context,
                      icon: Icons.manage_accounts,
                      title: 'Usuarios',
                      route: '/users',
                      color: Colors.deepPurple,
                      enabled: modulesEnabled,
                    ),
                  _buildModuleCard(
                    context,
                    icon: Icons.account_balance_wallet,
                    title: 'Conteo de caja',
                    route: '/cash-count',
                    color: Colors.teal,
                    enabled: modulesEnabled,
                  ),
                  _buildModuleCard(
                    context,
                    icon: Icons.settings,
                    title: 'Configuración',
                    route: '/settings',
                    color: Colors.grey,
                    enabled: modulesEnabled,
                  ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftStatusButton() {
    final shiftState = ref.watch(currentShiftProvider);

    if (shiftState.isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final hasShift = shiftState.shift != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Chip(
          label: Text(
            hasShift ? 'Turno abierto' : 'Sin turno',
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor:
              hasShift ? Colors.green.shade100 : Colors.red.shade100,
          side: BorderSide.none,
        ),
        const SizedBox(height: 4),
        if (hasShift)
          OutlinedButton.icon(
            onPressed: () => _showCloseShiftDialog(),
            icon: const Icon(Icons.stop, size: 16),
            label: const Text('Cerrar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          )
        else
          FilledButton.icon(
            onPressed: () => _showStartShiftDialog(),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Empezar'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
      ],
    );
  }

  Future<void> _showStartShiftDialog() async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const StartShiftDialog(),
    );
  }

  Future<void> _showCloseShiftDialog() async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CloseShiftDialog(),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required Color color,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Card(
        child: InkWell(
          onTap: enabled ? () => context.push(route) : null,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.seller:
        return Colors.blue;
      case UserRole.delivery:
        return Colors.green;
    }
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.seller:
        return 'Vendedor';
      case UserRole.delivery:
        return 'Domiciliario';
    }
  }
}
