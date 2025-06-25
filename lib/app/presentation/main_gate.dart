// lib/app/presentation/main_gate.dart
import 'package:agendaria/app/presentation/features/admin/dashboard/admin_dashboard_page.dart';
import 'package:agendaria/app/presentation/features/employee/dashboard/employee_dashboard_page.dart';
import 'package:agendaria/app/presentation/features/client/dashboard/client_dashboard_page.dart';
import 'package:agendaria/app/presentation/features/auth/auth_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainGate extends StatelessWidget {
  const MainGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Ouve as mudanças de auth!
      builder: (context, authSnapshot) {
        // 1. Se o authSnapshot ainda está carregando, mostre um indicador
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Se o usuário ESTÁ logado, mostre a HomePage
        if (authSnapshot.hasData) {
          // Tela principal temporária após o login
          // No futuro, aqui você vai verificar a 'role' do usuário e direcioná-lo
          return RoleBasedRedirect(userId: authSnapshot.data!.uid);
        }

        // 3. Se o usuário NÃO está logado, mostre a página de autenticação
        return const AuthPage();
      },
    );
  }
}

class RoleBasedRedirect extends StatelessWidget {
  final String userId;
  const RoleBasedRedirect({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      // Busca o documento do usuário na coleção 'users'
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (userSnapshot.hasError) {
          return const Scaffold(body: Center(child: Text("Ocorreu um erro!")));
        }

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          // Pega a 'role' do documento do usuário
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final String role = userData['role'];

          // Redireciona com base na 'role'
          switch (role) {
            case 'admin':
              return const AdminDashboardPage();
            case 'employee':
              return const EmployeeDashboardPage(); // Mude para o dashboard de funcionário
            case 'client':
              return const ClientDashboardPage(); // Mude para o dashboard de cliente
            default:
              // Se a 'role' for desconhecida, volta para o login
              return const AuthPage();
          }
        }

        // Se o documento do usuário não existir por algum motivo, desloga
        FirebaseAuth.instance.signOut();
        return const AuthPage();
      },
    );
  }
}