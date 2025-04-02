// ignore_for_file: library_private_types_in_public_api

import 'package:Escolarize/models/announcement.dart';
import 'package:Escolarize/models/user_model.dart';
import 'package:Escolarize/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  final UserModel adminUser;

  const AdminAnnouncementsScreen({super.key, required this.adminUser});

  @override
  _AdminAnnouncementsScreenState createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final Set<String> _selectedRoles = {'all'};

  void _showCreateAnnouncementDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.announcement, color: AppColors.primaryBlue),
                SizedBox(width: 12),
                Text(
                  'Novo Comunicado',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Container(
                width: double.maxFinite,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Título',
                          labelStyle: TextStyle(color: AppColors.primaryBlue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primaryBlue,
                              width: 2,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.title,
                            color: AppColors.primaryBlue,
                          ),
                          hintText: 'Ex: Reunião de Pais',
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? 'Campo obrigatório'
                                    : null,
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          labelText: 'Mensagem',
                          labelStyle: TextStyle(color: AppColors.primaryBlue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primaryBlue,
                              width: 2,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.message,
                            color: AppColors.primaryBlue,
                          ),
                          hintText: 'Digite sua mensagem aqui...',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        maxLines: 5,
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? 'Campo obrigatório'
                                    : null,
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    color: AppColors.primaryBlue,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Destinatários',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatefulBuilder(
                              builder:
                                  (context, setState) => Column(
                                    children: [
                                      _buildRoleCheckbox(
                                        'Todos',
                                        'all',
                                        setState,
                                      ),
                                      _buildRoleCheckbox(
                                        'Alunos',
                                        'student',
                                        setState,
                                      ),
                                      _buildRoleCheckbox(
                                        'Professores',
                                        'teacher',
                                        setState,
                                      ),
                                    ],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _createAnnouncement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Enviar',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildRoleCheckbox(String label, String role, StateSetter setState) {
    return CheckboxListTile(
      title: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800]),
      ),
      value: _selectedRoles.contains(role),
      activeColor: AppColors.primaryBlue,
      checkColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 12),
      dense: true,
      onChanged: (value) {
        setState(() {
          if (role == 'all') {
            if (value ?? false) {
              _selectedRoles.clear();
              _selectedRoles.add('all');
            }
          } else {
            if (value ?? false) {
              _selectedRoles.remove('all');
              _selectedRoles.add(role);
            } else {
              _selectedRoles.remove(role);
            }
          }
        });
      },
    );
  }

  Future<void> _createAnnouncement() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final announcement = Announcement(
          id: '',
          title: _titleController.text,
          message: _messageController.text,
          createdAt: DateTime.now(),
          createdBy: widget.adminUser.id,
          targetRoles: _selectedRoles.toList(),
        );

        await FirebaseFirestore.instance
            .collection('announcements')
            .add(announcement.toMap());

        Navigator.pop(context);
        _titleController.clear();
        _messageController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Comunicado enviado com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar comunicado: $e')),
        );
      }
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
          'Comunicados',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Header with curved bottom
          Container(
            padding: EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
          ),
          // Announcements List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('announcements')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState();
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                final announcements = snapshot.data?.docs ?? [];

                if (announcements.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final data =
                        announcements[index].data() as Map<String, dynamic>;
                    final announcement = Announcement.fromMap(
                      announcements[index].id,
                      data,
                    );

                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.announcement,
                                  color: AppColors.primaryBlue,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    announcement.title,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red[300],
                                  ),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('announcements')
                                        .doc(announcement.id)
                                        .delete();
                                  },
                                ),
                              ],
                            ),
                            Divider(height: 24),
                            Text(
                              announcement.message,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      _getTargetText(announcement.targetRoles),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      _formatDate(announcement.createdAt),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateAnnouncementDialog,
        backgroundColor: AppColors.primaryBlue,
        icon: Icon(Icons.add),
        label: Text('Novo Comunicado'),
      ),
    );
  }

  String _getTargetText(List<String> roles) {
    if (roles.contains('all')) return 'Todos';
    return roles
        .map((role) => role == 'student' ? 'Alunos' : 'Professores')
        .join(', ');
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.announcement_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Nenhum comunicado ainda',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          SizedBox(height: 16),
          Text(
            'Erro ao carregar comunicados',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.red[300]),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
