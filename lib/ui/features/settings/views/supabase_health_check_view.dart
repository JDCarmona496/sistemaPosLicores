import 'package:flutter/material.dart';
import '../../../../data/services/supabase_health_check_service.dart';

class SupabaseHealthCheckView extends StatefulWidget {
  const SupabaseHealthCheckView({super.key});

  @override
  State<SupabaseHealthCheckView> createState() => _SupabaseHealthCheckViewState();
}

class _SupabaseHealthCheckViewState extends State<SupabaseHealthCheckView> {
  final _service = SupabaseHealthCheckService();
  List<SupabaseHealthCheckResult>? _results;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runChecks();
  }

  Future<void> _runChecks() async {
    setState(() {
      _isLoading = true;
      _results = null;
    });

    final results = await _service.runAllChecks();

    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Supabase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _runChecks,
            tooltip: 'Ejecutar verificaciones nuevamente',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results == null
              ? const Center(child: Text('No hay resultados'))
              : _buildResults(),
    );
  }

  Widget _buildResults() {
    final successCount = _results!.where((r) => r.success).length;
    final totalCount = _results!.length;
    final allPassed = successCount == totalCount;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          color: allPassed ? Colors.green.shade50 : Colors.red.shade50,
          child: Column(
            children: [
              Icon(
                allPassed ? Icons.check_circle : Icons.error,
                size: 64,
                color: allPassed ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                allPassed ? 'Todas las verificaciones pasaron' : 'Algunas verificaciones fallaron',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: allPassed ? Colors.green.shade900 : Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '$successCount de $totalCount verificaciones exitosas',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: allPassed ? Colors.green.shade700 : Colors.red.shade700,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _results!.length,
            itemBuilder: (context, index) {
              final result = _results![index];
              return _buildResultCard(result);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(SupabaseHealthCheckResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.testName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.message,
                    style: TextStyle(
                      color: result.success ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tiempo: ${result.duration.inMilliseconds}ms',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
