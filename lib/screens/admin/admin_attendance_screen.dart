// ignore_for_file: file_names, avoid_print

import 'package:Escolarize/models/user_model.dart';
import 'package:Escolarize/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminAttendanceScreen extends StatefulWidget {
  final UserModel adminUser;

  const AdminAttendanceScreen({super.key, required this.adminUser});

  @override
  // ignore: library_private_types_in_public_api
  _AdminAttendanceScreenState createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime selectedDate = DateTime.now();
  String? selectedTurma;
  final dateFormat = DateFormat('dd/MM/yyyy');

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    String formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('Frequência dos Alunos'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.date_range, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Text(
                  'Data: ${dateFormat.format(selectedDate)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('turmas').snapshots(),
            builder: (context, turmasSnapshot) {
              if (turmasSnapshot.hasError) {
                return Center(child: Text('Erro ao carregar turmas'));
              }

              List<String> turmas =
                  turmasSnapshot.data?.docs.map((doc) => doc.id).toList() ?? [];

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Filtrar por Turma',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.class_),
                  ),
                  value: selectedTurma,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Todas as Turmas'),
                    ),
                    ...turmas.map(
                      (turma) =>
                          DropdownMenuItem(value: turma, child: Text(turma)),
                    ),
                  ],
                  onChanged: (value) => setState(() => selectedTurma = value),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('frequencia')
                      .where(
                        'data',
                        isGreaterThanOrEqualTo: DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                        ),
                      )
                      .where(
                        'data',
                        isLessThan: DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day + 1,
                        ),
                      )
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Erro: ${snapshot.error}'); // Debug
                  return Center(child: Text('Erro ao carregar frequência'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final records = snapshot.data?.docs ?? [];

                print('Registros encontrados: ${records.length}'); // Debug

                if (records.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning, size: 48, color: Colors.orange),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum registro de frequência encontrado\npara ${dateFormat.format(selectedDate)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                // Filtrar por turma se selecionada
                final filteredRecords =
                    selectedTurma != null
                        ? records
                            .where(
                              (doc) =>
                                  (doc.data()
                                      as Map<String, dynamic>)['turma'] ==
                                  selectedTurma,
                            )
                            .toList()
                        : records;

                return ListView.builder(
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    final data =
                        filteredRecords[index].data() as Map<String, dynamic>;
                    final turma = data['turma'] as String;
                    final presencas = Map<String, bool>.from(data['presencas']);
                    final professor = data['professor'] as Map<String, dynamic>;
                    final totalAlunos = data['totalAlunos'] as int;
                    final totalPresentes = data['totalPresentes'] as int;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryBlue,
                          child: Text(
                            turma.substring(0, 1),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          'Turma $turma',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Professor: ${professor['nome']}',
                              style: TextStyle(fontSize: 14),
                            ),
                            Row(
                              children: [
                                Icon(
                                  totalPresentes == totalAlunos
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  size: 16,
                                  color:
                                      totalPresentes == totalAlunos
                                          ? Colors.green
                                          : Colors.orange,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Presentes: $totalPresentes/$totalAlunos',
                                  style: TextStyle(
                                    color:
                                        totalPresentes == totalAlunos
                                            ? Colors.green
                                            : Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        children: [
                          FutureBuilder<QuerySnapshot>(
                            future:
                                _firestore
                                    .collection('users')
                                    .where('serie', isEqualTo: turma)
                                    .where('role', isEqualTo: 'student')
                                    .get(),
                            builder: (context, studentsSnapshot) {
                              if (studentsSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              // Add error handling with detailed error message
                              if (studentsSnapshot.hasError) {
                                print(
                                  'Error in student query: ${studentsSnapshot.error}',
                                );
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Erro ao carregar alunos:\n${studentsSnapshot.error}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final students =
                                  studentsSnapshot.data?.docs ?? [];

                              // Debug print to check data
                              print(
                                'Found ${students.length} students for turma $turma',
                              );

                              return Container(
                                color: Colors.grey[50],
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(height: 1),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.people,
                                            color: AppColors.primaryBlue,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Lista de Alunos (${students.length})',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (students.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: Text(
                                            'Nenhum aluno encontrado nesta turma',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      ...students.map((student) {
                                        // Safely get student data with null checks
                                        final studentData =
                                            student.data()
                                                as Map<String, dynamic>? ??
                                            {};
                                        final String studentName =
                                            studentData['name'] as String? ??
                                            'Sem nome';
                                        final bool isPresent =
                                            presencas[student.id] ?? false;

                                        // Debug print for each student
                                        print(
                                          'Processing student: $studentName (ID: ${student.id})',
                                        );

                                        return ListTile(
                                          dense: true,
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                isPresent
                                                    ? Colors.green.shade100
                                                    : Colors.red.shade100,
                                            child: Text(
                                              studentName.isNotEmpty
                                                  ? studentName[0].toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                color:
                                                    isPresent
                                                        ? Colors.green
                                                        : Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            studentName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Matrícula: ${student.id}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isPresent
                                                      ? Colors.green.shade50
                                                      : Colors.red.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color:
                                                    isPresent
                                                        ? Colors.green
                                                        : Colors.red,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              isPresent
                                                  ? 'Presente'
                                                  : 'Ausente',
                                              style: TextStyle(
                                                color:
                                                    isPresent
                                                        ? Colors.green
                                                        : Colors.red,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
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
