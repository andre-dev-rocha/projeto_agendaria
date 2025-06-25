// lib/app/presentation/features/client/my_appointments/client_appointments_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Pacote para formatação de datas
import '../../../../data/models/appointment_model.dart';

class ClientAppointmentsPage extends StatefulWidget {
  const ClientAppointmentsPage({Key? key}) : super(key: key);

  @override
  State<ClientAppointmentsPage> createState() => _ClientAppointmentsPageState();
}

class _ClientAppointmentsPageState extends State<ClientAppointmentsPage> {
  final String currentClientId = FirebaseAuth.instance.currentUser!.uid;
  final CollectionReference appointmentsCollection = FirebaseFirestore.instance.collection('appointments');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Agendamentos'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Filtra os agendamentos pelo ID do cliente logado e ordena por data
        stream: appointmentsCollection
            .where('clientId', isEqualTo: currentClientId)
            .orderBy('startDateTime', descending: true) // Mais recentes primeiro
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Ocorreu um erro ao carregar os agendamentos.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Você ainda não possui agendamentos.\nTente agendar com nosso assistente!',
                textAlign: TextAlign.center,
              ),
            );
          }

          // Converte os documentos em uma lista de objetos Appointment
          final appointments = snapshot.data!.docs.map((doc) => Appointment.fromFirestore(doc)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              // Usando o pacote intl para formatar a data e hora de forma amigável
              final String formattedDate = DateFormat('dd/MM/yyyy', 'pt_BR').format(appointment.startDateTime);
              final String formattedTime = DateFormat('HH:mm', 'pt_BR').format(appointment.startDateTime);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(appointment.serviceName[0]), // Primeira letra do serviço
                  ),
                  title: Text(appointment.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('$formattedDate às $formattedTime'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'R\$ ${appointment.price.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                      // TODO: Adicionar um status visual (ex: "Confirmado", "Cancelado")
                      Text(
                        appointment.status,
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}