// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Escolarize/utils/app_colors.dart';

class AnnouncementsWidget extends StatelessWidget {
  final String userRole;

  const AnnouncementsWidget({Key? key, required this.userRole})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('announcements')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar avisos'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final announcements =
            snapshot.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final targetRoles = List<String>.from(data['targetRoles'] ?? []);
              return targetRoles.contains('all') ||
                  targetRoles.contains(userRole.toLowerCase());
            }).toList() ??
            [];

        if (announcements.isEmpty) {
          return Center(
            child: Text(
              'Nenhum aviso disponível',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final data = announcements[index].data() as Map<String, dynamic>;
            final createdAt = DateTime.parse(data['createdAt']);

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ExpansionTile(
                leading: Icon(Icons.announcement, color: AppColors.primaryBlue),
                title: Text(
                  data['title'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: TextStyle(fontSize: 12),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(data['message']),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
