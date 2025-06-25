// lib/app/presentation/features/employee/availability/employee_availability_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployeeAvailabilityPage extends StatefulWidget {
  const EmployeeAvailabilityPage({Key? key}) : super(key: key);

  @override
  State<EmployeeAvailabilityPage> createState() => _EmployeeAvailabilityPageState();
}

class _EmployeeAvailabilityPageState extends State<EmployeeAvailabilityPage> {
  final String currentEmployeeId = FirebaseAuth.instance.currentUser!.uid;
  late DocumentReference _availabilityRef;

  // Mapa para guardar o estado da UI. A chave é o dia da semana.
  Map<String, dynamic> _schedule = {};
  bool _isLoading = true;

  final List<String> _weekdays = [
    'segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado', 'domingo'
  ];
  final Map<String, String> _weekdaysPortuguese = {
    'segunda': 'Segunda-feira', 'terca': 'Terça-feira', 'quarta': 'Quarta-feira',
    'quinta': 'Quinta-feira', 'sexta': 'Sexta-feira', 'sabado': 'Sábado', 'domingo': 'Domingo'
  };

  @override
  void initState() {
    super.initState();
    _availabilityRef = FirebaseFirestore.instance.collection('availabilities').doc(currentEmployeeId);
    _loadSchedule();
  }

  // Carrega o horário do Firestore ou cria um padrão
  Future<void> _loadSchedule() async {
    final doc = await _availabilityRef.get();
    if (doc.exists) {
      setState(() {
        _schedule = doc.data() as Map<String, dynamic>;
        _isLoading = false;
      });
    } else {
      // Se não houver horário salvo, cria um padrão (tudo desabilitado)
      setState(() {
        _schedule = {
          for (var day in _weekdays)
            day: {'isAvailable': false, 'startTime': '08:00', 'endTime': '18:00'}
        };
        _isLoading = false;
      });
    }
  }

  // Salva o horário no Firestore
  Future<void> _saveSchedule() async {
    setState(() => _isLoading = true);
    await _availabilityRef.set(_schedule);
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horários salvos com sucesso!'), backgroundColor: Colors.green),
      );
    }
  }

  // Mostra o seletor de tempo
  Future<void> _selectTime(BuildContext context, String day, String timeType) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _schedule[day][timeType] = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha Disponibilidade')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                ..._weekdays.map((day) => _buildDayTile(day)).toList(),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveSchedule,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: const Text('Salvar Horários'),
                ),
              ],
            ),
    );
  }

  // Widget para construir cada linha de dia da semana
  Widget _buildDayTile(String day) {
    final dayData = _schedule[day] as Map<String, dynamic>;
    final bool isAvailable = dayData['isAvailable'];
    final String startTime = dayData['startTime'];
    final String endTime = dayData['endTime'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_weekdaysPortuguese[day]!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Switch(
                  value: isAvailable,
                  onChanged: (value) {
                    setState(() {
                      _schedule[day]['isAvailable'] = value;
                    });
                  },
                ),
              ],
            ),
            if (isAvailable)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [const Text('Início'), TextButton(onPressed: () => _selectTime(context, day, 'startTime'), child: Text(startTime))]),
                  Column(children: [const Text('Fim'), TextButton(onPressed: () => _selectTime(context, day, 'endTime'), child: Text(endTime))]),
                ],
              ),
          ],
        ),
      ),
    );
  }
}