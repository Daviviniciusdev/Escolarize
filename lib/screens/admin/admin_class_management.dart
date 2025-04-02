import 'package:Escolarize/models/user_model.dart';
import 'package:Escolarize/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AdminClassManagement extends StatefulWidget {
  final UserModel adminUser;

  const AdminClassManagement({super.key, required this.adminUser});

  @override
  _AdminClassManagementState createState() => _AdminClassManagementState();
}

class _AdminClassManagementState extends State<AdminClassManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _turmas = [
    '4m1',
    '4m2',
    '4v1',
    '4v2',
    '5m1',
    '5m2',
    '5v1',
    '5v2',
  ];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _inicializarTurmas().then((_) => setState(() => _isLoading = false));
  }

  // ... existing _inicializarTurmas method ...
  Future<void> _inicializarTurmas() async {
    try {
      WriteBatch batch = _firestore.batch();

      for (String turma in _turmas) {
        DocumentReference turmaRef = _firestore.collection('turmas').doc(turma);
        DocumentSnapshot turmaDoc = await turmaRef.get();

        if (!turmaDoc.exists) {
          batch.set(turmaRef, {
            'nome': turma,
            'alunos': [],
            'criadoEm': FieldValue.serverTimestamp(),
            'ultimaAtualizacao': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      print('Turmas inicializadas com sucesso'); // Debug
    } catch (e) {
      print('Erro ao inicializar turmas: $e'); // Debug
      _mostrarMensagem('Erro ao inicializar turmas: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          'Gerenciamento de Turmas',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() => _isLoading = true),
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBlue,
                  ),
                ),
              )
              : StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('turmas').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorWidget('Erro ao carregar turmas');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryBlue,
                        ),
                      ),
                    );
                  }

                  return AnimationLimiter(
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final turma = snapshot.data!.docs[index];
                        final dados = turma.data() as Map<String, dynamic>;
                        final alunos = (dados['alunos'] as List?) ?? [];
                        final turmaNome = dados['nome']?.toString() ?? turma.id;

                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Card(
                                elevation: 4,
                                margin: EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ExpansionTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primaryBlue
                                        .withOpacity(0.1),
                                    child: Text(
                                      turmaNome[0].toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    'Turma $turmaNome',
                                    style: GoogleFonts.poppins(
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
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    if (alunos.isEmpty)
                                      Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                          'Nenhum aluno matriculado',
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      )
                                    else
                                      ...alunos.map(
                                        (aluno) => ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.grey[100],
                                            child: Text(
                                              (aluno['nome'] ?? 'A')[0]
                                                  .toUpperCase(),
                                              style: GoogleFonts.poppins(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            aluno['nome'] ??
                                                'Nome não disponível',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          subtitle: Text(
                                            aluno['email'] ??
                                                'Email não disponível',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(
                                              Icons.remove_circle_outline,
                                              color: Colors.red[400],
                                            ),
                                            onPressed:
                                                () => _showRemoveDialog(
                                                  context,
                                                  turmaNome,
                                                  aluno['uid'] ?? '',
                                                  aluno['nome'] ?? 'este aluno',
                                                ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.red[400]),
          ),
        ],
      ),
    );
  }

  Future<void> _showRemoveDialog(
    BuildContext context,
    String turma,
    String alunoUid,
    String alunoNome,
  ) {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              'Remover Aluno',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Tem certeza que deseja remover $alunoNome da turma $turma?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Remover',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _removerAluno(turma, alunoUid);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _removerAluno(String turma, String alunoUid) async {
    try {
      // 1. Buscar a turma atual
      DocumentSnapshot turmaDoc =
          await _firestore.collection('turmas').doc(turma).get();
      if (!turmaDoc.exists) {
        throw 'Turma não encontrada';
      }

      Map<String, dynamic> turmaData = turmaDoc.data() as Map<String, dynamic>;
      List<dynamic> alunos = List.from(turmaData['alunos'] ?? []);

      print('Lista de alunos antes: $alunos'); // Debug

      // 2. Remover aluno usando uid ou email
      bool alunoEncontrado = false;
      String? emailAluno;

      // Primeiro, tentar encontrar o aluno pelo uid
      var alunoIndex = alunos.indexWhere((aluno) => aluno['uid'] == alunoUid);
      if (alunoIndex != -1) {
        emailAluno = alunos[alunoIndex]['email'];
        alunoEncontrado = true;
      }

      // Se não encontrou pelo uid, buscar nos usuários
      if (!alunoEncontrado) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(alunoUid).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          emailAluno = userData['email'];
          alunoEncontrado = true;
        }
      }

      if (!alunoEncontrado) {
        throw 'Aluno não encontrado';
      }

      // 3. Remover o aluno da lista usando uid ou email
      alunos.removeWhere(
        (aluno) => aluno['uid'] == alunoUid || aluno['email'] == emailAluno,
      );

      print('Lista de alunos depois: $alunos'); // Debug

      // 4. Atualizar documento da turma
      await _firestore.collection('turmas').doc(turma).update({
        'alunos': alunos,
        'ultimaAtualizacao': FieldValue.serverTimestamp(),
      });

      // 5. Atualizar documento do aluno
      await _firestore.collection('users').doc(alunoUid).update({
        'serie': null,
      });

      print(
        'Aluno $alunoUid (email: $emailAluno) removido da turma $turma',
      ); // Debug
      _mostrarMensagem('Aluno removido da turma com sucesso!');
    } catch (e) {
      print('Erro ao remover aluno da turma: $e'); // Debug
      _mostrarMensagem('Erro ao remover aluno da turma: $e', isError: true);
    }
  }

  void _mostrarMensagem(String mensagem, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
