// lib/app/presentation/features/employee/my_appointments/employee_appointments_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/appointment_model.dart';

class EmployeeAppointmentsPage extends StatefulWidget {
  const EmployeeAppointmentsPage({Key? key}) : super(key: key);

  @override
  State<EmployeeAppointmentsPage> createState() =>
      _EmployeeAppointmentsPageState();
}

class _EmployeeAppointmentsPageState extends State<EmployeeAppointmentsPage> {
  final String currentEmployeeId = FirebaseAuth.instance.currentUser!.uid;

  // Guarda a data selecionada pelo usuário. Inicia com a data de hoje.
  DateTime _selectedDate = DateTime.now();

  Future<String> _getUserName(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        // Certifique-se de que o campo no seu Firestore se chama 'name'
        return (userDoc.data() as Map<String, dynamic>)['name'] ??
            'Cliente Desconhecido';
      }
    } catch (e) {
      print('Erro ao buscar nome do cliente: $e');
    }
    // Retorna um trecho do ID se o nome não for encontrado por algum motivo
    return 'ID: ${userId.substring(0, 6)}...';
  }

  void _updateAppointmentStatus(String appointmentId, String newStatus) {
    FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update({'status': newStatus})
        .then(
          (_) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Agendamento atualizado para "$newStatus"!'),
              backgroundColor: Colors.green,
            ),
          ),
        )
        .catchError(
          (error) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar status: $error'),
              backgroundColor: Colors.red,
            ),
          ),
        );
  }

  // Função para mostrar o seletor de data (DatePicker)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'), // Para traduzir o DatePicker
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked; // Atualiza o estado com a nova data
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define o início e o fim do dia para a consulta no Firestore
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Atendimentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Filtrar por data',
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mostra a data que está sendo filtrada
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Mostrando atendimentos para: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('employeeId', isEqualTo: currentEmployeeId)
                  // Filtra os agendamentos que estão dentro do dia selecionado
                  .where(
                    'startDateTime',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
                  )
                  .where(
                    'startDateTime',
                    isLessThan: Timestamp.fromDate(endOfDay),
                  )
                  .orderBy('startDateTime') // Ordena por hora
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  // Este erro pode acontecer se o índice do Firestore não existir
                  print(snapshot.error); // Ajuda a depurar
                  return const Center(
                    child: Text(
                      'Ocorreu um erro. Verifique os índices do Firestore.',
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum atendimento agendado para esta data.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final appointments = snapshot.data!.docs
                    .map((doc) => Appointment.fromFirestore(doc))
                    .toList();

                return ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    final formattedTime = DateFormat(
                      'HH:mm',
                    ).format(appointment.startDateTime);
                    // Define a cor e o ícone com base no status
                    IconData statusIcon;
                    Color statusColor;
                    switch (appointment.status) {
                      case 'completed':
                        statusIcon = Icons.check_circle;
                        statusColor = Colors.green;
                        break;
                      case 'canceled':
                        statusIcon = Icons.cancel;
                        statusColor = Colors.red;
                        break;
                      default: // 'scheduled'
                        statusIcon = Icons.schedule;
                        statusColor = Colors.blue;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor,
                          child: Icon(statusIcon, color: Colors.white),
                        ),
                        title: Text(
                          appointment.serviceName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: FutureBuilder<String>(
                          // Usamos FutureBuilder para buscar o nome do cliente
                          future: _getUserName(
                            appointment.clientId,
                          ), // Reutilizamos a função que já temos!
                          builder: (context, nameSnapshot) {
                            return Text(
                              nameSnapshot.data ?? 'Carregando cliente...',
                            );
                          },
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            _updateAppointmentStatus(appointment.id, value);
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                                // Mostra a opção apenas se o status permitir
                                if (appointment.status == 'scheduled')
                                  const PopupMenuItem<String>(
                                    value: 'completed',
                                    child: Text('Marcar como Concluído'),
                                  ),
                                if (appointment.status != 'canceled')
                                  const PopupMenuItem<String>(
                                    value: 'canceled',
                                    child: Text('Cancelar Agendamento'),
                                  ),
                              ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
