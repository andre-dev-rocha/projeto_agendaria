// Exemplo para client_dashboard_page.dart (faça um similar para Employee)
import 'package:agendaria/app/presentation/features/employee/availability/employee_availability_page.dart';
import 'package:agendaria/app/presentation/features/employee/my_services/employee_services_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmployeeDashboardPage extends StatelessWidget {
  const EmployeeDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel do Funcionário"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "Bem-vindo(a)!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildDashboardCard(
            context,
            icon: Icons.cut, // Ou use `Icons.design_services`
            title: 'Meus Serviços',
            subtitle: 'Gerencie os serviços que você oferece',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmployeeServicesPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 10), // Espaçamento
          // --- NOVO CARD AQUI ---
          _buildDashboardCard(
            context,
            icon: Icons.calendar_today,
            title: 'Minha Disponibilidade',
            subtitle: 'Defina seus horários de atendimento',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmployeeAvailabilityPage(),
                ),
              );
            },
          ),
          // Adicione mais cards aqui para as próximas funcionalidades
          // Ex: _buildDashboardCard(context, icon: Icons.calendar_today, title: 'Minha Disponibilidade', ...),
          // Ex: _buildDashboardCard(context, icon: Icons.schedule, title: 'Meus Atendimentos', ...),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, size: 40, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
