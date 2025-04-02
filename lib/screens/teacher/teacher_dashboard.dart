// ignore_for_file: library_private_types_in_public_api, avoid_print, deprecated_member_use, no_leading_underscores_for_local_identifiers

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:Escolarize/models/user_model.dart';
import 'package:Escolarize/screens/student/attendance_screen.dart';
import 'package:Escolarize/screens/login_pages/login_screen.dart';
import 'package:Escolarize/screens/student/notes_release_screen.dart';
import 'package:Escolarize/utils/app_colors.dart';

class TeacherDashboard extends StatefulWidget {
  final UserModel user;

  const TeacherDashboard({super.key, required this.user});

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  final List<String> _materias = [
    'Matemática',
    'Português',
    'História',
    'Geografia',
    'Ciências',
    'Física',
    'Química',
    'Biologia',
    'Inglês',
    'Educação Física',
  ];

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _buildDashboardHome(),
      _buildClassesScreen(),
      _buildProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _mostrarTelaLancamentoNotas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LancamentoNotasScreen(
              teacherId: widget.user.id,
              teacherName: widget.user.name,
            ),
      ),
    );
  }

  void _mostrarTelaFrequencia() {
    String teacherName = '';

    // Buscar o nome do professor no Firestore
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.id)
        .get()
        .then((doc) {
          if (doc.exists) {
            Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
            teacherName = userData['nome'] ?? userData['name'] ?? 'Professor';

            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AttendanceScreen(
                      teacherId: widget.user.id,
                      teacherName: teacherName,
                    ),
              ),
            );
          }
        });
  }

  void _mostrarListaAlunos() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text('Meus Alunos'),
                elevation: 0,
                backgroundColor: AppColors.primaryBlue,
              ),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primaryBlue, Colors.white],
                    stops: [0.0, 0.3],
                  ),
                ),
                child: StreamBuilder<DocumentSnapshot>(
                  stream:
                      _firestore
                          .collection('teachers')
                          .doc(widget.user.id)
                          .snapshots(),
                  builder: (context, teacherSnapshot) {
                    if (teacherSnapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16),
                            Text('Erro ao carregar turmas'),
                          ],
                        ),
                      );
                    }

                    if (!teacherSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    List<String> turmasDosProfessores = List<String>.from(
                      (teacherSnapshot.data!.data()
                              as Map<String, dynamic>?)?['turmas'] ??
                          [],
                    );

                    if (turmasDosProfessores.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Você ainda não tem turmas atribuídas',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _mostrarDialogSelecionarTurma();
                              },
                              icon: Icon(Icons.add),
                              label: Text('Adicionar Turma'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream:
                          _firestore
                              .collection('turmas')
                              .where('nome', whereIn: turmasDosProfessores)
                              .snapshots(),
                      builder: (context, turmasSnapshot) {
                        if (turmasSnapshot.hasError) {
                          return Center(child: Text('Erro ao carregar alunos'));
                        }

                        if (!turmasSnapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        List<Map<String, dynamic>> todosAlunos = [];
                        Map<String, String> alunoTurma = {};

                        for (var turmaDoc in turmasSnapshot.data!.docs) {
                          var turmaData =
                              turmaDoc.data() as Map<String, dynamic>;
                          var alunos = List<Map<String, dynamic>>.from(
                            turmaData['alunos'] ?? [],
                          );

                          for (var aluno in alunos) {
                            todosAlunos.add(aluno);
                            alunoTurma[aluno['uid']] = turmaData['nome'];
                          }
                        }

                        if (todosAlunos.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Nenhum aluno encontrado nas suas turmas',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        todosAlunos.sort(
                          (a, b) => a['nome'].compareTo(b['nome']),
                        );

                        return Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Total de alunos: ${todosAlunos.length}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.all(8),
                                itemCount: todosAlunos.length,
                                itemBuilder: (context, index) {
                                  final aluno = todosAlunos[index];
                                  final turma = alunoTurma[aluno['uid']];

                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.primaryBlue,
                                        child: Text(
                                          aluno['nome'][0].toUpperCase(),
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      title: Text(aluno['nome']),
                                      subtitle: Text('Turma $turma'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.grade,
                                              color: Colors.amber,
                                            ),
                                            onPressed:
                                                () => _lancarNota(
                                                  aluno['uid'],
                                                  aluno['nome'],
                                                ),
                                            tooltip: 'Notas',
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.info_outline,
                                              color: AppColors.primaryBlue,
                                            ),
                                            onPressed:
                                                () => _mostrarDetalhesAluno(
                                                  aluno,
                                                  turma!,
                                                ),
                                            tooltip: 'Detalhes',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
      ),
    );
  }

  // 3. Adicione o método para mostrar detalhes do aluno:
  void _mostrarDetalhesAluno(Map<String, dynamic> aluno, String turma) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student Header (mantém o mesmo)
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primaryBlue,
                        radius: 30,
                        child: Text(
                          aluno['nome'][0].toUpperCase(),
                          style: TextStyle(fontSize: 24, color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              aluno['nome'],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Turma $turma',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 32),

                  // Notas Section
                  Text(
                    'Notas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('notas')
                              .doc(aluno['uid'])
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Erro ao carregar notas: ${snapshot.error}',
                            ),
                          );
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Nenhuma nota registrada',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed:
                                      () => _lancarNota(
                                        aluno['uid'],
                                        aluno['nome'],
                                      ),
                                  icon: Icon(Icons.add),
                                  label: Text('Lançar Nota'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final notasData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final ciclos = ['ciclo1', 'ciclo2', 'ciclo3'];

                        return ListView.builder(
                          itemCount: ciclos.length,
                          itemBuilder: (context, index) {
                            final ciclo = ciclos[index];
                            final cicloNotas =
                                notasData[ciclo] as Map<String, dynamic>? ?? {};

                            if (cicloNotas.isEmpty) {
                              return SizedBox.shrink();
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    '${index + 1}º Ciclo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ),
                                ...cicloNotas.entries.map((entry) {
                                  final materia = entry.key;
                                  final nota = entry.value as num;
                                  return Card(
                                    margin: EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: _getGradeColor(
                                          nota.toDouble(),
                                        ).withOpacity(0.2),
                                        child: Text(
                                          nota.toStringAsFixed(1),
                                          style: TextStyle(
                                            color: _getGradeColor(
                                              nota.toDouble(),
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(materia),
                                      trailing: IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: AppColors.primaryBlue,
                                        ),
                                        onPressed:
                                            () => _lancarNota(
                                              aluno['uid'],
                                              aluno['nome'],
                                            ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                Divider(),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Fechar'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed:
                            () => _lancarNota(aluno['uid'], aluno['nome']),
                        icon: Icon(Icons.add),
                        label: Text('Nova Nota'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Color _getGradeColor(double grade) {
    if (grade >= 7) return Colors.green;
    if (grade >= 5) return Colors.orange;
    return Colors.red;
  }

  void _showAnnouncementsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              appBar: AppBar(
                title: Text('Comunicados'),
                actions: [
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _showCreateAnnouncementDialog,
                  ),
                ],
              ),
              body: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('announcements')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro ao carregar comunicados'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final announcements =
                      snapshot.data?.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final targetRoles = List<String>.from(
                          data['targetRoles'] ?? [],
                        );
                        return targetRoles.contains('all') ||
                            targetRoles.contains('teacher') ||
                            data['createdBy'] == widget.user.id;
                      }).toList() ??
                      [];

                  if (announcements.isEmpty) {
                    return Center(child: Text('Nenhum comunicado disponível'));
                  }

                  return ListView.builder(
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final data =
                          announcements[index].data() as Map<String, dynamic>;
                      final createdAt = DateTime.parse(data['createdAt']);
                      final isMyAnnouncement =
                          data['createdBy'] == widget.user.id;

                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ExpansionTile(
                          leading: Icon(
                            Icons.announcement,
                            color:
                                isMyAnnouncement
                                    ? Colors.green
                                    : AppColors.primaryBlue,
                          ),
                          title: Text(
                            data['title'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing:
                              isMyAnnouncement
                                  ? IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed:
                                        () => _showDeleteConfirmation(
                                          announcements[index].id,
                                          data['title'],
                                        ),
                                  )
                                  : null,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['message']),
                                  SizedBox(height: 8),
                                  Text(
                                    'Enviado por: ${isMyAnnouncement ? 'Você' : data['createdByName'] ?? 'Administrador'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
      ),
    );
  }

  void _showCreateAnnouncementDialog() {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController();
    final _messageController = TextEditingController();
    final Set<String> _selectedRoles = {'student'};

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Novo Comunicado'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Campo obrigatório'
                                  : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: 'Mensagem',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      validator:
                          (value) =>
                              value?.isEmpty ?? true
                                  ? 'Campo obrigatório'
                                  : null,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Destinatários:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      title: Text('Alunos'),
                      value: _selectedRoles.contains('student'),
                      onChanged: (value) {
                        setState(() {
                          if (value ?? false) {
                            _selectedRoles.add('student');
                          } else {
                            _selectedRoles.remove('student');
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    try {
                      await FirebaseFirestore.instance
                          .collection('announcements')
                          .add({
                            'title': _titleController.text,
                            'message': _messageController.text,
                            'createdAt': DateTime.now().toIso8601String(),
                            'createdBy': widget.user.id,
                            'createdByName': widget.user.name,
                            'targetRoles': _selectedRoles.toList(),
                          });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Comunicado enviado com sucesso!'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao enviar comunicado'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text('Enviar'),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(String announcementId, String title) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirmar exclusão'),
            content: Text('Deseja realmente excluir o comunicado "$title"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('announcements')
                        .doc(announcementId)
                        .delete();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Comunicado excluído com sucesso!'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao excluir comunicado'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text('Excluir', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  Widget _buildDashboardHome() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryBlue.withOpacity(0.1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'Painel do Professor',
                        textStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        speed: Duration(milliseconds: 100),
                      ),
                    ],
                    totalRepeatCount: 1,
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
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(),
                      SizedBox(height: 24),
                      _buildDashboardGrid(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.school, size: 32, color: AppColors.primaryBlue),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bem-vindo,',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Text(
                  widget.user.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardGrid() {
    return AnimationLimiter(
      child: StaggeredGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildAnimatedGridItem(
            icon: Icons.class_,
            label: 'Minhas\nTurmas',
            color: Color(0xFF4CAF50),
            onTap: () => _onItemTapped(1),
          ),
          _buildAnimatedGridItem(
            icon: Icons.assignment,
            label: 'Lançar\nNotas',
            color: Color(0xFF2196F3),
            onTap: () => _mostrarTelaLancamentoNotas(),
          ),
          _buildAnimatedGridItem(
            icon: Icons.fact_check,
            label: 'Frequência',
            color: Color(0xFF9C27B0),
            onTap: () => _mostrarTelaFrequencia(),
          ),
          _buildAnimatedGridItem(
            icon: Icons.people,
            label: 'Meus\nAlunos',
            color: Color(0xFFFF9800),
            onTap: () => _mostrarListaAlunos(),
          ),
          _buildAnimatedGridItem(
            icon: Icons.announcement,
            label: 'Comunicados',
            color: Color(0xFFE91E63),
            onTap: () => _showAnnouncementsScreen(),
          ),
          _buildAnimatedGridItem(
            icon: Icons.person,
            label: 'Meu\nPerfil',
            color: Color(0xFF607D8B),
            onTap: () => _onItemTapped(2),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedGridItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimationConfiguration.staggeredGrid(
      position: 1,
      duration: Duration(milliseconds: 375),
      columnCount: 2,
      child: ScaleAnimation(
        child: FadeInAnimation(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 32, color: color),
                    ),
                    SizedBox(height: 12),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassesScreen() {
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
              actions: [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _mostrarDialogSelecionarTurma(),
                  tooltip: 'Adicionar Turma',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Minhas Turmas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: StreamBuilder<DocumentSnapshot>(
                stream:
                    _firestore
                        .collection('teachers')
                        .doc(widget.user.id)
                        .snapshots(),
                builder: (context, teacherSnapshot) {
                  if (teacherSnapshot.hasError) {
                    return _buildErrorState('Erro ao carregar turmas');
                  }

                  if (teacherSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  List<String> turmasDosProfessores = [];
                  if (teacherSnapshot.data?.exists ?? false) {
                    turmasDosProfessores = List<String>.from(
                      (teacherSnapshot.data!.data()
                              as Map<String, dynamic>)['turmas'] ??
                          [],
                    );
                  }

                  if (turmasDosProfessores.isEmpty) {
                    return _buildEmptyState();
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream:
                        _firestore
                            .collection('turmas')
                            .where('nome', whereIn: turmasDosProfessores)
                            .snapshots(),
                    builder: (context, turmasSnapshot) {
                      if (turmasSnapshot.hasError) {
                        return _buildErrorState('Erro ao carregar turmas');
                      }

                      if (turmasSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return _buildLoadingState();
                      }

                      final turmas = turmasSnapshot.data!.docs;

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
                                  turmas.map((turma) {
                                    final turmaData =
                                        turma.data() as Map<String, dynamic>;
                                    final alunos =
                                        List<Map<String, dynamic>>.from(
                                          turmaData['alunos'] ?? [],
                                        );

                                    return Card(
                                      margin: EdgeInsets.only(bottom: 16),
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          dividerColor: Colors.transparent,
                                        ),
                                        child: ExpansionTile(
                                          leading: Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryBlue
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.class_,
                                              color: AppColors.primaryBlue,
                                              size: 28,
                                            ),
                                          ),
                                          title: Text(
                                            'Turma ${turmaData['nome']}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          subtitle: Row(
                                            children: [
                                              Icon(
                                                Icons.people,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '${alunos.length} alunos',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                      bottom: Radius.circular(
                                                        15,
                                                      ),
                                                    ),
                                              ),
                                              child: Column(
                                                children:
                                                    alunos.map((aluno) {
                                                      return ListTile(
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                              vertical: 8,
                                                            ),
                                                        leading: CircleAvatar(
                                                          backgroundColor:
                                                              AppColors
                                                                  .primaryBlue,
                                                          child: Text(
                                                            aluno['nome'][0]
                                                                .toUpperCase(),
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        title: Text(
                                                          aluno['nome'],
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                        subtitle: Text(
                                                          aluno['email'] ?? '',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                Colors
                                                                    .grey[600],
                                                          ),
                                                        ),
                                                        trailing: IconButton(
                                                          icon: Icon(
                                                            Icons.grade,
                                                            color: Colors.amber,
                                                          ),
                                                          onPressed:
                                                              () => _lancarNota(
                                                                aluno['uid'],
                                                                aluno['nome'],
                                                              ),
                                                          tooltip:
                                                              'Lançar nota',
                                                        ),
                                                      );
                                                    }).toList(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_outlined, size: 64, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Você ainda não tem turmas atribuídas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _mostrarDialogSelecionarTurma(),
              icon: Icon(Icons.add),
              label: Text('Adicionar Turma'),
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
      ),
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
            'Carregando turmas...',
            style: TextStyle(color: Colors.white, fontSize: 16),
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
          Text(message, style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  // Adicione este método para mostrar o diálogo de seleção de turma
  void _mostrarDialogSelecionarTurma() async {
    String? turmaSelecionada;

    // Buscar todas as turmas disponíveis
    QuerySnapshot turmasSnapshot = await _firestore.collection('turmas').get();
    List<String> todasTurmas =
        turmasSnapshot.docs
            .map(
              (doc) => (doc.data() as Map<String, dynamic>)['nome'] as String,
            )
            .toList();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Selecionar Turma'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: turmaSelecionada,
                  decoration: InputDecoration(
                    labelText: 'Turma',
                    prefixIcon: Icon(Icons.class_),
                  ),
                  items:
                      todasTurmas.map((turma) {
                        return DropdownMenuItem(
                          value: turma,
                          child: Text(turma),
                        );
                      }).toList(),
                  onChanged: (value) {
                    turmaSelecionada = value;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (turmaSelecionada != null) {
                    try {
                      await _firestore
                          .collection('teachers')
                          .doc(widget.user.id)
                          .set({
                            'turmas': FieldValue.arrayUnion([turmaSelecionada]),
                          }, SetOptions(merge: true));

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Turma adicionada com sucesso!'),
                        ),
                      );
                    } catch (e) {
                      print('Erro ao adicionar turma: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao adicionar turma'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text('Adicionar'),
              ),
            ],
          ),
    );
  }

  void _mostrarDialogSelecionarMaterias() async {
    List<String> materiasSelecionadas = [];

    // Buscar matérias atuais do professor
    DocumentSnapshot teacherDoc =
        await _firestore.collection('teachers').doc(widget.user.id).get();

    if (teacherDoc.exists) {
      Map<String, dynamic> data = teacherDoc.data() as Map<String, dynamic>;
      materiasSelecionadas = List<String>.from(data['materias'] ?? []);
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('Selecionar Matérias'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          _materias.map((materia) {
                            return CheckboxListTile(
                              title: Text(materia),
                              value: materiasSelecionadas.contains(materia),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    materiasSelecionadas.add(materia);
                                  } else {
                                    materiasSelecionadas.remove(materia);
                                  }
                                });
                              },
                            );
                          }).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await _firestore
                              .collection('teachers')
                              .doc(widget.user.id)
                              .set({
                                'materias': materiasSelecionadas,
                              }, SetOptions(merge: true));

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Matérias atualizadas com sucesso!',
                              ),
                            ),
                          );
                        } catch (e) {
                          print('Erro ao atualizar matérias: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao atualizar matérias'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Text('Salvar'),
                    ),
                  ],
                ),
          ),
    );
  }

  // Adicione este método para lançar notas
  void _lancarNota(String alunoId, String alunoNome) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LancamentoNotasScreen(
              teacherId: widget.user.id,
              teacherName: widget.user.name,
            ),
      ),
    );
  }

  Widget _buildProfileScreen() {
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
                  'Meu Perfil',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                    child: Container(
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF6448FE), Color(0xFF5FC6FF)],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primaryBlue.withOpacity(
                            0.1,
                          ),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Info Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoItem(
                              icon: Icons.person,
                              title: 'Nome',
                              value: widget.user.name,
                              color: Color(0xFF4CAF50),
                            ),
                            Divider(height: 24),
                            _buildInfoItem(
                              icon: Icons.email,
                              title: 'E-mail',
                              value: widget.user.email,
                              color: Color(0xFF2196F3),
                            ),
                            Divider(height: 24),
                            _buildInfoItem(
                              icon: Icons.school,
                              title: 'Cargo',
                              value: 'Professor',
                              color: Color(0xFF9C27B0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    // Matérias Card
                    StreamBuilder<DocumentSnapshot>(
                      stream:
                          _firestore
                              .collection('teachers')
                              .doc(widget.user.id)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _buildErrorCard('Erro ao carregar matérias');
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        List<String> materias = [];
                        if (snapshot.data?.exists ?? false) {
                          materias = List<String>.from(
                            (snapshot.data!.data()
                                    as Map<String, dynamic>)['materias'] ??
                                [],
                          );
                        }

                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Minhas Matérias',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: AppColors.primaryBlue,
                                      ),
                                      onPressed:
                                          _mostrarDialogSelecionarMaterias,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                if (materias.isEmpty)
                                  Center(
                                    child: Text(
                                      'Nenhuma matéria selecionada',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        materias.map((materia) {
                                          return Chip(
                                            label: Text(materia),
                                            backgroundColor: AppColors
                                                .primaryBlue
                                                .withOpacity(0.1),
                                            labelStyle: TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            avatar: Icon(
                                              Icons.book,
                                              size: 16,
                                              color: AppColors.primaryBlue,
                                            ),
                                          );
                                        }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 24),
                    // Logout Button
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: InkWell(
                        onTap: () async {
                          try {
                            await FirebaseAuth.instance.signOut();
                            if (!mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                              (route) => false,
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao fazer logout'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.logout,
                                      color: Colors.red,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    'Sair',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.red,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text(message, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  // Adicione este método para mostrar o diálogo de confirmação

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.class_), label: 'Turmas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryBlue,
        onTap: _onItemTapped,
      ),
    );
  }
}
