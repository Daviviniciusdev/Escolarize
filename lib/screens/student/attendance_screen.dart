// ignore_for_file: library_private_types_in_public_api, sort_child_properties_last, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Escolarize/utils/app_colors.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  final String teacherId;
  final String? teacherName;

  const AttendanceScreen({
    super.key,
    required this.teacherId,
    this.teacherName,
  });

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime selectedDate = DateTime.now();
  String? selectedTurma;
  Map<String, bool> attendance = {};
  String? _teacherName;

  @override
  void initState() {
    super.initState();
    _loadTeacherName();
  }

  Future<void> _loadTeacherName() async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(widget.teacherId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _teacherName = data['nome'] ?? data['name'] ?? 'Professor';
        });
      }
    } catch (e) {
      print('Erro ao carregar nome do professor: $e');
    }
  }

  void _mostrarHistoricoFrequencia() {
    if (selectedTurma == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Selecione uma turma primeiro')));
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Histórico de Frequência - Turma $selectedTurma',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<QuerySnapshot>(
                      future:
                          _firestore
                              .collection('frequencia')
                              .where('turma', isEqualTo: selectedTurma)
                              .get(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Erro ao carregar histórico: ${snapshot.error}',
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final registros = snapshot.data!.docs;
                        if (registros.isEmpty) {
                          return Center(
                            child: Text(
                              'Nenhum registro de frequência encontrado',
                            ),
                          );
                        }

                        // Ordenar por data (mais recente primeiro)
                        registros.sort((a, b) {
                          final dateA =
                              (a.data() as Map<String, dynamic>)['data']
                                  as Timestamp;
                          final dateB =
                              (b.data() as Map<String, dynamic>)['data']
                                  as Timestamp;
                          return dateB.compareTo(dateA);
                        });

                        return ListView.builder(
                          itemCount: registros.length,
                          itemBuilder: (context, index) {
                            final registro =
                                registros[index].data() as Map<String, dynamic>;
                            final data =
                                (registro['data'] as Timestamp).toDate();
                            final presencas = Map<String, bool>.from(
                              registro['presencas'] ?? {},
                            );
                            final totalPresentes =
                                presencas.values.where((p) => p).length;
                            final totalAlunos = registro['totalAlunos'] ?? 0;

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                title: Text(
                                  DateFormat('dd/MM/yyyy').format(data),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Presentes: $totalPresentes/$totalAlunos',
                                  style: TextStyle(
                                    color:
                                        totalPresentes == totalAlunos
                                            ? Colors.green
                                            : Colors.orange,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.visibility),
                                  onPressed:
                                      () =>
                                          _mostrarDetalhesFrequencia(registro),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Fechar'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _mostrarDetalhesFrequencia(Map<String, dynamic> registro) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.6,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Detalhes da Frequência',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat(
                      'dd/MM/yyyy',
                    ).format((registro['data'] as Timestamp).toDate()),
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<DocumentSnapshot>(
                      future:
                          _firestore
                              .collection('turmas')
                              .doc(selectedTurma)
                              .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final turmaData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final alunos = List<Map<String, dynamic>>.from(
                          turmaData['alunos'] ?? [],
                        );
                        final presencas = Map<String, bool>.from(
                          registro['presencas'] ?? {},
                        );

                        final alunosPresentes =
                            alunos
                                .where((a) => presencas[a['uid']] ?? false)
                                .toList();
                        final alunosAusentes =
                            alunos
                                .where((a) => !(presencas[a['uid']] ?? false))
                                .toList();

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (alunosPresentes.isNotEmpty) ...[
                                _buildPresencaHeader(
                                  'Presentes',
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                                ...alunosPresentes.map(
                                  (a) => _buildAlunoTile(a, true),
                                ),
                              ],
                              if (alunosAusentes.isNotEmpty) ...[
                                SizedBox(height: 16),
                                _buildPresencaHeader(
                                  'Ausentes',
                                  Icons.cancel,
                                  Colors.red,
                                ),
                                ...alunosAusentes.map(
                                  (a) => _buildAlunoTile(a, false),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Fechar'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildPresencaHeader(String titulo, IconData icone, Color cor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icone, color: cor),
          SizedBox(width: 8),
          Text(
            titulo,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAlunoTile(Map<String, dynamic> aluno, bool presente) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: presente ? Colors.green[100] : Colors.red[100],
        child: Icon(
          presente ? Icons.check : Icons.close,
          color: presente ? Colors.green : Colors.red,
        ),
      ),
      title: Text(aluno['nome'] ?? 'Nome não disponível'),
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Frequência'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => _mostrarHistoricoFrequencia(),
            tooltip: 'Histórico de Frequência',
          ),
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Data selecionada
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.event, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy').format(selectedDate),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Lista de turmas
          StreamBuilder<DocumentSnapshot>(
            stream:
                _firestore
                    .collection('teachers')
                    .doc(widget.teacherId)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Erro ao carregar turmas'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text('Professor não encontrado'));
              }

              Map<String, dynamic> teacherData =
                  snapshot.data!.data() as Map<String, dynamic>;
              List<String> turmas = List<String>.from(
                teacherData['turmas'] ?? [],
              );

              if (turmas.isEmpty) {
                return Center(child: Text('Nenhuma turma encontrada'));
              }

              selectedTurma ??= turmas.first;

              return Expanded(
                child: Column(
                  children: [
                    // Seletor de turma
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<String>(
                        value: selectedTurma,
                        decoration: InputDecoration(
                          labelText: 'Selecione a Turma',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            turmas.map((turma) {
                              return DropdownMenuItem(
                                value: turma,
                                child: Text('Turma $turma'),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTurma = value;
                            attendance
                                .clear(); // Limpar frequência ao mudar turma
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    // Lista de alunos
                    Expanded(child: _buildAttendanceList()),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _salvarFrequencia,
        child: Icon(Icons.save),
        tooltip: 'Salvar Frequência',
      ),
    );
  }

  Widget _buildAttendanceList() {
    if (selectedTurma == null) return SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('turmas').doc(selectedTurma).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar alunos'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('Turma não encontrada'));
        }

        List<dynamic> alunos = List.from(snapshot.data!.get('alunos') ?? []);

        if (alunos.isEmpty) {
          return Center(child: Text('Nenhum aluno matriculado'));
        }

        return FutureBuilder<DocumentSnapshot>(
          future:
              _firestore
                  .collection('frequencia')
                  .doc(
                    '${selectedTurma}_${DateFormat('dd_MM_yyyy').format(selectedDate)}',
                  )
                  .get(),
          builder: (context, frequenciaSnapshot) {
            if (!frequenciaSnapshot.hasData ||
                !frequenciaSnapshot.data!.exists) {
              // Se não existe frequência salva, inicializar todos como presentes
              for (var aluno in alunos) {
                if (!attendance.containsKey(aluno['uid'])) {
                  attendance[aluno['uid']] = true;
                }
              }
            } else {
              // Carregar frequência existente
              Map<String, dynamic> frequenciaData =
                  frequenciaSnapshot.data!.data() as Map<String, dynamic>;
              Map<String, bool> savedAttendance = Map<String, bool>.from(
                frequenciaData['presencas'] ?? {},
              );

              // Atualizar attendance com os valores salvos
              for (var aluno in alunos) {
                String alunoId = aluno['uid'];
                attendance[alunoId] = savedAttendance[alunoId] ?? true;
              }

              // Garantir que novos alunos tenham um valor padrão
              for (var aluno in alunos) {
                if (!attendance.containsKey(aluno['uid'])) {
                  attendance[aluno['uid']] = true;
                }
              }
            }
            return ListView.builder(
              itemCount: alunos.length,
              itemBuilder: (context, index) {
                final aluno = alunos[index];
                final String alunoId = aluno['uid'];
                final String nome = aluno['nome'] ?? 'Nome não disponível';
                final String email = aluno['email'] ?? 'Email não disponível';

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: CheckboxListTile(
                    title: Text(nome),
                    subtitle: Text(email),
                    value: attendance[alunoId], // Remove the ?? true
                    onChanged: (bool? value) {
                      if (value != null) {
                        // Only update if value is not null
                        setState(() {
                          attendance[alunoId] = value;
                          print(
                            'Alterando presença: Aluno=$nome, ID=$alunoId, Presente=$value',
                          ); // Debug
                        });
                      }
                    },
                    secondary: CircleAvatar(
                      backgroundColor: AppColors.primaryBlue,
                      child: Text(
                        nome[0].toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

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
        attendance.clear(); // Limpar frequência ao mudar data
      });
    }
  }

  Future<void> _salvarFrequencia() async {
    try {
      if (selectedTurma == null) {
        throw 'Selecione uma turma';
      }

      final String docId =
          '${selectedTurma}_${DateFormat('dd_MM_yyyy').format(selectedDate)}';

      // Primeiro buscar os alunos da turma
      DocumentSnapshot turmaDoc =
          await _firestore.collection('turmas').doc(selectedTurma).get();
      if (!turmaDoc.exists) {
        throw 'Turma não encontrada';
      }

      List<dynamic> alunos = List.from(turmaDoc.get('alunos') ?? []);

      // Garantir que todos os alunos tenham um status de presença
      Map<String, bool> presencasAtualizadas = {};
      for (var aluno in alunos) {
        String alunoId = aluno['uid'];
        presencasAtualizadas[alunoId] = attendance[alunoId] ?? true;
      }

      print('Salvando frequência: $presencasAtualizadas'); // Debug

      // Salvar com as presenças atualizadas
      await _firestore.collection('frequencia').doc(docId).set({
        'turma': selectedTurma,
        'data': Timestamp.fromDate(selectedDate),
        'professor': {
          'id': widget.teacherId,
          'nome': _teacherName ?? 'Professor',
        },
        'presencas': presencasAtualizadas,
        'ultimaAtualizacao': FieldValue.serverTimestamp(),
        'totalAlunos': alunos.length,
        'totalPresentes':
            presencasAtualizadas.values.where((present) => present).length,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Frequência salva com sucesso!')));
    } catch (e) {
      print('Erro ao salvar frequência: $e'); // Debug
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar frequência: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
