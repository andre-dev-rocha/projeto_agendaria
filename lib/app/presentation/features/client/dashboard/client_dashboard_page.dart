// Exemplo para client_dashboard_page.dart (faça um similar para Employee)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientDashboardPage extends StatelessWidget {
  const ClientDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel do Cliente"),
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut())],
      ),
      body: const Center(child: Text("Bem-vindo, Cliente!")),
    );
  }
}