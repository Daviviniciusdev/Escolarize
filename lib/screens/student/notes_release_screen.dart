// ignore_for_file: use_super_parameters, library_private_types_in_public_api, avoid_print, unnecessary_to_list_in_spreads, unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Escolarize/utils/app_colors.dart';

class LancamentoNotasScreen extends StatelessWidget {
  final String teacherId;
  final String teacherName;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LancamentoNotasScreen({
    Key? key,
    required this.teacherId,
    required this.teacherName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryBlue, Colors.white],
            stops: [0.0, 0.3],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Lançamento de Notas',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryBlue,
                        AppColors.primaryBlue.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.grade,
                          size: 64,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        SizedBox(height: 8),
                        Text(
                          teacherName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: StreamBuilder<DocumentSnapshot>(
                stream:
                    _firestore
                        .collection('teachers')
                        .doc(teacherId)
                        .snapshots(),
                builder: (context, teacherSnapshot) {
                  if (teacherSnapshot.hasError) {
                    return _buildErrorState('Erro ao carregar dados');
                  }

                  if (teacherSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  final teacherData =
                      teacherSnapshot.data?.data() as Map<String, dynamic>?;
                  final turmas = List<String>.from(
                    teacherData?['turmas'] ?? [],
                  );
                  final materias = List<String>.from(
                    teacherData?['materias'] ?? [],
                  );

                  if (turmas.isEmpty || materias.isEmpty) {
                    return _buildEmptyState(context, turmas.isEmpty);
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream:
                        _firestore
                            .collection('turmas')
                            .where('nome', whereIn: turmas)
                            .snapshots(),
                    builder: (context, turmasSnapshot) {
                      if (turmasSnapshot.hasError) {
                        return _buildErrorState('Erro ao carregar turmas');
                      }

                      if (turmasSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return _buildLoadingState();
                      }

                      final turmasData = turmasSnapshot.data!.docs;

                      return Padding(
                        padding: EdgeInsets.all(16),
                        child: AnimationLimiter(
                          child: Column(
                            children: AnimationConfiguration.toStaggeredList(
                              duration: Duration(milliseconds: 375),
                              childAnimationBuilder:
                                  (widget) => SlideAnimation(
                                    verticalOffset: 50.0,
                                    child: FadeInAnimation(child: widget),
                                  ),
                              children:
                                  turmasData.map((turma) {
                                    return _buildTurmaCard(
                                      context,
                                      turma,
                                      materias,
                                    );
                                  }).toList(),
                            ),
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
      ),
    );
  }

  Widget _buildTurmaCard(
    BuildContext context,
    DocumentSnapshot turma,
    List<String> materias,
  ) {
    final turmaData = turma.data() as Map<String, dynamic>;
    final alunos = List<Map<String, dynamic>>.from(turmaData['alunos'] ?? []);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.class_, color: AppColors.primaryBlue, size: 28),
          ),
          title: Text(
            'Turma ${turmaData['nome']}',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(Icons.people, size: 16, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                '${alunos.length} alunos',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(15),
                ),
              ),
              child: Column(
                children:
                    alunos.map((aluno) {
                      return _buildAlunoTile(
                        context,
                        aluno,
                        turmaData['nome'],
                        materias,
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlunoTile(
    BuildContext context,
    Map<String, dynamic> aluno,
    String turma,
    List<String> materias,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryBlue,
        child: Text(
          aluno['nome'][0].toUpperCase(),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        aluno['nome'],
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'Clique para lançar notas',
        style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: Icon(Icons.edit, color: AppColors.primaryBlue),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => LancarNotaAlunoScreen(
                  alunoId: aluno['uid'],
                  alunoNome: aluno['nome'],
                  turma: turma,
                  materias: materias,
                ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'Carregando...',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.white),
          SizedBox(height: 16),
          Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isTurmasEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isTurmasEmpty ? Icons.class_outlined : Icons.subject,
            size: 64,
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Text(
            isTurmasEmpty
                ? 'Você ainda não tem turmas atribuídas'
                : 'Você ainda não selecionou suas matérias',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back),
            label: Text('Voltar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryBlue,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ... First part of the code remains the same until LancarNotaAlunoScreen ...

class LancarNotaAlunoScreen extends StatefulWidget {
  final String alunoId;
  final String alunoNome;
  final String turma;
  final List<String> materias;

  const LancarNotaAlunoScreen({
    Key? key,
    required this.alunoId,
    required this.alunoNome,
    required this.turma,
    required this.materias,
  }) : super(key: key);

  @override
  _LancarNotaAlunoScreenState createState() => _LancarNotaAlunoScreenState();
}

class _LancarNotaAlunoScreenState extends State<LancarNotaAlunoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Map<String, TextEditingController>> _controllers = {
    'ciclo1': {},
    'ciclo2': {},
    'ciclo3': {},
  };
  bool _isLoading = false;
  int _selectedCiclo = 1;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each subject in each cycle
    for (var materia in widget.materias) {
      _controllers['ciclo1']![materia] = TextEditingController();
      _controllers['ciclo2']![materia] = TextEditingController();
      _controllers['ciclo3']![materia] = TextEditingController();
    }
    _carregarNotasExistentes();
  }

  Future<void> _carregarNotasExistentes() async {
    try {
      DocumentSnapshot notasDoc =
          await _firestore.collection('notas').doc(widget.alunoId).get();

      if (notasDoc.exists) {
        Map<String, dynamic> notasData =
            notasDoc.data() as Map<String, dynamic>;

        for (var ciclo in ['ciclo1', 'ciclo2', 'ciclo3']) {
          Map<String, dynamic> cicloNotas =
              notasData[ciclo] as Map<String, dynamic>? ?? {};

          cicloNotas.forEach((materia, nota) {
            if (_controllers[ciclo]!.containsKey(materia)) {
              _controllers[ciclo]![materia]?.text = nota.toString();
            }
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar notas: $e');
    }
  }

  Future<void> _salvarNotas() async {
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> cicloNotas = {};

      _controllers['ciclo$_selectedCiclo']!.forEach((materia, controller) {
        if (controller.text.isNotEmpty) {
          String notaText = controller.text.replaceAll(',', '.');
          cicloNotas[materia] = double.tryParse(notaText) ?? 0.0;
        }
      });

      await _firestore.collection('notas').doc(widget.alunoId).set({
        'ciclo$_selectedCiclo': cicloNotas,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notas do ${_selectedCiclo}º Ciclo salvas com sucesso!',
          ),
        ),
      );
    } catch (e) {
      print('Erro ao salvar notas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar notas'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryBlue, Colors.white],
            stops: [0.0, 0.3],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  'Lançar Notas - ${_selectedCiclo}º Ciclo',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                background: Container(
                  // ... Header background remains the same ...
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children:
                              [1, 2, 3].map((ciclo) {
                                bool isSelected = _selectedCiclo == ciclo;
                                return InkWell(
                                  onTap:
                                      () => setState(
                                        () => _selectedCiclo = ciclo,
                                      ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 24,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? AppColors.primaryBlue
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Text(
                                      '${ciclo}º Ciclo',
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ),
                  AnimationLimiter(
                    child: Column(
                      children: AnimationConfiguration.toStaggeredList(
                        duration: Duration(milliseconds: 375),
                        childAnimationBuilder:
                            (widget) => SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(child: widget),
                            ),
                        children:
                            widget.materias.map((materia) {
                              return _buildMateriaCard(materia);
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _salvarNotas,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child:
              _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                    'Salvar Notas do ${_selectedCiclo}º Ciclo',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildMateriaCard(String materia) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              materia,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _controllers['ciclo$_selectedCiclo']![materia],
              decoration: InputDecoration(
                labelText: 'Nota do ${_selectedCiclo}º Ciclo',
                hintText: 'Digite a nota',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.grade, color: AppColors.primaryBlue),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var cicloControllers in _controllers.values) {
      for (var controller in cicloControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }
}
