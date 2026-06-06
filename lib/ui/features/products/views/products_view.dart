import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/providers/product_providers.dart';
import '../../../../data/repositories/brand_repository.dart';
import '../../../../data/repositories/category_repository.dart';
import '../../../../domain/models/product.dart';

class ProductsView extends ConsumerStatefulWidget {
  const ProductsView({super.key});

  @override
  ConsumerState<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends ConsumerState<ProductsView> {
  final _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/products/scan'),
            tooltip: 'Escanear código',
          ),
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, código o código de barras...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(productsProvider.notifier).setSearch(null);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                ref.read(productsProvider.notifier).setSearch(value.isEmpty ? null : value);
              },
            ),
          ),
          if (_showFilters) _buildFilters(categoriesAsync, brandsAsync, productsState),
          Expanded(
            child: _buildProductsList(productsState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/products/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilters(
    AsyncValue<List<Category>> categoriesAsync,
    AsyncValue<List<Brand>> brandsAsync,
    ProductsState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<String?>(
                    value: state.selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                      ...categories.map((c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(c.name),
                      )),
                    ],
                    onChanged: (value) {
                      ref.read(productsProvider.notifier).setCategory(value);
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text('Error: $error'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: brandsAsync.when(
                  data: (brands) => DropdownButtonFormField<String?>(
                    value: state.selectedBrandId,
                    decoration: const InputDecoration(
                      labelText: 'Marca',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                      ...brands.map((b) => DropdownMenuItem<String?>(
                        value: b.id,
                        child: Text(b.name),
                      )),
                    ],
                    onChanged: (value) {
                      ref.read(productsProvider.notifier).setBrand(value);
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text('Error: $error'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.selectedCategoryId != null || state.selectedBrandId != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  ref.read(productsProvider.notifier).clearFilters();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar filtros'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsList(ProductsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(productsProvider.notifier).loadProducts(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay productos',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              state.searchQuery != null || state.selectedCategoryId != null || state.selectedBrandId != null
                  ? 'No se encontraron productos con los filtros aplicados'
                  : 'Agrega tu primer producto',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            if (state.searchQuery != null || state.selectedCategoryId != null || state.selectedBrandId != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(productsProvider.notifier).clearFilters();
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(productsProvider.notifier).loadProducts(),
      child: ListView.builder(
        itemCount: state.products.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final product = state.products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/products/${product.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.inventory),
                        ),
                      )
                    : const Icon(Icons.inventory, size: 32, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${product.code}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (product.isCold)
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.lightBlue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.ac_unit,
                              size: 16,
                              color: Colors.lightBlue.shade700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.presentation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${product.priceRetail.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStockBadge(product.stockCurrent, product.stockMin),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge(int current, int min) {
    Color bgColor;
    Color textColor;
    IconData icon;

    if (current == 0) {
      bgColor = Colors.red.shade100;
      textColor = Colors.red.shade700;
      icon = Icons.error_outline;
    } else if (current <= min) {
      bgColor = Colors.orange.shade100;
      textColor = Colors.orange.shade700;
      icon = Icons.warning_amber;
    } else {
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade700;
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            '$current',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
