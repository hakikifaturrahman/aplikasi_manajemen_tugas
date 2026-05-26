/**
 * Model Data Task untuk memetakan informasi daftar tugas/todo item
 */
class Task {
  final int id;
  final String title;
  final String description;
  final DateTime deadline;
  final String status; // 'Pending', 'Progress', 'Done'
  final int categoryId;
  final String categoryName; // Menyimpan nama kategori (di-resolve lewat JOIN SQL)
  final int userId;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.status,
    required this.categoryId,
    required this.categoryName,
    required this.userId,
  });

  // Factory constructor untuk mengonversi data JSON (Map) dari API ke objek Task
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline']) 
          : DateTime.now(),
      status: json['status'] ?? 'Pending',
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      userId: json['user_id'] ?? 0,
    );
  }

  // Mengonversi objek Task kembali menjadi Map JSON sebelum dikirim ke API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      // Mengubah objek DateTime menjadi string tanggal berformat yyyy-MM-dd
      'deadline': deadline.toIso8601String().substring(0, 10),
      'status': status,
      'category_id': categoryId,
    };
  }
}
