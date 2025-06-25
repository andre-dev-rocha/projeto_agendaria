// lib/app/presentation/features/employee/my_services/employee_services_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../data/models/service_model.dart'; // Importe nosso modelo

class EmployeeServicesPage extends StatefulWidget {
  const EmployeeServicesPage({Key? key}) : super(key: key);

  @override
  State<EmployeeServicesPage> createState() => _EmployeeServicesPageState();
}

class _EmployeeServicesPageState extends State<EmployeeServicesPage> {
  final String currentEmployeeId = FirebaseAuth.instance.currentUser!.uid;
  final CollectionReference servicesCollection = FirebaseFirestore.instance
      .collection('services');

  // Método para mostrar o diálogo de adicionar/editar serviço
  void _showServiceDialog({Service? service}) {
    final _nameController = TextEditingController(text: service?.name);
    final _priceController = TextEditingController(
      text: service?.price.toString(),
    );
    final _durationController = TextEditingController(
      text: service?.durationMinutes.toString(),
    );
    final isEditing = service != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Serviço' : 'Adicionar Serviço'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome do Serviço'),
              ),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Preço (R\$)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duração (minutos)',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final newService = {
                  'name': _nameController.text.trim(),
                  'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
                  'durationMinutes':
                      int.tryParse(_durationController.text.trim()) ?? 0,
                  'employeeId': currentEmployeeId,
                };

                if (isEditing) {
                  servicesCollection.doc(service.id).update(newService);
                } else {
                  servicesCollection.add(newService);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String serviceId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmar Exclusão"),
          content: const Text(
            "Tem certeza de que deseja apagar este serviço? Esta ação não pode ser desfeita.",
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Apagar"),
              onPressed: () {
                // Executa a exclusão no Firestore
                servicesCollection.doc(serviceId).delete();
                Navigator.of(context).pop(); // Fecha o diálogo
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Serviços')),
      body: StreamBuilder<QuerySnapshot>(
        stream: servicesCollection
            .where('employeeId', isEqualTo: currentEmployeeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Você ainda não cadastrou nenhum serviço.'),
            );
          }

          // Converte os documentos em uma lista de Widgets
          final services = snapshot.data!.docs
              .map((doc) => Service.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
    final service = services[index];
    return ListTile(
      title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('Duração: ${service.durationMinutes} min'),

      // --- MODIFICAÇÃO COMEÇA AQUI ---
      trailing: Row(
        mainAxisSize: MainAxisSize.min, // Importante para a Row caber no ListTile
        children: [
          Text(
            'R\$ ${service.price.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.green, fontSize: 16),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red[400]),
            tooltip: 'Apagar Serviço',
            onPressed: () {
              // Chama a função de confirmação que criamos
              _showDeleteConfirmationDialog(service.id);
            },
          ),
        ],
      ),
                onTap: () => _showServiceDialog(service: service),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceDialog(),
        tooltip: 'Adicionar Serviço',
        child: const Icon(Icons.add),
      ),
    );
  }
}
