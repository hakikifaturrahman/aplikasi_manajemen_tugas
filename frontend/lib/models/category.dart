/**
 * Model Data Category untuk memetakan kategori tugas dari database
 */
class Category {
  final int id;
  final String categoryName;
  final int taskCount; // Menyimpan statistik jumlah task di bawah kategori ini

  Category({
    required this.id,
    required this.categoryName,
    this.taskCount = 0,
  });

  // Factory constructor untuk mengonversi data JSON (Map) dari API ke objek Category
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      categoryName: json['category_name'] ?? '',
      taskCount: json['task_count'] != null 
          ? int.parse(json['task_count'].toString()) 
          : 0,
    );
  }

  // Mengonversi objek Category kembali menjadi Map JSON sebelum dikirim ke API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_name': categoryName,
    };
  }
}
