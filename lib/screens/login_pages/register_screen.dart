// Tela de Cadastro
// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, deprecated_member_use, unnecessary_to_list_in_spreads

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Escolarize/models/user_model.dart';
import 'package:Escolarize/screens/login_pages/login_screen.dart';
import 'package:Escolarize/services/security_utils.dart';
import 'package:Escolarize/utils/app_colors.dart';
import 'package:http/http.dart' as http;

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  _CadastroScreenState createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _codigoAcessoController = TextEditingController(); // Novo controller
  UserRole _selectedRole = UserRole.student;
  String? _selectedSerie;
  bool _mostrarCampoCodigoAcesso = false;
  bool _isLoading = false;
  int _registrationAttempts = 0;
  DateTime? _lockoutEnd;
  final int _maxAttempts = 5;

  // Updated access codes with salt
  Future<bool> _validateAccessCode(String accessCode, UserRole role) async {
    try {
      return await SecurityUtils.validateAccessCode(
        role == UserRole.admin ? 'admin' : 'teacher',
        accessCode,
      );
    } catch (e) {
      _showError('Erro ao validar código de acesso');
      return false;
    }
  }

  // Lista de séries disponíveis
  final List<String> _seriesList = [
    '4m1',
    '4m2',
    '4v1',
    '4v2',
    '5m1',
    '5m2',
    '5v1',
    '5v2',
  ];

  Future<void> _cadastrar() async {
    if (_isLoading) return;

    if (_lockoutEnd != null && DateTime.now().isBefore(_lockoutEnd!)) {
      final remaining = _lockoutEnd!.difference(DateTime.now());
      _showError(
        'Muitas tentativas. Tente novamente em ${remaining.inMinutes} minutos.',
      );
      return;
    }

    if (!_validateForm()) {
      _registrationAttempts++;
      _checkLockout();
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Validate access code for special users
      if (_selectedRole != UserRole.student) {
        final accessCode = _codigoAcessoController.text.trim();

        final isValidCode = await _validateAccessCode(
          accessCode,
          _selectedRole,
        );

        if (!isValidCode) {
          _showError('Código de acesso inválido');
          _registrationAttempts++;
          _checkLockout();
          setState(() => _isLoading = false);
          return;
        }

        // Log access code attempt
        await FirebaseFirestore.instance
            .collection('access_code_attempts')
            .add({
              'timestamp': FieldValue.serverTimestamp(),
              'role': _selectedRole.toString(),
              'success': true,
              'attempts': _registrationAttempts,
            });
      }

      // Password strength check
      final passwordStrength = SecurityUtils.checkPasswordStrength(
        _senhaController.text,
      );
      if (!passwordStrength['isStrong']) {
        _showError('''Senha muito fraca. A senha deve conter:
        - Pelo menos 8 caracteres
        - Letras maiúsculas e minúsculas
        - Números
        - Caracteres especiais''');
        setState(() => _isLoading = false);
        return;
      }

      // Create user
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _senhaController.text,
          );

      // Log registration attempt
      await _logRegistrationAttempt(userCredential.user!.uid, true);

      String nome = _nomeController.text.trim();
      String email = _emailController.text.trim();

      // Criar documento do usuário no Firestore
      UserModel novoUsuario = UserModel(
        id: userCredential.user!.uid,
        name: nome,
        email: email,
        role: _selectedRole,
        serie: _selectedRole == UserRole.student ? _selectedSerie : null,
      );

      // Salvar usuário no Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(novoUsuario.toMap());

      // Se for aluno, adicionar à turma
      if (_selectedRole == UserRole.student && _selectedSerie != null) {
        DocumentReference turmaRef = FirebaseFirestore.instance
            .collection('turmas')
            .doc(_selectedSerie);

        // Atualizar estrutura dos dados do aluno para garantir consistência
        Map<String, dynamic> alunoData = {
          'uid': userCredential.user!.uid,
          'nome': _nomeController.text.trim(), // Usar 'nome' consistentemente
          'email': _emailController.text.trim(),
          'serie': _selectedSerie,
        };

        // Verificar se a turma existe
        DocumentSnapshot turmaDoc = await turmaRef.get();

        if (!turmaDoc.exists) {
          // Criar nova turma com o aluno
          await turmaRef.set({
            'nome': _selectedSerie,
            'alunos': [alunoData], // Usar a nova estrutura
            'criadoEm': FieldValue.serverTimestamp(),
            'ultimaAtualizacao': FieldValue.serverTimestamp(),
          });
        } else {
          // Atualizar turma existente com o novo aluno
          await turmaRef.update({
            'alunos': FieldValue.arrayUnion([alunoData]),
            'ultimaAtualizacao': FieldValue.serverTimestamp(),
          });
        }

        // Atualizar documento do usuário com informações da turma
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
              'serie': _selectedSerie,
              'nome':
                  _nomeController.text.trim(), // Garantir consistência do nome
            });
      }
      _showSuccess('Cadastro realizado com sucesso!');
      Navigator.of(context).pop();
    } catch (e) {
      await _logRegistrationAttempt(null, false, error: e.toString());
      _showError('Erro no cadastro: ${e.toString()}');
      _registrationAttempts++;
      _checkLockout();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateForm() {
    if (_nomeController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _senhaController.text.isEmpty) {
      _showError('Todos os campos são obrigatórios');
      return false;
    }

    if (!_emailController.text.trim().contains('@')) {
      _showError('Email inválido');
      return false;
    }

    if (_selectedRole == UserRole.student && _selectedSerie == null) {
      _showError('Por favor, selecione a série');
      return false;
    }

    return true;
  }

  void _checkLockout() {
    if (_registrationAttempts >= _maxAttempts) {
      _lockoutEnd = DateTime.now().add(const Duration(minutes: 30));
      _showError(
        'Registro bloqueado por 30 minutos devido a múltiplas tentativas.',
      );
    }
  }

  Future<void> _logRegistrationAttempt(
    String? userId,
    bool success, {
    String? error,
  }) async {
    try {
      final deviceInfo = await SecurityUtils.getDeviceInfo();
      final ipAddress = await _getIpAddress();

      await FirebaseFirestore.instance.collection('registration_logs').add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'success': success,
        'deviceInfo': deviceInfo,
        'ipAddress': ipAddress,
        'error': error,
        'attempts': _registrationAttempts,
        'role': _selectedRole.toString(),
      });
    } catch (e) {
      print('Error logging registration attempt: $e');
    }
  }

  Future<String> _getIpAddress() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      return response.body;
    } catch (e) {
      return 'unknown';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryBlue, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                // Header com animação
                ShaderMask(
                  shaderCallback:
                      (bounds) => LinearGradient(
                        colors: [AppColors.primaryBlue, Colors.purple],
                      ).createShader(bounds),
                  child: Icon(Icons.how_to_reg, size: 80, color: Colors.white),
                ),
                SizedBox(height: 24),

                // Título animado
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Criar Conta',
                      textStyle: GoogleFonts.montserrat(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                      speed: Duration(milliseconds: 100),
                    ),
                  ],
                  totalRepeatCount: 1,
                ),
                SizedBox(height: 32),

                // Card principal com formulário
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Campo Nome
                        _buildInputField(
                          controller: _nomeController,
                          label: 'Nome Completo',
                          icon: Icons.person,
                          hint: 'Digite seu nome completo',
                        ),
                        SizedBox(height: 16),

                        // Campo Email
                        _buildInputField(
                          controller: _emailController,
                          label: 'E-mail',
                          icon: Icons.email,
                          hint: 'Digite seu e-mail',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 16),

                        // Campo Senha
                        _buildInputField(
                          controller: _senhaController,
                          label: 'Senha',
                          icon: Icons.lock,
                          hint: 'Digite sua senha',
                          isPassword: true,
                        ),
                        SizedBox(height: 16),

                        // Dropdown Nível de Acesso
                        _buildDropdownField<UserRole>(
                          value: _selectedRole,
                          label: 'Nível de Acesso',
                          icon: Icons.work,
                          items:
                              UserRole.values.map((role) {
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
                              _mostrarCampoCodigoAcesso =
                                  value == UserRole.admin ||
                                  value == UserRole.teacher;
                              if (value != UserRole.student) {
                                _selectedSerie = null;
                              }
                            });
                          },
                        ),
                        SizedBox(height: 16),

                        // Campo Código de Acesso (condicional)
                        if (_mostrarCampoCodigoAcesso)
                          _buildInputField(
                            controller: _codigoAcessoController,
                            label: 'Código de Acesso',
                            icon: Icons.lock_outline,
                            hint: 'Insira o código de acesso',
                            isPassword: true,
                          ),

                        // Dropdown Série (condicional)
                        if (_selectedRole == UserRole.student)
                          _buildDropdownField<String?>(
                            value: _selectedSerie,
                            label: 'Série/Turma',
                            icon: Icons.school,
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Selecione a série'),
                              ),
                              ..._seriesList.map((serie) {
                                return DropdownMenuItem<String?>(
                                  value: serie,
                                  child: Text(serie.toUpperCase()),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedSerie = value;
                              });
                            },
                          ),

                        SizedBox(height: 24),

                        // Botão de cadastro
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _cadastrar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child:
                                _isLoading
                                    ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      'Cadastrar',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),

                        // Link para login
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 16),
                              children: [
                                TextSpan(
                                  text: 'Já tem uma conta? ',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                TextSpan(
                                  text: 'Entrar',
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }

  // Helper methods
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    // Common container decoration
    final containerDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.white.withOpacity(0.1),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    );

    if (isPassword && controller == _codigoAcessoController) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: controller,
              obscureText: isPassword,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                prefixIcon: Icon(icon, color: AppColors.primaryBlue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                helperText:
                    'Solicite o código de acesso ao administrador do sistema',
                helperStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            if (_registrationAttempts > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Tentativas restantes: ${_maxAttempts - _registrationAttempts}',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      );
    }

    // Default return for all other cases
    return Container(
      decoration: containerDecoration,
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primaryBlue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (value == null) {
            return 'Por favor, selecione uma opção';
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _codigoAcessoController.dispose();
    super.dispose();
  }
}

// Configuração principal do App
class SchoolSystemApp extends StatelessWidget {
  const SchoolSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema Escolar',
      theme: ThemeData(
        primaryColor: AppColors.primaryBlue,
        scaffoldBackgroundColor: AppColors.backgroundGray,
        textTheme: GoogleFonts.interTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: LoginScreen(),
    );
  }
}
