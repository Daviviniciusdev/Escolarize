import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, teacher, student }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? serie; // Novo campo adicionado

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.serie, // Torna o campo serie opcional
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: UserRole.values.byName(data['role'] ?? 'student'),
      serie: data['serie'], // Adiciona a série ao fromFirestore
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'serie': serie, // Adiciona a série ao toMap
    };
  }
}
