class LogModel {
  final String title;
  final String date;
  final String description;
  final String category; // Kategori catatan: "Pekerjaan", "Pribadi", "Urgent"

  LogModel({
    required this.title,
    required this.date,
    required this.description,
    this.category = 'Pribadi', // Default kategori = "Pribadi" jika tidak diisi
  });

  // Untuk Tugas HOTS: Konversi Map (JSON) ke Object
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: map['title'],
      date: map['date'],
      description: map['description'],
      // Jika data lama tidak punya category, gunakan default 'Pribadi'
      category: map['category'] ?? 'Pribadi',
    );
  }

  // Konversi Object ke Map (JSON) untuk disimpan
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'description': description,
      'category': category,
    };
  }
}
