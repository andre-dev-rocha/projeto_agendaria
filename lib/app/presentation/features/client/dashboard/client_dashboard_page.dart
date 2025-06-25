// lib/app/presentation/features/client/dashboard/client_dashboard_page.dart
import 'package:agendaria/app/presentation/features/client/my_appointments/client_appointments_page.dart';
import 'package:agendaria/app/presentation/features/client/chatbot/chatbot_page.dart'; // Importe a página do chatbot
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClientDashboardPage extends StatelessWidget {
  const ClientDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel do Cliente"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      // Transforma o corpo em uma lista de opções
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "Bem-vindo(a) de volta!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // --- CARD DE ENTRADA PARA O CHATBOT ---
          _buildDashboardCard(
            context,
            icon: Icons.smart_toy_outlined, // Ícone de robô/assistente
            title: 'Agendar com o Assistente',
            subtitle: 'Converse com nossa IA para marcar seu horário',
            onTap: () {
              // Navega para a página do Chatbot
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotPage()),
              );
            },
          ),

          // --- FIM DO CARD ---
          const SizedBox(height: 10),

          // Placeholder para a próxima funcionalidade
          _buildDashboardCard(
            context,
            icon: Icons.calendar_month_outlined,
            title: 'Meus Agendamentos',
            subtitle: 'Visualize seus horários marcados',
            onTap: () {
              // TODO: Navegar para a página de "Meus Agendamentos" do cliente
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClientAppointmentsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para criar os cards do painel (mesmo estilo do painel do funcionário)
  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 15,
        ),
        leading: Icon(icon, size: 40, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
