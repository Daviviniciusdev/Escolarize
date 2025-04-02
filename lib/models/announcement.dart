class Announcement {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String createdBy;
  final List<String> targetRoles; // ['all', 'student', 'teacher']

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.createdBy,
    required this.targetRoles,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'targetRoles': targetRoles,
    };
  }

  factory Announcement.fromMap(String id, Map<String, dynamic> map) {
    return Announcement(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      createdBy: map['createdBy'] ?? '',
      targetRoles: List<String>.from(map['targetRoles'] ?? []),
    );
  }
}
