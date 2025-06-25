// lib/app/data/models/appointment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String clientId;
  final String employeeId;
  final String serviceId;
  final String serviceName;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final double price;
  final String status;

  Appointment({
    required this.id,
    required this.clientId,
    required this.employeeId,
    required this.serviceId,
    required this.serviceName,
    required this.startDateTime,
    required this.endDateTime,
    required this.price,
    required this.status,
  });

  // Converte um DocumentSnapshot do Firestore em um objeto Appointment
  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      employeeId: data['employeeId'] ?? '',
      serviceId: data['serviceId'] ?? '',
      serviceName: data['serviceName'] ?? '',
      // A conversão do Timestamp para DateTime é crucial
      startDateTime: (data['startDateTime'] as Timestamp).toDate(),
      endDateTime: (data['endDateTime'] as Timestamp).toDate(),
      price: (data['price'] as num).toDouble(),
      status: data['status'] ?? 'scheduled',
    );
  }

  // Converte um objeto Appointment em um Map para o Firestore
  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'employeeId': employeeId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'price': price,
      'status': status,
    };
  }
}