import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/providers/product_providers.dart';
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
  final _priceWholesaleFractionalController = TextEditingController();
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
          _priceWholesaleFractionalController.text = product.priceWholesaleFractional?.toString() ?? '';
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
    _priceWholesaleFractionalController.dispose();
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
        priceWholesaleFractional: _priceWholesaleFractionalController.text.isNotEmpty
            ? double.parse(_priceWholesaleFractionalController.text)
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
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Código *',
                            prefixIcon: Icon(Icons.tag),
                          ),
                          keyboardType: TextInputType.number,
                          enabled: !_isEditing,
                          validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _barcodeController,
                          decoration: InputDecoration(
                            labelText: 'Código de Barras',
                            prefixIcon: const Icon(Icons.qr_code),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.qr_code_scanner),
                              onPressed: () => _scanBarcode(),
                            ),
                          ),
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
                        child: brandsAsync.when(
                          data: (brands) => DropdownButtonFormField<String>(
                            value: _selectedBrandId,
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
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, _) => Text('Error: $error'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: categoriesAsync.when(
                          data: (categories) => DropdownButtonFormField<String>(
                            value: _selectedCategoryId,
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
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, _) => Text('Error: $error'),
                        ),
                      ),
                    ],
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
                      const SizedBox(width: 16),
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
                  const SizedBox(height: 24),
                  _buildSectionTitle('Empaque'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<PackagingType>(
                          value: _packagingType,
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
                      const SizedBox(width: 16),
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
                  Row(
                    children: [
                      Expanded(
                        child: SwitchListTile(
                          title: const Text('Frío'),
                          subtitle: const Text('Requiere refrigeración'),
                          value: _isCold,
                          onChanged: (value) => setState(() => _isCold = value),
                        ),
                      ),
                      Expanded(
                        child: SwitchListTile(
                          title: const Text('Retornable'),
                          subtitle: const Text('Envase retornable'),
                          value: _isReturnable,
                          onChanged: (value) => setState(() => _isReturnable = value),
                        ),
                      ),
                    ],
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
                  const SizedBox(height: 24),
                  _buildSectionTitle('Precios'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceRetailController,
                          decoration: const InputDecoration(
                            labelText: 'Precio Detal *',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _priceWholesaleController,
                          decoration: const InputDecoration(
                            labelText: 'Precio Mayorista *',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceWholesaleFractionalController,
                          decoration: const InputDecoration(
                            labelText: 'Mayorista Fraccionado',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _costController,
                          decoration: const InputDecoration(
                            labelText: 'Costo *',
                            prefixIcon: Icon(Icons.money_off),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Inventario'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockCurrentController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Actual *',
                            prefixIcon: Icon(Icons.inventory),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stockMinController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Mínimo *',
                            prefixIcon: Icon(Icons.warning),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stockMaxController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Máximo *',
                            prefixIcon: Icon(Icons.check_circle),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Estado'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ProductStatus>(
                    value: _status,
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
                  const SizedBox(height: 24),
                  _buildSectionTitle('Descripción'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
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
