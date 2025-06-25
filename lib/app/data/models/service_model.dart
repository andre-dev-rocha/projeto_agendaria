// lib/app/data/models/service_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String name;
  final double price;
  final int durationMinutes; // Duração em minutos
  final String employeeId;

  Service({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
    required this.employeeId,
  });

  // Converte um DocumentSnapshot do Firestore em um objeto Service
  factory Service.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Service(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] as num).toDouble(),
      durationMinutes: data['durationMinutes'] ?? 0,
      employeeId: data['employeeId'] ?? '',
    );
  }

  // Converte um objeto Service em um Map para o Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'durationMinutes': durationMinutes,
      'employeeId': employeeId,
    };
  }
}