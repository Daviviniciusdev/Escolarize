// ignore_for_file: library_private_types_in_public_api, non_constant_identifier_names, avoid_types_as_parameter_names, deprecated_member_use, unnecessary_to_list_in_spreads

import 'package:Escolarize/models/user_model.dart';
import 'package:Escolarize/screens/admin/admin_announcement.dart';
import 'package:Escolarize/screens/admin/admin_attendance_screen.dart';
import 'package:Escolarize/screens/admin/admin_class_management.dart';
import 'package:Escolarize/screens/admin/admin_profile_screen.dart';
import 'package:Escolarize/screens/admin/admin_student_management.dart';
import 'package:Escolarize/screens/admin/admin_user_management.dart';
import 'package:Escolarize/screens/login_pages/login_screen.dart';
import 'package:Escolarize/utils/app_colors.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboard extends StatefulWidget {
  final UserModel user;

  const AdminDashboard({super.key, required this.user});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  String _getFirstName(String fullName) {
    List<String> names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0]} ${names[1]}';
    }
    return names[0]; // Retorna apenas o primeiro nome se não houver sobrenome
  }

  // Lista de telas para navegação
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Inicializar a lista de telas
    _screens = [
      _buildDashboardHome(),
      AdminUserManagementScreen(adminUser: widget.user),
      _buildSettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Tela inicial do dashboard
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
                        'Painel da Direção',
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
            child: Icon(
              Icons.admin_panel_settings,
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
                  _getFirstName(widget.user.name),
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
        children: List.generate(
          6,
          (index) => AnimationConfiguration.staggeredGrid(
            position: index,
            duration: Duration(milliseconds: 375),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildAnimatedCard(_getDashboardItem(index)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  DashboardItem _getDashboardItem(int index) {
    final items = [
      DashboardItem(
        icon: Icons.people,
        label: 'Gerenciar\nAlunos',
        color: Color(0xFF4CAF50),
        onTap: () => _onItemTapped(1),
      ),
      DashboardItem(
        icon: Icons.fact_check,
        label: 'Frequência',
        color: Color(0xFF2196F3),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AdminAttendanceScreen(adminUser: widget.user),
              ),
            ),
      ),
      DashboardItem(
        icon: Icons.school,
        label: 'Gerenciar\nTurmas',
        color: Color(0xFF9C27B0),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AdminClassManagement(adminUser: widget.user),
              ),
            ),
      ),
      DashboardItem(
        icon: Icons.announcement,
        label: 'Comunicados',
        color: Color(0xFFE91E63),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        AdminAnnouncementsScreen(adminUser: widget.user),
              ),
            ),
      ),
      DashboardItem(
        icon: Icons.supervised_user_circle,
        label: 'Relatório\nDe alunos',
        color: Color(0xFFFF9800),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminReportScreen(adminUser: widget.user),
              ),
            ),
      ),
      DashboardItem(
        icon: Icons.settings,
        label: 'Configurações',
        color: Color(0xFF607D8B),
        onTap: () => _onItemTapped(2),
      ),
    ];

    return items[index];
  }

  Widget _buildAnimatedCard(DashboardItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: item.color.withOpacity(0.2),
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
                  color: item.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 32, color: item.color),
              ),
              SizedBox(height: 12.0),
              Text(
                item.label,
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
    );
  }

  Widget _buildSettingsScreen() {
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
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'Configurações',
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.admin_panel_settings,
                              size: 50,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            widget.user.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                    children: [
                      _buildSettingsCard(
                        title: 'Conta',
                        items: [
                          SettingsItem(
                            icon: Icons.person,
                            title: 'Perfil',
                            subtitle: 'Informações pessoais',
                            color: Color(0xFF4CAF50),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          AdminProfileScreen(user: widget.user),
                                ),
                              );
                            },
                          ),
                          SettingsItem(
                            icon: Icons.security,
                            title: 'Segurança',
                            subtitle: 'Senha e privacidade',
                            color: Color(0xFF2196F3),
                            onTap: () {
                              // Implement security settings
                              _desenvolvimento();
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildSettingsCard(
                        title: 'Preferências',
                        items: [
                          SettingsItem(
                            icon: Icons.notifications,
                            title: 'Notificações',
                            subtitle: 'Configurar alertas',
                            color: Color(0xFF9C27B0),
                            onTap: () {
                              // Implement notifications settings
                              _desenvolvimento();
                            },
                          ),
                          SettingsItem(
                            icon: Icons.language,
                            title: 'Idioma',
                            subtitle: 'Português (Brasil)',
                            color: Color(0xFFFF9800),
                            onTap: () {
                              // Implement language settings
                              _desenvolvimento();
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildLogoutButton(),
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

  void _desenvolvimento() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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

  Widget _buildSettingsCard({
    required String title,
    required List<SettingsItem> items,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(height: 16),
            ...items
                .map(
                  (item) => Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.icon, color: item.color),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          item.subtitle,
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                        onTap: item.onTap,
                      ),
                      if (item != items.last) Divider(height: 1),
                    ],
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: () async {
          try {
            await FirebaseAuth.instance.signOut();
            if (!mounted) return;

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginScreen()),
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
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.logout, color: Colors.red),
        ),
        title: Text(
          'Sair',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuários'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryBlue,
        onTap: _onItemTapped,
      ),
    );
  }
}

class SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class DashboardItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  DashboardItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
