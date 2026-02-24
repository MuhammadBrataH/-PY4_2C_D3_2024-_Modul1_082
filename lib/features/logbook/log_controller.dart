import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/log_model.dart';

// ===== LSP: Superclass Abstrak =====
// LSP = Liskov Substitution Principle
// "Subclass harus bisa menggantikan Superclass tanpa merusak program"
// Analoginya: .mp3 dan .wav keduanya adalah "Lagu", pemutar musik harus bisa putar keduanya
abstract class BaseLog {
  String get title;
  String get description;
}

// ===== LSP: Subclass - LectureLog =====
// Catatan jenis Kuliah — turunan dari BaseLog
class LectureLog extends BaseLog {
  @override
  final String title;
  @override
  final String description;

  LectureLog({required this.title, required this.description});
}

// ===== LSP: Subclass - TaskLog =====
// Catatan jenis Tugas — turunan dari BaseLog
class TaskLog extends BaseLog {
  @override
  final String title;
  @override
  final String description;

  TaskLog({required this.title, required this.description});
}

// ===== Controller: Mengelola data (CRUD + Persistence) =====
class LogController {
  // ValueNotifier = "kotak data" yang BERTERIAK ke semua pendengarnya saat isinya berubah
  // Jadi UI tidak perlu setState() manual — cukup dengarkan notifier ini
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);

  // Key untuk SharedPreferences (seperti label pada laci penyimpanan)
  static const String _storageKey = 'user_logs_data';

  // Constructor — dipanggil saat LogController pertama kali dibuat
  // Langsung load data dari disk agar catatan lama muncul
  LogController() {
    loadFromDisk();
  }

  // ===== CREATE: Tambah catatan baru =====
  void addLog(String title, String desc) {
    // Buat object LogModel baru
    // DateTime.now().toString() → contoh: "2026-02-24 14:30:00.000"
    final newLog = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toString(),
    );

    // Buat list BARU dengan spread operator
    // Kenapa list baru? Karena ValueNotifier hanya tahu ada perubahan
    // jika REFERENCE berubah (ditunjuk ke object baru)
    // [...listLama, itemBaru] = ambil semua isi list lama + tambah item baru
    logsNotifier.value = [...logsNotifier.value, newLog];

    // Simpan ke storage setiap ada perubahan
    saveToDisk();
  }

  // ===== UPDATE: Edit catatan berdasarkan index =====
  void updateLog(int index, String title, String desc) {
    // Buat SALINAN list (bukan reference ke list yang sama)
    final currentLogs = List<LogModel>.from(logsNotifier.value);

    // Ganti item di posisi index dengan LogModel baru
    currentLogs[index] = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toString(),
    );

    // Assign list baru → ValueNotifier mendeteksi perubahan → UI rebuild
    logsNotifier.value = currentLogs;
    saveToDisk();
  }

  // ===== DELETE: Hapus catatan berdasarkan index =====
  void removeLog(int index) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    // removeAt = hapus item di posisi tertentu
    // Misal list = [A, B, C], removeAt(1) → [A, C]
    currentLogs.removeAt(index);
    logsNotifier.value = currentLogs;
    saveToDisk();
  }

  // ===== SAVE: Encoding Object → JSON → SharedPreferences =====
  // Future = operasi yang butuh waktu (async), hasilnya datang nanti
  // async/await = "tunggu sampai operasi ini selesai"
  Future<void> saveToDisk() async {
    // 1. Dapatkan instance SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // 2. Ubah List<LogModel> → List<Map> → JSON String
    //    .map((e) => e.toMap()) = setiap LogModel diubah jadi Map
    //    .toList() = hasil map (Iterable) dijadikan List
    //    jsonEncode() = List<Map> dijadikan JSON String
    final String encodedData = jsonEncode(
      logsNotifier.value.map((e) => e.toMap()).toList(),
    );

    // 3. Simpan JSON String ke SharedPreferences dengan key tertentu
    await prefs.setString(_storageKey, encodedData);
  }

  // ===== LOAD: SharedPreferences → JSON → Decoding ke Object =====
  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();

    // Baca string dari storage (bisa null jika belum pernah simpan)
    final String? data = prefs.getString(_storageKey);

    if (data != null) {
      // 1. jsonDecode() = JSON String → List<dynamic>
      final List decoded = jsonDecode(data);

      // 2. .map((e) => LogModel.fromMap(e)) = setiap Map diubah jadi LogModel
      logsNotifier.value = decoded.map((e) => LogModel.fromMap(e)).toList();
    }
  }
}
