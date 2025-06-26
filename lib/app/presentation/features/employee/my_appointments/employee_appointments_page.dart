// lib/app/presentation/features/employee/my_appointments/employee_appointments_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/appointment_model.dart';

class EmployeeAppointmentsPage extends StatefulWidget {
  const EmployeeAppointmentsPage({Key? key}) : super(key: key);

  @override
  State<EmployeeAppointmentsPage> createState() => _EmployeeAppointmentsPageState();
}

class _EmployeeAppointmentsPageState extends State<EmployeeAppointmentsPage> {
  final String currentEmployeeId = FirebaseAuth.instance.currentUser!.uid;

  // Guarda a data selecionada pelo usuário. Inicia com a data de hoje.
  DateTime _selectedDate = DateTime.now();

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
    final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
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
                  .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                  .where('startDateTime', isLessThan: Timestamp.fromDate(endOfDay))
                  .orderBy('startDateTime') // Ordena por hora
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  // Este erro pode acontecer se o índice do Firestore não existir
                  print(snapshot.error); // Ajuda a depurar
                  return const Center(child: Text('Ocorreu um erro. Verifique os índices do Firestore.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum atendimento agendado para esta data.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final appointments = snapshot.data!.docs.map((doc) => Appointment.fromFirestore(doc)).toList();

                return ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    final formattedTime = DateFormat('HH:mm').format(appointment.startDateTime);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(formattedTime.substring(0,2)), // Mostra a hora
                        ),
                        title: Text(appointment.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        // TODO: Precisamos do nome do cliente aqui. Isso exigirá outra consulta.
                        subtitle: Text('Cliente ID: ${appointment.clientId}'), 
                        trailing: Text(
                          'R\$ ${appointment.price.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
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