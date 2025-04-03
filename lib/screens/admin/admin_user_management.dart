// ignore_for_file: library_private_types_in_public_api, sort_child_properties_last, avoid_print, unused_field, unused_local_variable

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Escolarize/models/user_model.dart';
import 'package:Escolarize/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

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
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isBiometricAvailable = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    if (!mounted) return;

    try {
      // Verifica se o hardware suporta biometria
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        setState(() => _isBiometricAvailable = false);
        return;
      }

      // Verifica quais tipos de biometria estão disponíveis
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      // Verifica se há biometrias cadastradas
      final hasBiometrics =
          availableBiometrics.contains(BiometricType.fingerprint) ||
              availableBiometrics.contains(BiometricType.face) ||
              availableBiometrics.contains(BiometricType.strong);

      if (mounted) {
        setState(() => _isBiometricAvailable = hasBiometrics);
      }
    } catch (e) {
      print('Erro ao verificar biometria: $e');
      if (mounted) {
        setState(() => _isBiometricAvailable = false);
      }
    }
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      // Tenta autenticar
      final authenticated = await _localAuth.authenticate(
        localizedReason:
            'Por favor, use sua biometria para criar um novo usuário',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Permite PIN como fallback
          useErrorDialogs: true,
        ),
      );

      return authenticated;
    } on PlatformException catch (e) {
      print('Erro na autenticação biométrica: ${e.message}');
      return false;
    } catch (e) {
      print('Erro inesperado: $e');
      return false;
    }
  }

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
              final hasClass = userData['serie'] != null;

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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    userName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                // Adicionar botão para matricular (apenas para alunos sem turma)
                                if (role == UserRole.student && !hasClass)
                                  OutlinedButton.icon(
                                    onPressed: () => _showAddToClassDialog(
                                        userId,
                                        userName,
                                        userData['email'] ?? ''),
                                    icon: Icon(
                                      Icons.add_circle_outline,
                                      color: AppColors.primaryBlue,
                                      size: 16,
                                    ),
                                    label: Text(
                                      'Matricular',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 0),
                                      minimumSize: Size(0, 30),
                                      side: BorderSide(
                                          color: AppColors.primaryBlue),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                              ],
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
                                    color: hasClass ? Colors.green : Colors.red,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Turma: ${userData['serie'] ?? 'Não matriculado'}',
                                    style: GoogleFonts.poppins(
                                      color:
                                          hasClass ? Colors.green : Colors.red,
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
    final _adminPasswordController =
        TextEditingController(); // Mantido para backup
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

                  // Substituído o campo de senha do admin por informação de biometria
                  if (_isBiometricAvailable)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primaryBlue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.fingerprint, color: AppColors.primaryBlue),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Autenticação biométrica será solicitada ao criar o usuário',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Campo senha do admin (backup caso biometria não esteja disponível)
                  if (!_isBiometricAvailable)
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

                  // Resto do formulário permanece igual...
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
                          // Se biometria disponível, solicitar autenticação
                          if (_isBiometricAvailable) {
                            final authenticated =
                                await _authenticateWithBiometrics();
                            if (!authenticated) {
                              throw Exception('Autenticação biométrica falhou');
                            }

                            // Autenticação com sucesso, armazenar email do admin
                            final adminEmail = widget.adminUser.email;
                            // Recuperar senha do secure storage se disponível
                            final adminPassword =
                                await _storage.read(key: 'admin_password');

                            if (adminPassword == null) {
                              throw Exception(
                                  'Senha do admin não disponível. Faça login novamente.');
                            }

                            // Armazenar credenciais para relogin
                            await _storage.write(
                                key: 'admin_email_backup', value: adminEmail);
                            await _storage.write(
                                key: 'admin_pwd_backup', value: adminPassword);
                          } else {
                            // Sem biometria, usar senha do admin
                            final adminEmail = widget.adminUser.email;
                            final adminPassword =
                                _adminPasswordController.text.trim();

                            // Validar senha do admin
                            try {
                              final credential = await FirebaseAuth.instance
                                  .signInWithEmailAndPassword(
                                      email: adminEmail,
                                      password: adminPassword);

                              // Login bem sucedido, guarda credenciais e faz login novamente
                              await _storage.write(
                                  key: 'admin_email_backup', value: adminEmail);
                              await _storage.write(
                                  key: 'admin_pwd_backup',
                                  value: adminPassword);

                              // Na prática, o admin já está logado agora
                            } catch (e) {
                              throw Exception('Senha do admin incorreta');
                            }
                          }

                          // Criar usuário com as credenciais verificadas
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
                                builder: (context) => AdminUserManagementScreen(
                                  adminUser: widget.adminUser,
                                ),
                              ),
                            );
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

  void _showAddToClassDialog(String userId, String userName, String email) {
    String? selectedSerie;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.school, color: AppColors.primaryBlue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Matricular Aluno',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aluno: $userName',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Email: $email',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSerie,
                  decoration: InputDecoration(
                    labelText: 'Turma',
                    icon: Icon(Icons.class_),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Selecione a turma'),
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
                  onChanged: (value) {
                    setState(() => selectedSerie = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading || selectedSerie == null
                  ? null
                  : () async {
                      setState(() => isLoading = true);
                      try {
                        // 1. Atualizar documento do usuário
                        await _firestore
                            .collection('users')
                            .doc(userId)
                            .update({'serie': selectedSerie});

                        // 2. Adicionar à turma
                        await _addStudentToClass(
                          userId,
                          userName,
                          email,
                          selectedSerie!,
                        );

                        Navigator.pop(context);
                        _mostrarMensagem(
                            'Aluno matriculado na turma $selectedSerie com sucesso!');
                      } catch (e) {
                        print('Erro ao matricular aluno: $e');
                        _mostrarMensagem(
                            'Erro ao matricular aluno: ${e.toString()}',
                            isError: true);
                      } finally {
                        if (context.mounted) setState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Text('Matricular'),
            ),
          ],
        ),
      ),
    );
  }
}
