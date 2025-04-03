// ignore_for_file: library_private_types_in_public_api, sort_child_properties_last, avoid_print, unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Escolarize/models/user_model.dart';
import 'package:Escolarize/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;

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
  final _storage = const FlutterSecureStorage();
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        icon: Icon(Icons.person_add),
        label: Text('Novo Usuário',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: const Color.fromARGB(255, 189, 185, 185),
            )),
        backgroundColor: AppColors.primaryBlue,
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
              color: isSelected
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
      stream: _firestore
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
                                    color: userData['serie'] == null
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Turma: ${userData['serie'] ?? 'Não matriculado'}',
                                    style: GoogleFonts.poppins(
                                      color: userData['serie'] == null
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (role == UserRole.teacher)
                              FutureBuilder<DocumentSnapshot>(
                                future: _firestore
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
        'Nenhum ${role == UserRole.student ? 'aluno' : role == UserRole.teacher ? 'professor' : 'funcionário'} cadastrado';

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

  void _mostrarMensagem(String mensagem, {bool isError = false}) {
    if (mounted) {
      // Verificar se o widget ainda está montado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    } else {
      // Registrar mensagem somente no console se o widget não estiver montado
      print('❗ Mensagem não exibida (widget desmontado): $mensagem');
    }
  }

  void _showCreateUserDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nomeController = TextEditingController();
    final _emailController = TextEditingController();
    final _senhaController = TextEditingController();
    final _adminPasswordController = TextEditingController();
    String? _selectedSerie;
    UserRole _selectedRole = UserRole.student;
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person_add, color: AppColors.primaryBlue),
              SizedBox(width: 12),
              Text(
                'Novo Usuário',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Campo Nome
                  TextFormField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      labelText: 'Nome Completo',
                      icon: Icon(Icons.person),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                  ),
                  SizedBox(height: 16),

                  // Campo Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      icon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Campo obrigatório';
                      if (!value!.contains('@')) return 'E-mail inválido';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Campo Senha
                  TextFormField(
                    controller: _senhaController,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      icon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Campo obrigatório';
                      if (value!.length < 6) return 'Mínimo de 6 caracteres';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  // Campo Senha do Admin
                  TextFormField(
                    controller: _adminPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Senha do Admin',
                      helperText: 'Confirme sua senha para criar usuário',
                      icon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Senha necessária' : null,
                  ),
                  SizedBox(height: 16),

                  // Seleção de Tipo de Usuário
                  DropdownButtonFormField<UserRole>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Usuário',
                      icon: Icon(Icons.badge),
                    ),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(
                          role == UserRole.admin
                              ? 'Administrador'
                              : role == UserRole.teacher
                                  ? 'Professor'
                                  : 'Aluno',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                        if (value != UserRole.student) {
                          _selectedSerie = null;
                        }
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  // Campo Série (apenas para alunos)
                  if (_selectedRole == UserRole.student)
                    DropdownButtonFormField<String>(
                      value: _selectedSerie,
                      decoration: InputDecoration(
                        labelText: 'Série/Turma',
                        icon: Icon(Icons.school),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text('Selecione a série'),
                        ),
                        ...[
                          '4m1',
                          '4m2',
                          '4v1',
                          '4v2',
                          '5m1',
                          '5m2',
                          '5v1',
                          '5v2',
                        ].map((serie) {
                          return DropdownMenuItem(
                            value: serie,
                            child: Text(serie.toUpperCase()),
                          );
                        }).toList(),
                      ],
                      validator: (value) =>
                          value == null ? 'Selecione uma série' : null,
                      onChanged: (value) {
                        setState(() => _selectedSerie = value);
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
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        setState(() => _isLoading = true);

                        try {
                          // Obter e armazenar senha do admin
                          final adminEmail = widget.adminUser.email;
                          final adminPassword =
                              _adminPasswordController.text.trim();

                          // Armazenar credenciais temporariamente para caso de emergência
                          await _storage.write(
                              key: 'admin_email_backup', value: adminEmail);
                          await _storage.write(
                              key: 'admin_pwd_backup', value: adminPassword);

                          // Criar usuário sem afetar a sessão atual
                          await _createUserWithoutSignout(
                            email: _emailController.text.trim(),
                            password: _senhaController.text.trim(),
                            name: _nomeController.text.trim(),
                            role: _selectedRole,
                            serie: _selectedRole == UserRole.student
                                ? _selectedSerie
                                : null,
                          );

                          // Limpar backup após sucesso
                          await _storage.delete(key: 'admin_email_backup');
                          await _storage.delete(key: 'admin_pwd_backup');

                          Navigator.pop(context);
                          _mostrarMensagem('Usuário criado com sucesso!');
                        } catch (e) {
                          print('Erro ao criar usuário: $e');
                          _mostrarMensagem(
                              'Erro ao criar usuário: ${e.toString()}',
                              isError: true);
                        } finally {
                          // Limpar credenciais em caso de erro também
                          await _storage.delete(key: 'admin_email_backup');
                          await _storage.delete(key: 'admin_pwd_backup');

                          if (context.mounted) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AdminUserManagementScreen(
                                    adminUser: widget.adminUser,
                                  ),
                                ));
                            if (mounted) {
                              _mostrarMensagem('Usuário criado com sucesso!');
                            }
                          } else if (mounted) {
                            setState(() => _isLoading = false);
                          }
                        }
                      }
                    },
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addStudentToClass(
    String userId,
    String nome,
    String email,
    String serie,
  ) async {
    DocumentReference turmaRef = _firestore.collection('turmas').doc(serie);
    DocumentSnapshot turmaDoc = await turmaRef.get();

    Map<String, dynamic> alunoData = {
      'uid': userId,
      'nome': nome,
      'email': email,
      'serie': serie,
    };

    if (!turmaDoc.exists) {
      await turmaRef.set({
        'nome': serie,
        'alunos': [alunoData],
        'criadoEm': FieldValue.serverTimestamp(),
        'ultimaAtualizacao': FieldValue.serverTimestamp(),
      });
    } else {
      await turmaRef.update({
        'alunos': FieldValue.arrayUnion([alunoData]),
        'ultimaAtualizacao': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _createUserWithoutSignout({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? serie,
  }) async {
    try {
      // 1. Criar usuário no Firebase Auth
      // Isso pode deslogar o admin temporariamente, mas o relogaremos depois
      await _createUserInFirebaseAuth(email, password, "temp_id");

      // 2. Obter o UID do usuário recém-criado
      final newUserCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final userId = newUserCredential.user!.uid;

      // 3. Relogar o admin
      final adminEmail = await _storage.read(key: 'admin_email_backup');
      final adminPassword = await _storage.read(key: 'admin_pwd_backup');
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: adminEmail!, password: adminPassword!);

      // 4. Criar usuário no Firestore
      final novoUsuario = UserModel(
        id: userId,
        name: name,
        email: email,
        role: role,
        serie: serie,
      );

      await _firestore.collection('users').doc(userId).set(novoUsuario.toMap());

      // 5. Se for aluno, adicionar à turma
      if (role == UserRole.student && serie != null) {
        await _addStudentToClass(userId, name, email, serie);
      }
    } catch (e) {
      print('Erro detalhado na criação: $e');

      // Em qualquer caso de erro, tentar reconectar o admin
      try {
        final adminEmail = await _storage.read(key: 'admin_email_backup');
        final adminPassword = await _storage.read(key: 'admin_pwd_backup');
        if (adminEmail != null && adminPassword != null) {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: adminEmail, password: adminPassword);
        }
      } catch (_) {}

      throw e;
    }
  }

  Future<void> _createUserInFirebaseAuth(
      String email, String password, String userId) async {
    try {
      // Obter backup das credenciais do admin (já foram salvas antes)
      final adminEmail = await _storage.read(key: 'admin_email_backup');
      final adminPassword = await _storage.read(key: 'admin_pwd_backup');

      if (adminEmail == null || adminPassword == null) {
        throw Exception('Credenciais do admin não disponíveis');
      }

      // Criar usuário diretamente no Firebase Auth
      // Isso deslogará o admin temporariamente
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Após criar o usuário, imediatamente faça login com o admin novamente
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      // Verificar se o admin está logado novamente
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.email != adminEmail) {
        throw Exception('Falha ao reconectar o admin');
      }

      print('✅ Usuário criado com sucesso e admin mantido logado');
    } catch (e) {
      // Em caso de erro, tente relogar o admin
      try {
        final adminEmail = await _storage.read(key: 'admin_email_backup');
        final adminPassword = await _storage.read(key: 'admin_pwd_backup');

        if (adminEmail != null && adminPassword != null) {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );

          print('🔄 Admin reconectado após erro');
        }
      } catch (_) {
        // Falha na tentativa de reconexão
        print('⚠️ Falha na reconexão do admin após erro');
      }

      print('❌ Erro original ao criar usuário: $e');
      throw e;
    }
  }
}
