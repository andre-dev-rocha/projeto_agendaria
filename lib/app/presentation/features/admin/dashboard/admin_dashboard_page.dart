// lib/app/presentation/features/admin/dashboard/admin_dashboard_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para buscar o desempenho dos funcionários no mês atual
  Future<Map<String, int>> _fetchEmployeePerformance() async {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 1);

    QuerySnapshot snapshot = await _firestore
        .collection('appointments')
        .where('startDateTime', isGreaterThanOrEqualTo: startOfMonth)
        .where('startDateTime', isLessThan: endOfMonth)
        .get();

    Map<String, int> employeeCounts = {};
    for (var doc in snapshot.docs) {
      String employeeId = doc['employeeId'];
      employeeCounts[employeeId] = (employeeCounts[employeeId] ?? 0) + 1;
    }
    return employeeCounts;
  }

  // Método para buscar os serviços mais populares do mês
  Future<Map<String, int>> _fetchTopServices() async {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 1);

    QuerySnapshot snapshot = await _firestore
        .collection('appointments')
        .where('startDateTime', isGreaterThanOrEqualTo: startOfMonth)
        .where('startDateTime', isLessThan: endOfMonth)
        .get();

    Map<String, int> serviceCounts = {};
    for (var doc in snapshot.docs) {
      String serviceName = doc['serviceName'];
      serviceCounts[serviceName] = (serviceCounts[serviceName] ?? 0) + 1;
    }
    return serviceCounts;
  }

  // Função auxiliar para buscar o nome de um usuário pelo ID
  // Isso evita mostrar apenas o ID na tela
  Future<String> _getUserName(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        return userDoc['name'] ?? 'Usuário Desconhecido';
      }
    } catch (e) {
      print('Erro ao buscar nome do usuário: $e');
    }
    return 'ID: ${userId.substring(0, 6)}...';
  }

  // Método para buscar estatísticas do dia (atendimentos e faturamento)
  Future<Map<String, dynamic>> _fetchTodayStats() async {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    QuerySnapshot snapshot = await _firestore
        .collection('appointments')
        .where('startDateTime', isGreaterThanOrEqualTo: startOfDay)
        .where('startDateTime', isLessThan: endOfDay)
        .get();

    int appointmentCount = snapshot.docs.length;
    double totalRevenue = 0;
    for (var doc in snapshot.docs) {
      // Supondo que você queira somar apenas os agendamentos com status "completed"
      if (doc['status'] == 'completed') {
        totalRevenue += (doc['price'] as num).toDouble();
      }
    }
    return {'count': appointmentCount, 'revenue': totalRevenue};
  }

  // Método para buscar as estatísticas do mês
  Future<Map<String, dynamic>> _fetchMonthStats() async {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 1);

    QuerySnapshot snapshot = await _firestore
        .collection('appointments')
        .where('startDateTime', isGreaterThanOrEqualTo: startOfMonth)
        .where('startDateTime', isLessThan: endOfMonth)
        .get();

    int appointmentCount = snapshot.docs.length;
    double totalRevenue = 0;
    for (var doc in snapshot.docs) {
      if (doc['status'] == 'completed') {
        totalRevenue += (doc['price'] as num).toDouble();
      }
    }
    return {'count': appointmentCount, 'revenue': totalRevenue};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel do Administrador"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Permite que você puxe para atualizar os dados
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'Resumo do Negócio',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),

            // Cards para as estatísticas do dia
            FutureBuilder<Map<String, dynamic>>(
              future: _fetchTodayStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError)
                  return const Text('Erro ao carregar dados do dia.');

                final stats = snapshot.data ?? {'count': 0, 'revenue': 0.0};
                return Row(
                  children: [
                    _buildStatCard(
                      'Atendimentos Hoje',
                      stats['count'].toString(),
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Receita Hoje',
                      'R\$ ${stats['revenue'].toStringAsFixed(2)}',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Cards para as estatísticas do mês
            FutureBuilder<Map<String, dynamic>>(
              future: _fetchMonthStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError)
                  return const Text('Erro ao carregar dados do mês.');

                final stats = snapshot.data ?? {'count': 0, 'revenue': 0.0};
                final currentMonth = DateFormat.MMMM(
                  'pt_BR',
                ).format(DateTime.now());

                return Row(
                  children: [
                    _buildStatCard(
                      'Atendimentos em $currentMonth',
                      stats['count'].toString(),
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Receita em $currentMonth',
                      'R\$ ${stats['revenue'].toStringAsFixed(2)}',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Desempenho da Equipe (este mês)',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            FutureBuilder<Map<String, int>>(
              future: _fetchEmployeePerformance(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError)
                  return const Text('Erro ao carregar desempenho.');
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Card(
                    child: ListTile(
                      title: Text('Nenhum atendimento este mês.'),
                    ),
                  );
                }

                // Ordena o mapa para mostrar quem tem mais atendimentos primeiro
                final sortedEntries = snapshot.data!.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return Card(
                  child: Column(
                    children: sortedEntries.map((entry) {
                      // Usamos um FutureBuilder aqui dentro para buscar o nome de cada funcionário
                      return FutureBuilder<String>(
                        future: _getUserName(entry.key),
                        builder: (context, nameSnapshot) {
                          String displayName =
                              nameSnapshot.data ?? 'Carregando...';
                          return ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(displayName),
                            trailing: Text(
                              '${entry.value} atendimentos',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // --- NOVA SEÇÃO: SERVIÇOS MAIS POPULARES ---
            Text(
              'Serviços Populares (este mês)',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            FutureBuilder<Map<String, int>>(
              future: _fetchTopServices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError)
                  return const Text('Erro ao carregar serviços.');
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Card(
                    child: ListTile(
                      title: Text('Nenhum serviço realizado este mês.'),
                    ),
                  );
                }

                final sortedEntries = snapshot.data!.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return Card(
                  child: Column(
                    children: sortedEntries.map((entry) {
                      return ListTile(
                        leading: const Icon(
                          Icons.cut,
                        ), // Ícone genérico de serviço
                        title: Text(entry.key), // Nome do serviço
                        trailing: Text(
                          '${entry.value} vezes',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para construir os cards de estatísticas
  Widget _buildStatCard(String title, String value) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
