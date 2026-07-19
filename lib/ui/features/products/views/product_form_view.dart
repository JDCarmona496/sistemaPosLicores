import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/providers/product_providers.dart';
import '../../../../data/repositories/brand_repository.dart';
import '../../../../data/repositories/category_repository.dart';
import '../../../../domain/models/product.dart';

class ProductFormView extends ConsumerStatefulWidget {
  final String? productId;

  const ProductFormView({super.key, this.productId});

  @override
  ConsumerState<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends ConsumerState<ProductFormView> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _presentationController = TextEditingController();
  final _volumeController = TextEditingController();
  final _unitsPerPackageController = TextEditingController(text: '1');
  final _priceRetailController = TextEditingController();
  final _priceWholesaleController = TextEditingController();
  final _priceColdController = TextEditingController();
  final _costController = TextEditingController();
  final _stockCurrentController = TextEditingController(text: '0');
  final _stockMinController = TextEditingController(text: '5');
  final _stockMaxController = TextEditingController(text: '100');
  final _returnableDepositController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();

  String? _selectedBrandId;
  String? _selectedCategoryId;
  PackagingType _packagingType = PackagingType.unit;
  ProductStatus _status = ProductStatus.active;
  bool _isCold = false;
  bool _isReturnable = false;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _isEditing = true;
      _loadProduct();
    } else {
      _generateNextCode();
    }
  }

  Future<void> _generateNextCode() async {
    try {
      final nextCode = await ref.read(productsProvider.notifier).getNextCode();
      if (mounted) {
        _codeController.text = nextCode.toString();
      }
    } catch (e) {
      if (mounted) {
        _codeController.text = '1000';
      }
    }
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    try {
      final product = await ref.read(productRepositoryProvider).getById(widget.productId!);
      if (product == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto no encontrado'),
              backgroundColor: Colors.red,
            ),
          );
          context.pop();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _codeController.text = product.code.toString();
          _nameController.text = product.name;
          _barcodeController.text = product.barcode ?? '';
          _presentationController.text = product.presentation;
          _volumeController.text = product.volumeMl?.toString() ?? '';
          _unitsPerPackageController.text = product.unitsPerPackage.toString();
          _priceRetailController.text = product.priceRetail.toString();
          _priceWholesaleController.text = product.priceWholesale.toString();
          _priceColdController.text = product.priceCold?.toString() ?? '';
          _costController.text = product.cost.toString();
          _stockCurrentController.text = product.stockCurrent.toString();
          _stockMinController.text = product.stockMin.toString();
          _stockMaxController.text = product.stockMax.toString();
          _returnableDepositController.text = product.returnableDeposit.toString();
          _descriptionController.text = product.description ?? '';
          _selectedBrandId = product.brandId;
          _selectedCategoryId = product.categoryId;
          _packagingType = product.packagingType;
          _status = product.status;
          _isCold = product.isCold;
          _isReturnable = product.isReturnable;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar producto: $e'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _barcodeController.dispose();
    _presentationController.dispose();
    _volumeController.dispose();
    _unitsPerPackageController.dispose();
    _priceRetailController.dispose();
    _priceWholesaleController.dispose();
    _priceColdController.dispose();
    _costController.dispose();
    _stockCurrentController.dispose();
    _stockMinController.dispose();
    _stockMaxController.dispose();
    _returnableDepositController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBrandId == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una marca y una categoría'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_barcodeController.text.isNotEmpty) {
      final existing = await ref
          .read(productsProvider.notifier)
          .getByBarcode(_barcodeController.text);
      if (existing != null && existing.id != (widget.productId ?? '')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('El código de barras ya está en uso: ${existing.name}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final product = Product(
        id: widget.productId ?? '',
        code: int.parse(_codeController.text),
        name: _nameController.text,
        brandId: _selectedBrandId!,
        categoryId: _selectedCategoryId!,
        presentation: _presentationController.text,
        packagingType: _packagingType,
        unitsPerPackage: int.parse(_unitsPerPackageController.text),
        priceRetail: double.parse(_priceRetailController.text),
        priceWholesale: double.parse(_priceWholesaleController.text),
        priceCold: _priceColdController.text.isNotEmpty
            ? double.parse(_priceColdController.text)
            : null,
        cost: double.parse(_costController.text),
        stockCurrent: int.parse(_stockCurrentController.text),
        stockMin: int.parse(_stockMinController.text),
        stockMax: int.parse(_stockMaxController.text),
        barcode: _barcodeController.text.isNotEmpty ? _barcodeController.text : null,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        volumeMl: _volumeController.text.isNotEmpty ? int.parse(_volumeController.text) : null,
        isCold: _isCold,
        isReturnable: _isReturnable,
        returnableDeposit: double.parse(_returnableDepositController.text),
        status: _status,
      );

      if (_isEditing) {
        await ref.read(productsProvider.notifier).updateProduct(product);
      } else {
        await ref.read(productsProvider.notifier).createProduct(product);
      }

      if (mounted) {
        context.pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Producto actualizado correctamente' : 'Producto creado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Nuevo Producto'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProduct,
              tooltip: 'Guardar',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionTitle('Información Básica'),
                  const SizedBox(height: 12),
                  _buildBasicInfoCard(),
                  const SizedBox(height: 16),
                  _buildBrandCategoryRow(brandsAsync, categoriesAsync),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Empaque'),
                  const SizedBox(height: 12),
                  _buildPackagingCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Precios'),
                  const SizedBox(height: 12),
                  _buildPricesCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Inventario'),
                  const SizedBox(height: 12),
                  _buildInventoryCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Estado'),
                  const SizedBox(height: 12),
                  _buildStatusCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Descripción'),
                  const SizedBox(height: 12),
                  _buildDescriptionCard(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      child: Text(_isEditing ? 'Actualizar Producto' : 'Crear Producto'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  /// Código + escáner de barras en una fila amplia.
  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Código interno',
                      prefixIcon: Icon(Icons.tag),
                      helperText: 'Generado automáticamente',
                    ),
                    keyboardType: TextInputType.number,
                    enabled: false,
                    validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _barcodeController,
                        decoration: InputDecoration(
                          labelText: 'Código de barras',
                          prefixIcon: const Icon(Icons.qr_code),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            tooltip: 'Escanear con cámara',
                            onPressed: () => _scanBarcode(),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _scanBarcode(),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Capturar código de barras'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _presentationController,
                    decoration: const InputDecoration(
                      labelText: 'Presentación *',
                      hintText: '330ml, 750ml, etc.',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _volumeController,
                    decoration: const InputDecoration(
                      labelText: 'Volumen (ml)',
                      prefixIcon: Icon(Icons.local_drink),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandCategoryRow(
    AsyncValue<List<Brand>> brandsAsync,
    AsyncValue<List<Category>> categoriesAsync,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRow = constraints.maxWidth >= 500;
        final children = [
          Expanded(
            child: brandsAsync.when(
              data: (brands) => DropdownButtonFormField<String>(
                value: _selectedBrandId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Marca *',
                  prefixIcon: Icon(Icons.branding_watermark),
                ),
                items: brands
                    .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedBrandId = value),
                validator: (value) => value == null ? 'Requerido' : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Error: $error'),
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              data: (categories) => DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Categoría *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: categories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategoryId = value),
                validator: (value) => value == null ? 'Requerido' : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Error: $error'),
            ),
          ),
        ];
        return useRow
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  children[0],
                  const SizedBox(width: 16),
                  children[1],
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  children[0],
                  const SizedBox(height: 16),
                  children[1],
                ],
              );
      },
    );
  }

  Widget _buildPackagingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<PackagingType>(
                    value: _packagingType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Empaque *',
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    items: PackagingType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(_getPackagingName(t)),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _packagingType = value!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unitsPerPackageController,
                    decoration: const InputDecoration(
                      labelText: 'Unidades/Empaque *',
                      prefixIcon: Icon(Icons.format_list_numbered),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final useRow = constraints.maxWidth >= 500;
                final children = [
                  _buildSwitchTile(
                    'Frío',
                    'Requiere refrigeración',
                    _isCold,
                    (value) => setState(() => _isCold = value),
                  ),
                  _buildSwitchTile(
                    'Retornable',
                    'Envase retornable',
                    _isReturnable,
                    (value) => setState(() => _isReturnable = value),
                  ),
                ];
                return useRow
                    ? Row(children: children.map((c) => Expanded(child: c)).toList())
                    : Column(children: children);
              },
            ),
            if (_isReturnable) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _returnableDepositController,
                decoration: const InputDecoration(
                  labelText: 'Depósito Retornable',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildPricesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextFieldRow(
              _priceRetailController,
              'Precio Detal *',
              Icons.attach_money,
              const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildTextFieldRow(
              _priceWholesaleController,
              'Precio Mayorista *',
              Icons.attach_money,
              const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildTextFieldRow(
              _priceColdController,
              'Precio Frío',
              Icons.ac_unit,
              const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            _buildTextFieldRow(
              _costController,
              'Costo *',
              Icons.money_off,
              const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final children = [
              _buildInventoryField(
                _stockCurrentController,
                'Stock Actual *',
                Icons.inventory,
              ),
              const SizedBox(width: 12),
              _buildInventoryField(
                _stockMinController,
                'Stock Mínimo *',
                Icons.warning,
              ),
              const SizedBox(width: 12),
              _buildInventoryField(
                _stockMaxController,
                'Stock Máximo *',
                Icons.check_circle,
              ),
            ];
            if (constraints.maxWidth < 600) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInventoryField(
                    _stockCurrentController,
                    'Stock Actual *',
                    Icons.inventory,
                  ),
                  const SizedBox(height: 16),
                  _buildInventoryField(
                    _stockMinController,
                    'Stock Mínimo *',
                    Icons.warning,
                  ),
                  const SizedBox(height: 16),
                  _buildInventoryField(
                    _stockMaxController,
                    'Stock Máximo *',
                    Icons.check_circle,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            );
          },
        ),
      ),
    );
  }

  Widget _buildInventoryField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Expanded(
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        keyboardType: TextInputType.number,
        validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<ProductStatus>(
          value: _status,
          // TODO: reemplazar por initialValue cuando Flutter sea >= 3.33
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Estado *',
            prefixIcon: Icon(Icons.info),
          ),
          items: const [
            DropdownMenuItem(
              value: ProductStatus.active,
              child: Text('Activo'),
            ),
            DropdownMenuItem(
              value: ProductStatus.outOfStock,
              child: Text('Sin Stock'),
            ),
            DropdownMenuItem(
              value: ProductStatus.discontinued,
              child: Text('Descontinuado'),
            ),
          ],
          onChanged: (value) => setState(() => _status = value!),
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
        ),
      ),
    );
  }

  Widget _buildTextFieldRow(
    TextEditingController controller,
    String label,
    IconData icon,
    TextInputType keyboardType, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _getPackagingName(PackagingType type) {
    switch (type) {
      case PackagingType.unit:
        return 'Unidad';
      case PackagingType.sixpack:
        return 'Sixpack';
      case PackagingType.basket:
        return 'Canasta';
      case PackagingType.pack:
        return 'Paca';
      case PackagingType.box:
        return 'Caja';
      case PackagingType.packCigarettes:
        return 'Cajetilla';
      case PackagingType.halfPack:
        return 'Media';
    }
  }

  Future<void> _scanBarcode() async {
    final result = await context.push<String>('/products/scan');
    if (result != null && mounted) {
      _barcodeController.text = result;
    }
  }
}
