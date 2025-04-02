// ignore_for_file: library_private_types_in_public_api, sort_child_properties_last, avoid_print, unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Escolarize/models/user_model.dart';
import 'package:Escolarize/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUserManagementScreen extends StatefulWidget {
  final UserModel adminUser;

  const AdminUserManagementScreen({super.key, required this.adminUser});

  @override
  _AdminUserManagementScreenState createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          'Gerenciamento de Usuários',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Atualizar lista',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 80,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(width: 8),
                  _buildTabButton(0, Icons.school, 'Alunos'),
                  SizedBox(width: 12),
                  _buildTabButton(1, Icons.person_2, 'Professores'),
                  SizedBox(width: 12),
                  _buildTabButton(
                    2,
                    Icons.admin_panel_settings,
                    'Funcionários',
                  ),
                  SizedBox(width: 8),
                ],
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildUserList(UserRole.student),
                _buildUserList(UserRole.teacher),
                _buildUserList(UserRole.admin),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isSelected
                      ? Colors.transparent
                      : Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primaryBlue : Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: isSelected ? AppColors.primaryBlue : Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(UserRole role) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('users')
              .where('role', isEqualTo: role.toString().split('.').last)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Erro ao carregar usuários');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final users = snapshot.data!.docs;

        if (users.isEmpty) {
          return _buildEmptyState(role);
        }

        return Padding(
          padding: EdgeInsets.all(16),
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              final userName =
                  userData['nome'] ?? userData['name'] ?? 'Nome não definido';

              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                        child: Text(
                          userName[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.email, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    userData['email'] ?? 'Email não definido',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (role == UserRole.student) ...[
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.class_,
                                    size: 16,
                                    color:
                                        userData['serie'] == null
                                            ? Colors.red
                                            : Colors.green,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Turma: ${userData['serie'] ?? 'Não matriculado'}',
                                    style: GoogleFonts.poppins(
                                      color:
                                          userData['serie'] == null
                                              ? Colors.red
                                              : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (role == UserRole.teacher)
                              FutureBuilder<DocumentSnapshot>(
                                future:
                                    _firestore
                                        .collection('teachers')
                                        .doc(userId)
                                        .get(),
                                builder: (context, teacherSnapshot) {
                                  if (teacherSnapshot.hasData &&
                                      teacherSnapshot.data!.exists) {
                                    List<String> materias = List<String>.from(
                                      teacherSnapshot.data!.get('materias') ??
                                          [],
                                    );
                                    return Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.book,
                                            size: 16,
                                            color: Colors.blue,
                                          ),
                                          SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Matérias: ${materias.join(", ")}',
                                              style: GoogleFonts.poppins(
                                                color: Colors.blue,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return SizedBox.shrink();
                                },
                              ),
                          ],
                        ),
                      ),

                      // Delete button
                      IconButton(
                        icon: Icon(Icons.delete_outline),
                        color: Colors.red,
                        onPressed:
                            () => _excluirUsuario(userId, userData['email']),
                        tooltip: 'Excluir usuário',
                      ),
                    ],
                  ),
                ),
              );
            },
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
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
          SizedBox(height: 16),
          Text(
            'Carregando usuários...',
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
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
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(color: Colors.red, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(UserRole role) {
    String message =
        'Nenhum ${role == UserRole.student
            ? 'aluno'
            : role == UserRole.teacher
            ? 'professor'
            : 'funcionário'} cadastrado';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            role == UserRole.student
                ? Icons.school_outlined
                : role == UserRole.teacher
                ? Icons.person_2_outlined
                : Icons.admin_panel_settings_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _excluirUsuario(String userId, String userEmail) async {
    try {
      bool confirmacao = await _mostrarDialogConfirmacao(
        'Deseja realmente excluir este usuário?',
        'Usuário: $userEmail',
      );

      if (!confirmacao) return;

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      if (userData['role'] == 'student') {
        String? serie = userData['serie'];
        if (serie != null) {
          DocumentReference turmaRef = _firestore
              .collection('turmas')
              .doc(serie);
          DocumentSnapshot turmaDoc = await turmaRef.get();

          if (turmaDoc.exists) {
            Map<String, dynamic> turmaData =
                turmaDoc.data() as Map<String, dynamic>;
            List<dynamic> alunos = List.from(turmaData['alunos'] ?? []);
            alunos.removeWhere(
              (aluno) => aluno['uid'] == userId || aluno['email'] == userEmail,
            );

            await turmaRef.update({
              'alunos': alunos,
              'ultimaAtualizacao': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      await _firestore.collection('users').doc(userId).delete();

      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (e) {
        print('Erro ao excluir usuário do Auth: $e');
      }

      _mostrarMensagem('Usuário excluído com sucesso!');
    } catch (e) {
      _mostrarMensagem(
        'Erro ao excluir usuário: ${e.toString()}',
        isError: true,
      );
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

  Future<bool> _mostrarDialogConfirmacao(String titulo, String conteudo) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(titulo),
                content: Text(conteudo),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Confirmar'),
                  ),
                ],
              ),
        ) ??
        false;
  }
}
