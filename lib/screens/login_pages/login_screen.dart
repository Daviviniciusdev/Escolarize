// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, deprecated_member_use, depend_on_referenced_packages, unused_field

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:Escolarize/models/user_model.dart';
import 'package:Escolarize/screens/admin/admin_dashboard.dart';
import 'package:Escolarize/screens/login_pages/register_screen.dart';
import 'package:Escolarize/screens/student/student_dashboard.dart';
import 'package:Escolarize/screens/teacher/teacher_dashboard.dart';
import 'package:Escolarize/utils/app_colors.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  late AnimationController _shakeController;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isBiometricAvailable = false;
  int _loginAttempts = 0;
  DateTime? _lockoutEnd;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _checkBiometrics();
    _checkPreviousSession();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _lockoutTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    if (!mounted) return;

    try {
      final auth = LocalAuthentication();

      // Verifica se o hardware suporta biometria
      final canCheckBiometrics = await auth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        setState(() => _isBiometricAvailable = false);
        return;
      }

      // Verifica quais tipos de biometria estão disponíveis
      final availableBiometrics = await auth.getAvailableBiometrics();

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

  Future<void> _checkPreviousSession() async {
    if (!mounted) return;

    try {
      final email = await _storage.read(key: 'user_email');
      final password = await _storage.read(key: 'user_password');

      if (mounted && email != null && password != null) {
        setState(() {
          _emailController.text = email;
          // Don't set password controller for security
        });
      }
    } catch (e) {
      print('Error checking previous session: $e');
    }
  }

  Future<void> _showBiometricPrompt() async {
    if (!mounted) return;

    try {
      // Primeiro verifica se há credenciais salvas
      final email = await _storage.read(key: 'user_email');
      final password = await _storage.read(key: 'user_password');

      if (email == null || password == null) {
        _showError(
          'Faça login manualmente primeiro para configurar a biometria',
        );
        return;
      }

      // Configura as opções de autenticação
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      final List<BiometricType> availableBiometrics =
          await auth.getAvailableBiometrics();

      if (!canCheck || availableBiometrics.isEmpty) {
        _showError('Biometria não está disponível neste dispositivo');
        return;
      }

      // Tenta autenticar
      final authenticated = await auth.authenticate(
        localizedReason: 'Por favor, use sua digital para fazer login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly:
              false, // Alterado para false para permitir PIN como fallback
          useErrorDialogs: true,
        ),
      );

      if (!mounted) return;

      if (authenticated) {
        setState(() {
          _emailController.text = email;
          _passwordController.text = password;
        });

        // Tenta fazer login com as credenciais salvas
        await _login();
      }
    } on PlatformException catch (e) {
      if (mounted) {
        switch (e.code) {
          case 'NotAvailable':
            _showError('Biometria não está disponível');
            break;
          case 'NotEnrolled':
            _showError('Nenhuma digital cadastrada no dispositivo');
            break;
          case 'LockedOut':
            _showError('Muitas tentativas. Tente novamente mais tarde');
            break;
          case 'PermanentlyLockedOut':
            _showError('Biometria bloqueada. Use sua senha');
            break;
          default:
            _showError('Erro na autenticação biométrica: ${e.message}');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro inesperado: $e');
      }
    }
  }

  Future<void> _storeCredentials(String email, String password) async {
    try {
      await _storage.write(key: 'user_email', value: email);
      await _storage.write(key: 'user_password', value: password);
    } catch (e) {
      print('Error storing credentials: $e');
    }
  }

  Future<void> _login() async {
    if (!mounted) return; // Early return if widget is unmounted

    if (_lockoutEnd != null && DateTime.now().isBefore(_lockoutEnd!)) {
      final remaining = _lockoutEnd!.difference(DateTime.now());
      _showError(
        'Muitas tentativas. Tente novamente em ${remaining.inMinutes} minutos.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _shakeController.forward(from: 0.0);
      return;
    }

    if (!mounted) return; // Check again before setState
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (!mounted) return; // Check mounted before proceeding

      // Store credentials securely
      await _storeCredentials(email, password);

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

      // Log login attempt
      await _logLoginAttempt(userCredential.user!.uid, true);

      if (!mounted) return; // Check mounted before proceeding

      final user = UserModel.fromFirestore(userDoc);

      // Reset attempts after successful login
      _loginAttempts = 0;
      _lockoutEnd = null;
      _lockoutTimer?.cancel();

      if (!mounted) return; // Final mounted check before navigation

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) =>
                  _navigateToDashboard(user),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } on FirebaseAuthException catch (e) {
      _loginAttempts++;
      await _logLoginAttempt(null, false, errorCode: e.code);

      if (!mounted) return; // Check mounted before handling errors

      if (_loginAttempts >= 3) {
        _lockoutEnd = DateTime.now().add(const Duration(minutes: 15));
        _lockoutTimer = Timer(_lockoutEnd!.difference(DateTime.now()), () {
          if (mounted) {
            // Check mounted in timer callback
            setState(() {
              _loginAttempts = 0;
              _lockoutEnd = null;
            });
          }
        });
        _showError(
          'Conta bloqueada por 15 minutos devido a múltiplas tentativas.',
        );
        return;
      }

      String errorMessage = _getErrorMessage(e);
      _showError(errorMessage);
      _shakeController.forward(from: 0.0);
    } catch (e) {
      if (!mounted) return; // Check mounted before showing error
      _showError('Erro inesperado: ${e.toString()}');
      _shakeController.forward(from: 0.0);
    } finally {
      if (mounted) {
        // Check mounted before final setState
        setState(() => _isLoading = false);
      }
    }
  }

  // Update _showError method to handle unmounted state
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _logLoginAttempt(
    String? userId,
    bool success, {
    String? errorCode,
  }) async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      Map<String, dynamic> deviceData = {};

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceData = {
          'device': androidInfo.device,
          'manufacturer': androidInfo.manufacturer,
          'model': androidInfo.model,
          'version': androidInfo.version.release,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceData = {
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'model': iosInfo.model,
        };
      } else {
        deviceData = {'deviceType': 'web/desktop', 'userAgent': 'unknown'};
      }

      await FirebaseFirestore.instance.collection('login_logs').add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'success': success,
        'deviceInfo': deviceData,
        'errorCode': errorCode,
        'attempts': _loginAttempts,
        'ipAddress': await _getIpAddress(),
      });
    } catch (e) {
      // Fallback if device info collection fails
      await FirebaseFirestore.instance.collection('login_logs').add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'success': success,
        'errorCode': errorCode,
        'attempts': _loginAttempts,
      });
    }
  }

  // Add this helper method
  Future<String> _getIpAddress() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      return response.body;
    } catch (e) {
      return 'unknown';
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    // Log the error for debugging
    print('Firebase Auth Error Code: ${e.code}');
    print('Firebase Auth Error Message: ${e.message}');

    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Email ou senha incorretos';
      case 'invalid-credential':
        return 'Email ou senha incorretos';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Usuário desabilitado';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde';
      case 'operation-not-allowed':
        return 'Operação não permitida';
      case 'email-already-in-use':
        return 'Este email já está em uso';
      case 'weak-password':
        return 'A senha é muito fraca';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet';
      case 'invalid-password':
        return 'Senha incorreta';
      default:
        // Log unhandled errors
        print('Unhandled Firebase Error: ${e.code} - ${e.message}');
        return 'Credenciais inválidas';
    }
  }

  void _recuperarSenha() {
    final recuperacaoController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dismissing by tapping outside
      builder:
          (dialogContext) => AlertDialog(
            title: Text(
              'Recuperar Senha',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            content: TextField(
              controller: recuperacaoController,
              decoration: InputDecoration(
                labelText: 'Email de recuperação',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  recuperacaoController.dispose();
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final email = recuperacaoController.text.trim();
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Por favor, insira um email',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                    return;
                  }

                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(
                      email: email,
                    );

                    // Dispose controller before popping dialog
                    recuperacaoController.dispose();
                    Navigator.of(dialogContext).pop();

                    // Show success message using the parent context
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Email de recuperação enviado',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    // Show error message using dialog context
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Erro ao enviar email de recuperação: ${e is FirebaseAuthException ? _getErrorMessage(e) : 'Erro desconhecido'}',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Enviar',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Widget _navigateToDashboard(UserModel user) {
    switch (user.role) {
      case UserRole.admin:
        return AdminDashboard(user: user);
      case UserRole.teacher:
        return TeacherDashboard(user: user);
      case UserRole.student:
        return StudentDashboard(user: user);
    }
  }

  void _goToCadastro() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CadastroScreen()));
  }

  Widget _buildLoginCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo animado
              ShaderMask(
                shaderCallback:
                    (bounds) => LinearGradient(
                      colors: [AppColors.primaryBlue, Colors.purple],
                    ).createShader(bounds),
                child: const Icon(Icons.school, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 24),

              // Título animado
              AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Escolarize',
                    textStyle: GoogleFonts.montserrat(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                    speed: const Duration(milliseconds: 100),
                  ),
                ],
                totalRepeatCount: 1,
              ),
              const SizedBox(height: 40),

              // Campo de email com efeito de elevação
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    hintText: 'Digite seu e-mail',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu email';
                    }
                    final emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Campo de senha com efeito de elevação
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    hintText: 'Digite sua senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira sua senha';
                    }
                    if (value.length < 6) {
                      return 'Senha deve ter no mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _recuperarSenha,
                  child: Text(
                    'Esqueceu a senha?',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botão biométrico (mostrar apenas se disponível)
              if (_isBiometricAvailable)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 15),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Entrar com biometria'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _showBiometricPrompt,
                  ),
                ),

              // Botão de login animado
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          )
                          : const Text(
                            'Entrar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 20),

              // Botão de cadastro
              TextButton(
                onPressed: _goToCadastro,
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16),
                    children: [
                      TextSpan(
                        text: 'Não tem uma conta? ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextSpan(
                        text: 'Criar conta',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final sineValue = sin(4 * pi * _shakeController.value);
          return Transform.translate(
            offset: Offset(sineValue * 10, 0),
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryBlue.withOpacity(0.8), Colors.white],
              stops: const [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildLoginCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
