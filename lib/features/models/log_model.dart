import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  final ObjectId? id; // Wajib untuk penanda unik di MongoDB
  final String title;
  final String date;
  final String description;
  final String category;

  LogModel({
    this.id, // Jangan lupa tambahkan ini di constructor
    required this.title,
    required this.date,
    required this.description,
    this.category = 'Pribadi',
  });

  // [REVERT] Membongkar "Kardus" (BSON/Map) dari Cloud
  factory LogModel.fromMap(Map<String, dynamic> map) {
    ObjectId? parseId;
    final rawId = map['_id'];
    if (rawId is ObjectId) {
      parseId = rawId;
    } else if (rawId is String) {
      try {
        parseId = ObjectId.fromHexString(rawId);
      } catch (e) {
        parseId = null; // Jika parsing gagal, biarkan parseId tetap null
      }
    }

    return LogModel(
      id: parseId, // Menarik ID dari database
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Pribadi',
    );
  }

  // [CONVERT] Memasukkan data ke "Kardus" (BSON/Map) untuk dikirim ke Cloud
  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(), // Buat ID otomatis jika data baru
      'title': title,
      'date': date,
      'description': description,
      'category': category,
    };
  }
}
