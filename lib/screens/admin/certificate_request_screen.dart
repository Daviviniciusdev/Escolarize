// ignore_for_file: unused_local_variable, unused_field

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:Escolarize/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';

class CertificateRequestsScreen extends StatefulWidget {
  const CertificateRequestsScreen({Key? key}) : super(key: key);

  @override
  _CertificateRequestsScreenState createState() =>
      _CertificateRequestsScreenState();
}

class _CertificateRequestsScreenState extends State<CertificateRequestsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late TabController _tabController;
  bool _isLoading = false;

  String _filterStatus = 'all';
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Solicitações de Atestados',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Pendentes'),
            Tab(text: 'Em Processo'),
            Tab(text: 'Concluídos'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and filter section
          _buildSearchAndFilterBar(),

          // Tab view content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsList('pending'),
                _buildRequestsList('processing'),
                _buildRequestsList('completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou turma',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(String tabStatus) {
    // Determine the Firestore status values to query based on tab
    List<String> statusValues;
    if (tabStatus == 'pending') {
      statusValues = ['pending'];
    } else if (tabStatus == 'processing') {
      statusValues = ['processing'];
    } else {
      statusValues = ['approved', 'rejected'];
    }

    return StreamBuilder<QuerySnapshot>(
      // Temporary query without ordering while index builds
      stream: _firestore
          .collection('certificate_requests')
          .where('status', whereIn: statusValues)
          // Comment out the orderBy until index is built
          // .orderBy('requestDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erro ao carregar solicitações: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(tabStatus);
        }

        // Filter by search query if needed
        var filteredDocs = snapshot.data!.docs;
        if (_searchQuery.isNotEmpty) {
          filteredDocs = filteredDocs.where((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String fullName = (data['fullName'] ?? '').toLowerCase();
            String className = (data['class'] ?? '').toLowerCase();

            return fullName.contains(_searchQuery) ||
                className.contains(_searchQuery);
          }).toList();

          if (filteredDocs.isEmpty) {
            return Center(
              child: Text(
                'Nenhuma solicitação encontrada para "$_searchQuery"',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            );
          }
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = filteredDocs[index];
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            return _buildRequestCard(data, doc.id, tabStatus);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String tabStatus) {
    String message;
    IconData icon;

    if (tabStatus == 'pending') {
      message = 'Nenhuma solicitação pendente';
      icon = Icons.inbox;
    } else if (tabStatus == 'processing') {
      message = 'Nenhuma solicitação em processamento';
      icon = Icons.hourglass_empty;
    } else {
      message = 'Nenhuma solicitação concluída';
      icon = Icons.assignment_turned_in;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
      Map<String, dynamic> data, String docId, String tabStatus) {
    String status = data['status'] ?? 'pending';
    Timestamp requestDate = data['requestDate'] as Timestamp;
    String formattedDate =
        DateFormat('dd/MM/yyyy - HH:mm').format(requestDate.toDate());

    Color cardColor;
    switch (status) {
      case 'pending':
        cardColor = Colors.blue[50]!;
        break;
      case 'processing':
        cardColor = Colors.orange[50]!;
        break;
      case 'approved':
        cardColor = Colors.green[50]!;
        break;
      case 'rejected':
        cardColor = Colors.red[50]!;
        break;
      default:
        cardColor = Colors.grey[50]!;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardColor,
      child: ExpansionTile(
        title: Text(
          data['fullName'] ?? 'Nome não informado',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              'Turma: ${data['class'] ?? 'Não informada'}',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              'Solicitado em: $formattedDate',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
        trailing: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(Icons.arrow_drop_down),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        childrenPadding: EdgeInsets.all(16),
        children: [
          // Detailed student info
          _buildInfoRow('Nome do Pai', data['fatherName'] ?? ''),
          _buildInfoRow('Nome da Mãe', data['motherName'] ?? ''),
          _buildInfoRow('Endereço', data['address'] ?? ''),
          _buildInfoRow('Naturalidade', data['birthplace'] ?? ''),
          _buildInfoRow(
              'Data de Nascimento',
              data['birthDate'] != null
                  ? DateFormat('dd/MM/yyyy')
                      .format((data['birthDate'] as Timestamp).toDate())
                  : 'Não informada'),
          _buildInfoRow('E-mail', data['studentEmail'] ?? ''),

          SizedBox(height: 16),

          // Admin notes
          TextFormField(
            initialValue: data['adminNotes'] ?? '',
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Observações',
              border: OutlineInputBorder(),
              hintText: 'Adicione observações sobre esta solicitação',
            ),
            onChanged: (value) {
              // Update admin notes in Firestore
              _firestore
                  .collection('certificate_requests')
                  .doc(docId)
                  .update({'adminNotes': value});
            },
          ),

          SizedBox(height: 20),

          // Action buttons based on status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _buildActionButtons(data, docId, status),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(
      Map<String, dynamic> data, String docId, String status) {
    List<Widget> buttons = [];

    if (status == 'pending') {
      // Pending status actions
      buttons = [
        ElevatedButton.icon(
          onPressed: () => _updateStatus(docId, 'processing'),
          icon: Icon(Icons.play_arrow),
          label: Text('Iniciar Processamento'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showRejectDialog(docId),
          icon: Icon(Icons.cancel),
          label: Text('Rejeitar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ];
    } else if (status == 'processing') {
      // Processing status actions
      buttons = [
        ElevatedButton.icon(
          onPressed: () => _uploadCertificate(docId, data),
          icon: Icon(Icons.upload_file),
          label: Text('Enviar Atestado'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showRejectDialog(docId),
          icon: Icon(Icons.cancel),
          label: Text('Rejeitar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ];
    } else if (status == 'approved' && data['certificateUrl'] != null) {
      // Approved with certificate
      buttons = [
        ElevatedButton.icon(
          onPressed: () => _viewCertificate(data['certificateUrl']),
          icon: Icon(Icons.visibility),
          label: Text('Ver Atestado'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _uploadCertificate(docId, data),
          icon: Icon(Icons.update),
          label: Text('Atualizar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
          ),
        ),
      ];
    }

    return buttons;
  }

  Future<void> _updateStatus(String docId, String newStatus) async {
    await _firestore
        .collection('certificate_requests')
        .doc(docId)
        .update({'status': newStatus});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status atualizado com sucesso'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _showRejectDialog(String docId) async {
    String reason = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rejeitar Solicitação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Informe o motivo da rejeição:'),
            SizedBox(height: 16),
            TextFormField(
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Motivo da rejeição',
              ),
              onChanged: (value) {
                reason = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _firestore.collection('certificate_requests').doc(docId).update({
                'status': 'rejected',
                'adminNotes': reason,
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Solicitação rejeitada'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Rejeitar'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadCertificate(
      String docId, Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Pick file using file_selector
      final XTypeGroup typeGroup = XTypeGroup(
        label: 'Documents',
        extensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Read file bytes for email attachment
      final bytes = await file.readAsBytes();
      final fileName = file.name;

      // Configure email server (substitua com suas credenciais)
      String username = 'davivinicius045@gmail.com';
      String password = 'vbty dmci puuu vxxc';
      final smtpServer = gmail(username, password);

      final studentEmail = data['studentEmail'];
      final studentName = data['fullName'];

      // Create email message with attachment
      final message = Message()
        ..from = Address(username, 'Sistema Escolarize')
        ..recipients.add(studentEmail)
        ..subject = 'EBAAA Seu Atestado Escolar Chegou!'
        ..html = '''
          <h1>Atestado Escolar</h1>
          <p>Olá $studentName,</p>
          <p>Seu atestado escolar foi aprovado e está em anexo neste e-mail.</p>
          <p>Atenciosamente,<br>Equipe Escolar Antonio Lomanto junior</p>
        '''
        ..attachments = [
          FileAttachment(File(file.path))
            ..location = Location.attachment
            ..fileName = fileName
        ];

      // Send email
      final sendReport = await send(message, smtpServer);
      print('Email enviado: ${sendReport.toString()}');
      await _firestore.collection('certificate_requests').doc(docId).update({
        'status': 'approved',
        'certificateEmailSent': true,
        'certificateName': fileName,
        'approvalDate': Timestamp.now(),
        'sentMethod': 'email'
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Atestado enviado por e-mail com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar atestado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _viewCertificate(String url) async {
    if (url.isEmpty) return;

    Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível abrir o documento'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Não informado' : value,
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
