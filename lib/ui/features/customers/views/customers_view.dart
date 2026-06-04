import 'package:flutter/material.dart';

class CustomersView extends StatelessWidget {
  const CustomersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
      ),
      body: const Center(
        child: Text('Clientes - En desarrollo'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
