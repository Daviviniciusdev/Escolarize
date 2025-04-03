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
    _inicializarTurmas().then((_) {
      // Verificar e corrigir duplicatas em todas as turmas
      for (final turma in _turmas) {
        _verificarDuplicatasNaTurma(turma);
      }
      setState(() => _isLoading = false);
    });
  }

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
      body: _isLoading
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
                                  backgroundColor:
                                      AppColors.primaryBlue.withOpacity(0.1),
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
                                          onPressed: () => _showRemoveDialog(
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
      builder: (context) => AlertDialog(
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
      // 1. Verificar se o alunoUid é válido
      if (alunoUid.isEmpty) {
        throw 'ID do aluno inválido';
      }

      print('Tentando remover aluno $alunoUid da turma $turma'); // Debug

      // 2. Buscar o documento do aluno primeiro para confirmar dados
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(alunoUid).get();

      if (!userDoc.exists) {
        throw 'Usuário não encontrado no banco de dados';
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      final String emailAluno = userData['email'] ?? '';
      final String nomeAluno = userData['name'] ?? userData['nome'] ?? '';

      print('Aluno encontrado: $nomeAluno ($emailAluno)'); // Debug

      // 3. Buscar a turma atual
      DocumentSnapshot turmaDoc =
          await _firestore.collection('turmas').doc(turma).get();
      if (!turmaDoc.exists) {
        throw 'Turma $turma não encontrada';
      }

      Map<String, dynamic> turmaData = turmaDoc.data() as Map<String, dynamic>;
      List<dynamic> alunos = List.from(turmaData['alunos'] ?? []);

      print('Total de alunos na turma antes: ${alunos.length}'); // Debug

      // 4. Verificar se o aluno está na turma
      int alunoIndex = -1;

      // Procurar pelo uid
      alunoIndex = alunos
          .indexWhere((aluno) => aluno is Map && aluno['uid'] == alunoUid);

      // Se não encontrou pelo uid, procurar pelo email
      if (alunoIndex == -1 && emailAluno.isNotEmpty) {
        alunoIndex = alunos.indexWhere(
            (aluno) => aluno is Map && aluno['email'] == emailAluno);
      }

      if (alunoIndex == -1) {
        throw 'Aluno não encontrado na turma $turma';
      }

      // 5. Remover o aluno especifico da lista (usando o índice encontrado)
      alunos.removeAt(alunoIndex);

      print('Total de alunos na turma depois: ${alunos.length}'); // Debug

      // 6. Executar as atualizações em uma transaction para garantir consistência
      await _firestore.runTransaction((transaction) async {
        // Atualiza a turma
        transaction.update(_firestore.collection('turmas').doc(turma), {
          'alunos': alunos,
          'ultimaAtualizacao': FieldValue.serverTimestamp(),
        });

        // Atualiza o aluno
        transaction.update(_firestore.collection('users').doc(alunoUid), {
          'serie': null,
        });
      });

      print('Aluno $nomeAluno removido com sucesso da turma $turma'); // Debug
      _mostrarMensagem('Aluno $nomeAluno removido da turma com sucesso!');
    } catch (e) {
      print('❌ Erro detalhado ao remover aluno: $e'); // Debug detalhado

      String mensagemErro = 'Erro ao remover aluno da turma';
      if (e is FirebaseException) {
        mensagemErro += ': ${e.message}';
      } else {
        mensagemErro += ': $e';
      }

      _mostrarMensagem(mensagemErro, isError: true);
    }
  }

// Adicione esse método à classe _AdminClassManagementState
  Future<void> _verificarDuplicatasNaTurma(String turmaId) async {
    try {
      final turmaDoc = await _firestore.collection('turmas').doc(turmaId).get();
      if (!turmaDoc.exists) return;

      final turmaData = turmaDoc.data() as Map<String, dynamic>;
      final alunos = List.from(turmaData['alunos'] ?? []);

      // Mapear UIDs e emails para verificar duplicatas
      final uids = <String>{};
      final emails = <String>{};
      final duplicateUids = <String>[];
      final duplicateEmails = <String>[];

      for (var aluno in alunos) {
        if (aluno is Map) {
          final uid = aluno['uid'] as String?;
          final email = aluno['email'] as String?;

          if (uid != null) {
            if (uids.contains(uid)) {
              duplicateUids.add(uid);
            } else {
              uids.add(uid);
            }
          }

          if (email != null) {
            if (emails.contains(email)) {
              duplicateEmails.add(email);
            } else {
              emails.add(email);
            }
          }
        }
      }

      // Remover duplicatas se encontradas
      if (duplicateUids.isNotEmpty || duplicateEmails.isNotEmpty) {
        print('⚠️ Encontradas duplicatas na turma $turmaId:');
        print('UIDs duplicados: $duplicateUids');
        print('Emails duplicados: $duplicateEmails');

        // Remover duplicatas
        final uniqueAlunos = <Map<String, dynamic>>[];
        final processedUids = <String>{};
        final processedEmails = <String>{};

        for (var aluno in alunos) {
          if (aluno is Map) {
            final uid = aluno['uid'] as String?;
            final email = aluno['email'] as String?;

            if (uid != null && !processedUids.contains(uid)) {
              uniqueAlunos.add(Map<String, dynamic>.from(aluno));
              processedUids.add(uid);
            } else if (email != null &&
                !processedEmails.contains(email) &&
                uid == null) {
              uniqueAlunos.add(Map<String, dynamic>.from(aluno));
              processedEmails.add(email);
            }
          }
        }

        // Atualizar turma com lista sem duplicatas
        await _firestore.collection('turmas').doc(turmaId).update({
          'alunos': uniqueAlunos,
          'ultimaAtualizacao': FieldValue.serverTimestamp(),
        });

        print(
            '✅ Duplicatas removidas. Nova quantidade de alunos: ${uniqueAlunos.length}');
      }
    } catch (e) {
      print('Erro ao verificar duplicatas: $e');
    }
  }

  void _mostrarMensagem(String mensagem, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mensagem,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      print('Mensagem não exibida (widget desmontado): $mensagem');
    }
  }
}
