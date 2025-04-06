// ignore_for_file: library_private_types_in_public_api, unused_element, avoid_print, unused_field

import 'package:Escolarize/screens/student/request_certificate_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Escolarize/models/user_model.dart';
import 'package:Escolarize/screens/student/Schedule_Screen.dart';
import 'package:Escolarize/screens/admin/announcentement_widget.dart';
import 'package:Escolarize/screens/login_pages/login_screen.dart';
import 'package:Escolarize/screens/student/details_performace.dart';
import 'package:Escolarize/screens/student/student_screen_notes.dart';
import 'package:Escolarize/utils/app_colors.dart';

class StudentDashboard extends StatefulWidget {
  final UserModel user;

  const StudentDashboard({super.key, required this.user});

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasAnnouncements = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add this method to check for announcements
  void _checkForAnnouncements() {
    FirebaseFirestore.instance
        .collection('announcements')
        .where('targetRoles', arrayContainsAny: ['all', 'student'])
        .get()
        .then((snapshot) {
          if (mounted) {
            setState(() {
              _hasAnnouncements = snapshot.docs.isNotEmpty;
            });
          }
        });
  }

  late List<Widget> _screens;
  @override
  void initState() {
    super.initState();
    _checkForAnnouncements();
    _screens = [
      _buildDashboardHome(),
      AlunoNotasScreen(
        alunoId: widget.user.id,
        alunoNome: widget.user.name,
        turma: widget.user.serie,
      ),
      _buildProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _verNotas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlunoNotasScreen(
          alunoId: widget.user.id, // ID do aluno logado
          alunoNome: widget.user.name, // Nome do aluno logado
          turma: widget.user.serie, // Turma do aluno (se disponível)
        ),
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
            colors: [AppColors.primaryBlue, Colors.white],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                automaticallyImplyLeading: false,
                centerTitle: true,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'Área do Aluno',
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
                      _buildAnnouncementsSection(), // Announcements section
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .snapshots(),
      builder: (context, snapshot) {
        String nomeAluno = snapshot.hasData && snapshot.data!.exists
            ? (snapshot.data!.data() as Map<String, dynamic>)['nome'] ?? 'Aluno'
            : widget.user.name;

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
                child: Icon(
                  Icons.school,
                  size: 32,
                  color: AppColors.primaryBlue,
                ),
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
                      nomeAluno,
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
      },
    );
  }

  // Update the StreamBuilder in _buildAnnouncementsSection()
  Widget _buildAnnouncementsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('announcements').where(
          'targetRoles',
          arrayContainsAny: ['all', 'student']).snapshots(),
      builder: (context, snapshot) {
        bool hasAnnouncements =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showAnnouncementsBottomSheet(context),
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.announcement,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Avisos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Stack(
                            children: [
                              Icon(
                                Icons.notifications,
                                color: hasAnnouncements
                                    ? AppColors.primaryBlue
                                    : Colors.grey[400],
                                size: 24,
                              ),
                              if (hasAnnouncements)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.primaryBlue,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 8),
          Text(message, style: TextStyle(color: Colors.red)),
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
            icon: Icons.assignment,
            label: 'Minhas\nNotas',
            color: Color(0xFF4CAF50),
            onTap: _verNotas,
          ),
          _buildAnimatedGridItem(
            icon: Icons.schedule,
            label: 'Horários',
            color: Color(0xFF2196F3),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ScheduleScreen(turma: widget.user.serie ?? ''),
              ),
            ),
          ),
          _buildAnimatedGridItem(
            icon: Icons.book,
            label: 'Material\nDe estudo',
            color: Color.fromARGB(255, 0, 26, 255),
            onTap: () {
              _desenvolvimento();
            },
          ),
          _buildAnimatedGridItem(
            icon: Icons.align_vertical_bottom,
            label: 'Desempenho\nEscolar',
            color: Color.fromARGB(255, 124, 19, 145),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailedPerformanceScreen(
                  studentId: widget.user.id,
                  studentName: widget.user.name,
                ),
              ),
            ),
          ),
          _buildAnimatedGridItem(
            icon: Icons.person,
            label: 'Meu\nPerfil',
            color: Color(0xFF607D8B),
            onTap: () => _onItemTapped(2),
          ),
          _buildAnimatedGridItem(
            icon: Icons.add_circle,
            label: 'Pedir\nAtestado',
            color: Color.fromARGB(255, 229, 255, 0),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      RequestCertificateScreen(user: widget.user),
                ),
              );
            },
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

  Widget _buildDashboardCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: AppColors.primaryBlue),
              SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnnouncementsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Avisos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(child: AnnouncementsWidget(userRole: 'student')),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, String>> _getTeacherNames(List<String> materias) async {
    Map<String, String> materiaProfessor = {};

    try {
      // Buscar todos os professores da coleção users
      QuerySnapshot teachersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .get();

      print('Encontrados ${teachersQuery.docs.length} professores'); // Debug

      for (var teacherDoc in teachersQuery.docs) {
        var teacherData = teacherDoc.data() as Map<String, dynamic>;
        String teacherId = teacherDoc.id;
        String teacherName = teacherData['name'] ?? 'Professor não atribuído';

        print('Professor: $teacherName, ID: $teacherId'); // Debug

        // Buscar matérias do professor na coleção teachers
        DocumentSnapshot teacherMateriasDoc = await FirebaseFirestore.instance
            .collection('teachers')
            .doc(teacherId)
            .get();

        if (teacherMateriasDoc.exists) {
          var materiasData = teacherMateriasDoc.data() as Map<String, dynamic>;
          List<String> teacherMaterias = List<String>.from(
            materiasData['materias'] ?? [],
          );

          print(
            'Matérias do professor $teacherName: $teacherMaterias',
          ); // Debug

          for (var materia in teacherMaterias) {
            if (materias.contains(materia)) {
              materiaProfessor[materia] = teacherName;
              print('Associando $materia ao professor $teacherName'); // Debug
            }
          }
        }
      }
    } catch (e) {
      print('Erro ao buscar professores: $e'); // Debug
    }

    print('Mapa final de matérias e professores: $materiaProfessor'); // Debug
    return materiaProfessor;
  }

  Widget _buildGradeCard(String subject, List<double> grades) {
    double average = grades.reduce((a, b) => a + b) / grades.length;
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        title: Text(subject),
        subtitle: Text('Notas: ${grades.join(", ")}'),
        trailing: Text(
          'Média: ${average.toStringAsFixed(1)}',
          style: TextStyle(
            color: average >= 7 ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryBlue, Colors.purple.withOpacity(0.8)],
            stops: [0.2, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header with animated profile image
                Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Efeito de brilho animado
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.withOpacity(0.5),
                                  Colors.purple.withOpacity(0.5),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          // Imagem de perfil
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.blue, Colors.purple],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 58,
                                backgroundColor:
                                    AppColors.primaryBlue.withOpacity(0.9),
                                child: Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Botão de edição
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // Implementar edição de foto
                                  _desenvolvimento();
                                },
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        widget.user.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Turma: ${widget.user.serie ?? "Não definida"}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Cards de informações
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    child: Column(
                      children: [
                        _buildInfoCard(
                          title: 'Informações Pessoais',
                          icon: Icons.person_outline,
                          children: [
                            _buildInfoRow('Email', widget.user.email),
                            _buildInfoRow('Matrícula', widget.user.id),
                            _buildInfoRow(
                              'Status',
                              'Ativo',
                              color: Colors.green,
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildPerformanceCard(),
                        SizedBox(height: 16),
                        _buildSettingsCard(),
                        SizedBox(height: 24),
                        _buildLogoutButton(),
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

  Widget _buildPerformanceCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getStudentPerformance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ??
            {
              'mediaGeral': '0.0',
              'frequencia': '0',
              'atividadesPendentes': '0',
            };

        return _buildInfoCard(
          title: 'Desempenho',
          icon: Icons.bar_chart,
          children: [
            _buildPerformanceRow(
              'Frequência',
              '${data['frequencia']}%',
              double.parse(data['frequencia']),
            ),
            _buildPerformanceRow(
              'Média Geral',
              data['mediaGeral'],
              double.parse(data['mediaGeral']) * 10,
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getStudentPerformance() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      // Buscar notas do aluno
      final notasDoc = await FirebaseFirestore.instance
          .collection('notas')
          .doc(userId)
          .get();

      // Calcular média geral considerando todos os ciclos
      double mediaGeral = 0.0;
      int totalNotas = 0;

      if (notasDoc.exists) {
        final notasData = notasDoc.data() as Map<String, dynamic>;
        double somaNotas = 0.0;

        // Iterar sobre cada ciclo
        for (var ciclo in ['ciclo1', 'ciclo2', 'ciclo3']) {
          final cicloData = notasData[ciclo] as Map<String, dynamic>? ?? {};

          cicloData.forEach((_, nota) {
            if (nota is num) {
              somaNotas += nota.toDouble();
              totalNotas++;
            }
          });
        }

        if (totalNotas > 0) {
          mediaGeral = somaNotas / totalNotas;
        }
      }

      // Buscar registros de frequência do aluno
      final frequenciaQuery = await FirebaseFirestore.instance
          .collection('frequencia')
          .where('presencas.$userId', isEqualTo: true)
          .get();

      int aulasPresente = frequenciaQuery.docs.length;

      // Buscar total de aulas da turma
      final turmaRef = await FirebaseFirestore.instance
          .collection('frequencia')
          .where('turma', isEqualTo: widget.user.serie)
          .get();

      int totalAulas = turmaRef.docs.length;

      // Calcular porcentagem de frequência
      double frequencia =
          totalAulas > 0 ? (aulasPresente / totalAulas) * 100 : 0.0;

      return {
        'mediaGeral': mediaGeral.toStringAsFixed(1),
        'frequencia': frequencia.toStringAsFixed(0),
        'totalNotas': totalNotas.toString(),
        'totalAulas': totalAulas.toString(),
      };
    } catch (e) {
      print('Erro ao buscar desempenho: $e');
      return {
        'mediaGeral': '0.0',
        'frequencia': '0',
        'totalNotas': '0',
        'totalAulas': '0',
      };
    }
  }

  // Add this new method to your _StudentDashboardState class

  Color _getGradeColor(double grade) {
    if (grade >= 7) return Colors.green;
    if (grade >= 5) return Colors.orange;
    return Colors.red;
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildPerformanceRow(String label, String value, double percentage) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              Text(
                value,
                style: TextStyle(
                  color: _getStatusColor(percentage),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStatusColor(percentage),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildSettingsCard() {
    return _buildInfoCard(
      title: 'Configurações',
      icon: Icons.settings_outlined,
      children: [
        _buildAnimatedSettingsTile(
          'Notificações',
          Icons.notifications_outlined,
          onTap: () {
            _desenvolvimento();
          },
        ),
        _buildAnimatedSettingsTile(
          'Privacidade',
          Icons.lock_outline,
          onTap: () {
            _desenvolvimento();
          },
        ),
        _buildAnimatedSettingsTile(
          'Alterar Senha',
          Icons.key_outlined,
          onTap: () {
            _desenvolvimento();
          },
        ),
      ],
    );
  }

  Widget _buildAnimatedSettingsTile(
    String title,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _handleLogout(),
        icon: Icon(Icons.exit_to_app),
        label: Text('Sair da Conta'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    if (!mounted) return;

    try {
      bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Confirmar Saída'),
              content: Text('Deseja realmente sair da sua conta?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Text('Sair'),
                ),
              ],
            ),
          ) ??
          false;

      if (confirm && mounted) {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao fazer logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        initiallyExpanded: true,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color ?? Colors.black87, // Use provided color or default
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    String title,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryBlue),
      title: Text(title, style: TextStyle(fontSize: 16, color: Colors.black87)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Notas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryBlue,
        onTap: _onItemTapped,
      ),
    );
  }

  void _desenvolvimento() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Wrap(
          children: [
            Icon(
              Icons.construction,
              color: AppColors.primaryBlue,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'Em Desenvolvimento',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Esta funcionalidade está em desenvolvimento e estará disponível em breve!',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 16),
              Icon(Icons.engineering, size: 48, color: Colors.grey[400]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK, Entendi',
              style: GoogleFonts.poppins(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
