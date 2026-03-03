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

  List<LogModel> _allLogs =
      []; // List utama untuk menyimpan semua catatan (tanpa filter)

  String _currentSearchKeyword = ''; // Kata kunci pencarian saat ini

  // Constructor — dipanggil saat LogController pertama kali dibuat
  // Langsung load data dari disk agar catatan lama muncul
  LogController() {
    loadFromDisk();
  }

  void searchLogs(String keyword) {
    _currentSearchKeyword = keyword.toLowerCase();

    if (_currentSearchKeyword.isEmpty) {
      // Jika kata kunci kosong, tampilkan semua catatan
      logsNotifier.value = List<LogModel>.from(_allLogs);
    } else {
      // Filter catatan berdasarkan kata kunci (cari di title dan description)
      logsNotifier.value = _allLogs.where((log) {
        return log.title.toLowerCase().contains(_currentSearchKeyword) ||
            log.description.toLowerCase().contains(_currentSearchKeyword);
      }).toList();
    }
  }

  void _refreshDisplay() {
    searchLogs(_currentSearchKeyword);
  }

  // ===== CREATE: Tambah catatan baru =====
  void addLog(String title, String desc, {String category = 'Pribadi'}) {
    // Buat object LogModel baru
    // DateTime.now().toString() → contoh: "2026-02-24 14:30:00.000"
    final newLog = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      category: category,
    );

    _allLogs.add(newLog); // Simpan ke list utama
    _refreshDisplay(); // Refresh tampilan berdasarkan kata kunci saat ini
    saveToDisk(); // Simpan ke storage setiap ada perubahan
  }

  // ===== UPDATE: Edit catatan berdasarkan index =====
  void updateLog(
    int displayIndex,
    String title,
    String desc, {
    String category = 'Pribadi',
  }) {
    final displayedLog = logsNotifier.value[displayIndex];
    final actualIndex = _allLogs.indexOf(displayedLog);

    if (actualIndex != -1) {
      _allLogs[actualIndex] = LogModel(
        title: title,
        description: desc,
        date: DateTime.now().toString(),
        category: category,
      );
      _refreshDisplay();
      saveToDisk();
    }
  }

  // ===== DELETE: Hapus catatan berdasarkan index =====
  void removeLog(int displayIndex) {
    final displayedLog = logsNotifier.value[displayIndex];
    _allLogs.remove(displayedLog);
    _refreshDisplay();
    saveToDisk();
  }

  // ===== SAVE: Encoding Object → JSON → SharedPreferences =====
  // Future = operasi yang butuh waktu (async), hasilnya datang nanti
  // async/await = "tunggu sampai operasi ini selesai"
  // ===== SAVE =====
  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    // Simpan _allLogs (list LENGKAP), bukan logsNotifier (yang mungkin terfilter)
    final String encodedData = jsonEncode(
      _allLogs.map((e) => e.toMap()).toList(),
    );
    await prefs.setString(_storageKey, encodedData);
  }

  // ===== LOAD =====
  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      final List decoded = jsonDecode(data);
      _allLogs = decoded.map((e) => LogModel.fromMap(e)).toList();
      // Tampilkan semua catatan saat pertama kali load
      logsNotifier.value = List.from(_allLogs);
    }
  }
}
