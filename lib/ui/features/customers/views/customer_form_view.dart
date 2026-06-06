import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _creditLimitController = TextEditingController(text: '0');
  final _currentBalanceController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  CustomerType _type = CustomerType.occasional;
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

  @override
  void dispose() {
    _fullNameController.dispose();
    _identificationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _creditLimitController.dispose();
    _currentBalanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomer() async {
    setState(() => _isLoading = true);
    try {
      final customer =
          await ref.read(customerRepositoryProvider).getById(widget.customerId!);
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
          _latitudeController.text = customer.latitude?.toString() ?? '';
          _longitudeController.text = customer.longitude?.toString() ?? '';
          _creditLimitController.text = customer.creditLimit.toString();
          _currentBalanceController.text = customer.currentBalance.toString();
          _notesController.text = customer.notes ?? '';
          _type = customer.type;
          _status = customer.status;
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
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final customer = Customer(
        id: widget.customerId ?? '',
        fullName: _fullNameController.text.trim(),
        identification: _identificationController.text.trim().isEmpty
            ? null
            : _identificationController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        latitude: double.tryParse(_latitudeController.text.trim()),
        longitude: double.tryParse(_longitudeController.text.trim()),
        type: _type,
        status: _status,
        creditLimit: double.tryParse(_creditLimitController.text) ?? 0,
        currentBalance:
            double.tryParse(_currentBalanceController.text) ?? 0,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (_isEditing) {
        await ref.read(customersProvider.notifier).updateCustomer(customer);
        _showSnack('Cliente actualizado');
      } else {
        final created =
            await ref.read(customersProvider.notifier).createCustomer(customer);
        _showSnack('Cliente creado');
        if (mounted) {
          context.pop(created.id);
        }
        return;
      }

      ref.invalidate(customerByIdProvider(widget.customerId!));
      if (mounted) context.pop();
    } catch (e) {
      _showSnack('Error al guardar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Cliente' : 'Nuevo Cliente'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _save,
              tooltip: 'Guardar',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              'Información Personal',
              Icons.person,
              [
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo *',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    if (value.trim().length < 3) {
                      return 'Mínimo 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _identificationController,
                  decoration: const InputDecoration(
                    labelText: 'Cédula / NIT',
                    prefixIcon: Icon(Icons.credit_card),
                    border: OutlineInputBorder(),
                    helperText: 'Opcional, debe ser único',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                  ],
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (value.trim().length < 4) {
                        return 'Mínimo 4 caracteres';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono *',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\s\-\+]')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El teléfono es requerido';
                    }
                    if (value.trim().length < 7) {
                      return 'Mínimo 7 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final emailRegex = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      );
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Email inválido';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Dirección',
              Icons.location_on,
              [
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.home),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Latitud',
                          prefixIcon: Icon(Icons.my_location),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d\-\.]')),
                        ],
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final lat = double.tryParse(value);
                            if (lat == null || lat < -90 || lat > 90) {
                              return 'Inválida';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        decoration: const InputDecoration(
                          labelText: 'Longitud',
                          prefixIcon: Icon(Icons.my_location),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d\-\.]')),
                        ],
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final lng = double.tryParse(value);
                            if (lng == null || lng < -180 || lng > 180) {
                              return 'Inválida';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Clasificación',
              Icons.business_center,
              [
                DropdownButtonFormField<CustomerType>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Cliente',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: CustomerType.values
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(_getTypeIcon(type),
                                    size: 18, color: _getTypeColor(type)),
                                const SizedBox(width: 8),
                                Text(type.label),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _type = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CustomerStatus>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    prefixIcon: Icon(Icons.flag),
                    border: OutlineInputBorder(),
                  ),
                  items: CustomerStatus.values
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Información de Crédito',
              Icons.account_balance_wallet,
              [
                TextFormField(
                  controller: _creditLimitController,
                  decoration: const InputDecoration(
                    labelText: 'Cupo de Crédito',
                    prefixIcon: Icon(Icons.credit_card),
                    border: OutlineInputBorder(),
                    helperText: 'Límite máximo de crédito permitido',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final limit = double.tryParse(value);
                      if (limit == null || limit < 0) {
                        return 'Debe ser un número positivo';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_isEditing) ...[
                  TextFormField(
                    controller: _currentBalanceController,
                    decoration: InputDecoration(
                      labelText: 'Saldo Actual',
                      prefixIcon: const Icon(Icons.account_balance),
                      border: const OutlineInputBorder(),
                      helperText: _type == CustomerType.credit
                          ? 'Deuda actual del cliente'
                          : 'Solo se modifica al registrar pagos',
                      enabled: _type == CustomerType.credit,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                if (_type == CustomerType.credit && _isEditing)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'El saldo se actualiza automáticamente con cada pedido a crédito o pago',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Notas',
              Icons.note,
              [
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isEditing ? 'Actualizar' : 'Crear Cliente'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  MaterialColor _getTypeColor(CustomerType type) {
    switch (type) {
      case CustomerType.occasional:
        return Colors.grey;
      case CustomerType.frequent:
        return Colors.blue;
      case CustomerType.wholesale:
        return Colors.purple;
      case CustomerType.credit:
        return Colors.orange;
      case CustomerType.consignment:
        return Colors.teal;
    }
  }

  IconData _getTypeIcon(CustomerType type) {
    switch (type) {
      case CustomerType.occasional:
        return Icons.person;
      case CustomerType.frequent:
        return Icons.person_outline;
      case CustomerType.wholesale:
        return Icons.business;
      case CustomerType.credit:
        return Icons.account_balance_wallet;
      case CustomerType.consignment:
        return Icons.inventory;
    }
  }
}
