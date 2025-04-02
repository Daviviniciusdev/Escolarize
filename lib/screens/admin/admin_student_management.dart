// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:Escolarize/models/user_model.dart';
import 'package:Escolarize/screens/student/student_screen_notes.dart';
import 'package:Escolarize/utils/app_colors.dart';

class AdminReportScreen extends StatelessWidget {
  final UserModel adminUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminReportScreen({Key? key, required this.adminUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.primaryBlue,
          title: Text(
            'Gestão de Alunos',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(icon: Icon(Icons.groups), text: 'Por Turma'),
              Tab(icon: Icon(Icons.person_search), text: 'Todos os Alunos'),
            ],
          ),
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
          child: TabBarView(
            children: [_buildTurmasList(), _buildAllStudentsList()],
          ),
        ),
      ),
    );
  }

  Widget _buildTurmasList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('turmas').orderBy('nome').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Erro ao carregar turmas');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final turmas = snapshot.data!.docs;

        if (turmas.isEmpty) {
          return _buildEmptyState('Nenhuma turma cadastrada');
        }

        return AnimationLimiter(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: turmas.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildTurmaCard(context, turmas[index]),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTurmaCard(BuildContext context, DocumentSnapshot turmaDoc) {
    final turmaData = turmaDoc.data() as Map<String, dynamic>;
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
            style: TextStyle(
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
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: alunos.length,
                itemBuilder:
                    (context, index) => _buildAlunoTile(
                      context,
                      alunos[index],
                      turmaData['nome'],
                    ),
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
  ) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(aluno['uid']).get(),
      builder: (context, snapshot) {
        String nome = aluno['nome'] ?? 'Nome não disponível';
        String email = aluno['email'] ?? '';

        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          nome = userData['nome'] ?? nome;
          email = userData['email'] ?? email;
        }

        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryBlue,
            child: Text(
              nome[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(nome, style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(
            email,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          trailing: IconButton(
            icon: Icon(Icons.visibility, color: AppColors.primaryBlue),
            onPressed:
                () => _navegarParaNotas(context, aluno['uid'], nome, turma),
          ),
        );
      },
    );
  }

  void _navegarParaNotas(
    BuildContext context,
    String alunoId,
    String nome,
    String turma,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AlunoNotasScreen(
              alunoId: alunoId,
              alunoNome: nome,
              turma: turma,
            ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 48, color: Colors.white),
          SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAllStudentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('users')
              .where('role', isEqualTo: 'student')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Erro ao carregar alunos');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final students = snapshot.data!.docs;

        if (students.isEmpty) {
          return _buildEmptyState('Nenhum aluno cadastrado');
        }

        return AnimationLimiter(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final studentData =
                  students[index].data() as Map<String, dynamic>;
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryBlue,
                        child: Text(
                          studentData['nome'][0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        studentData['nome'],
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        studentData['email'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.visibility,
                          color: AppColors.primaryBlue,
                        ),
                        onPressed:
                            () => _navegarParaNotas(
                              context,
                              students[index].id,
                              studentData['nome'],
                              'N/A',
                            ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
