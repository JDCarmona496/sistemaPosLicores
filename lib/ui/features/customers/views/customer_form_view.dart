import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/providers/customer_providers.dart';
import '../../../../domain/models/customer.dart';

class CustomerFormView extends ConsumerStatefulWidget {
  final String? customerId;

  const CustomerFormView({super.key, this.customerId});

  @override
  ConsumerState<CustomerFormView> createState() => _CustomerFormViewState();
}

class _CustomerFormViewState extends ConsumerState<CustomerFormView> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _identificationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _creditLimitController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  CustomerType _customerType = CustomerType.occasional;
  CustomerStatus _status = CustomerStatus.active;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      _isEditing = true;
      _loadCustomer();
    }
  }

  Future<void> _loadCustomer() async {
    setState(() => _isLoading = true);
    try {
      final customer = await ref.read(customerRepositoryProvider).getById(widget.customerId!);
      if (customer == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente no encontrado'),
              backgroundColor: Colors.red,
            ),
          );
          context.pop();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _fullNameController.text = customer.fullName;
          _identificationController.text = customer.identification ?? '';
          _phoneController.text = customer.phone;
          _emailController.text = customer.email ?? '';
          _addressController.text = customer.address ?? '';
          _creditLimitController.text = customer.creditLimit.toString();
          _notesController.text = customer.notes ?? '';
          _customerType = customer.customerType;
          _status = customer.status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar cliente: $e'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _identificationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _creditLimitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      final customer = Customer(
        id: widget.customerId ?? '',
        fullName: _fullNameController.text,
        identification: _identificationController.text.isNotEmpty ? _identificationController.text : null,
        phone: _phoneController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
        customerType: _customerType,
        status: _status,
        creditLimit: _customerType == CustomerType.credit ? double.parse(_creditLimitController.text) : 0,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdBy: userId,
      );

      if (_isEditing) {
        await ref.read(customersProvider.notifier).updateCustomer(customer);
      } else {
        await ref.read(customersProvider.notifier).createCustomer(customer);
      }

      if (mounted) {
        context.pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Cliente actualizado correctamente' : 'Cliente creado correctamente'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Cliente' : 'Nuevo Cliente'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveCustomer,
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
                  _buildSectionTitle('Información Personal'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Completo *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _identificationController,
                    decoration: const InputDecoration(
                      labelText: 'Identificación (Cédula/NIT)',
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono *',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value?.isEmpty == true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Email inválido';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Tipo y Estado'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CustomerType>(
                    value: _customerType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Cliente *',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: CustomerType.occasional,
                        child: Text('Ocasional'),
                      ),
                      DropdownMenuItem(
                        value: CustomerType.frequent,
                        child: Text('Frecuente'),
                      ),
                      DropdownMenuItem(
                        value: CustomerType.wholesale,
                        child: Text('Mayorista'),
                      ),
                      DropdownMenuItem(
                        value: CustomerType.credit,
                        child: Text('Crédito'),
                      ),
                      DropdownMenuItem(
                        value: CustomerType.consignment,
                        child: Text('Consignación'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _customerType = value!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CustomerStatus>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Estado *',
                      prefixIcon: Icon(Icons.info),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: CustomerStatus.active,
                        child: Text('Activo'),
                      ),
                      DropdownMenuItem(
                        value: CustomerStatus.inactive,
                        child: Text('Inactivo'),
                      ),
                      DropdownMenuItem(
                        value: CustomerStatus.blocked,
                        child: Text('Bloqueado'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _status = value!),
                  ),
                  if (_customerType == CustomerType.credit) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Información de Crédito'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _creditLimitController,
                      decoration: const InputDecoration(
                        labelText: 'Límite de Crédito *',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (_customerType == CustomerType.credit) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido para clientes de crédito';
                          }
                          final limit = double.tryParse(value);
                          if (limit == null || limit <= 0) {
                            return 'Debe ser mayor a 0';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildSectionTitle('Notas'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notas Adicionales',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCustomer,
                      child: Text(_isEditing ? 'Actualizar Cliente' : 'Crear Cliente'),
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
}
