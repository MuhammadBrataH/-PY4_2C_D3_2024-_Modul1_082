import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/log_model.dart';
import 'package:logbook_app_082/services/mongo_service.dart';
import 'package:logbook_app_082/helpers/log_helper.dart';

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

// ===== Controller: Mengelola data (CRUD + Cloud Sync) =====
class LogController {
  // ValueNotifier = "kotak data" yang BERTERIAK ke semua pendengarnya saat isinya berubah
  // Jadi UI tidak perlu setState() manual — cukup dengarkan notifier ini
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);

  // ===== BARU: Notifier status loading untuk UI =====
  // true = sedang mengambil data dari cloud, false = selesai
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

  // Key untuk SharedPreferences (cache lokal / fallback offline)
  static const String _storageKey = 'user_logs_data';

  // ===== BARU: Instance MongoService (Singleton) =====
  // Ini "jembatan" antara Controller dan Cloud Database
  final MongoService _mongoService = MongoService();

  final String _source = "log_controller.dart";

  List<LogModel> _allLogs =
      []; // List utama untuk menyimpan semua catatan (tanpa filter)

  String _currentSearchKeyword = ''; // Kata kunci pencarian saat ini

  // Constructor — dipanggil saat LogController pertama kali dibuat
  // Langsung load data dari CLOUD agar catatan terbaru muncul
  LogController() {
    loadFromCloud();
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

  // ===== CREATE: Tambah catatan baru + Sync ke Cloud =====
  Future<void> addLog(
    String title,
    String desc, {
    String category = 'Pribadi',
  }) async {
    // Buat object LogModel baru
    final newLog = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      category: category,
    );

    // 1. Simpan ke list lokal & refresh UI (agar responsif)
    _allLogs.add(newLog);
    _refreshDisplay();
    saveToDisk(); // Cache lokal

    // 2. Sync ke Cloud (MongoDB Atlas)
    try {
      await _mongoService.insertLog(newLog);
      await LogHelper.writeLog(
        "SYNC: '${newLog.title}' berhasil disimpan ke Cloud",
        source: _source,
        level: 2,
      );
      // Reload dari cloud untuk mendapatkan data dengan _id dari MongoDB
      await _reloadFromCloud();
    } catch (e) {
      await LogHelper.writeLog(
        "SYNC: Gagal simpan ke Cloud - $e (data tersimpan lokal)",
        source: _source,
        level: 1,
      );
    }
  }

  // ===== UPDATE: Edit catatan + Sync ke Cloud =====
  Future<void> updateLog(
    int displayIndex,
    String title,
    String desc, {
    String category = 'Pribadi',
  }) async {
    final displayedLog = logsNotifier.value[displayIndex];
    final actualIndex = _allLogs.indexOf(displayedLog);

    if (actualIndex != -1) {
      // Buat LogModel baru dengan ID yang SAMA (agar MongoDB tahu yang mana)
      final updatedLog = LogModel(
        id: _allLogs[actualIndex].id, // Pertahankan ID dari cloud
        title: title,
        description: desc,
        date: DateTime.now().toString(),
        category: category,
      );

      // 1. Update lokal & refresh UI
      _allLogs[actualIndex] = updatedLog;
      _refreshDisplay();
      saveToDisk();

      // 2. Sync ke Cloud
      try {
        await _mongoService.updateLog(updatedLog);
        await LogHelper.writeLog(
          "SYNC: '${updatedLog.title}' berhasil diupdate di Cloud",
          source: _source,
          level: 2,
        );
      } catch (e) {
        await LogHelper.writeLog(
          "SYNC: Gagal update ke Cloud - $e (data terupdate lokal)",
          source: _source,
          level: 1,
        );
      }
    }
  }

  // ===== DELETE: Hapus catatan + Sync ke Cloud =====
  Future<void> removeLog(int displayIndex) async {
    final displayedLog = logsNotifier.value[displayIndex];
    final removedId = displayedLog.id; // Ambil ID sebelum dihapus

    // 1. Hapus lokal & refresh UI
    _allLogs.remove(displayedLog);
    _refreshDisplay();
    saveToDisk();

    // 2. Sync ke Cloud (hapus berdasarkan ObjectId)
    if (removedId != null) {
      try {
        await _mongoService.deleteLog(removedId);
        await LogHelper.writeLog(
          "SYNC: '${displayedLog.title}' berhasil dihapus dari Cloud",
          source: _source,
          level: 2,
        );
      } catch (e) {
        await LogHelper.writeLog(
          "SYNC: Gagal hapus dari Cloud - $e (data terhapus lokal)",
          source: _source,
          level: 1,
        );
      }
    }
  }

  // ===== LOAD FROM CLOUD: Sumber data utama =====
  // Dipanggil saat pertama kali app dibuka
  // Jika cloud gagal, fallback ke cache lokal (SharedPreferences)
  Future<void> loadFromCloud() async {
    isLoadingNotifier.value = true;

    try {
      await LogHelper.writeLog(
        "SYNC: Memuat data dari Cloud...",
        source: _source,
        level: 3,
      );

      // Ambil semua data dari MongoDB Atlas
      final cloudLogs = await _mongoService.getLogs();

      _allLogs = cloudLogs;
      _refreshDisplay();

      // Simpan ke cache lokal sebagai backup
      saveToDisk();

      await LogHelper.writeLog(
        "SYNC: ${cloudLogs.length} catatan berhasil dimuat dari Cloud",
        source: _source,
        level: 2,
      );
    } catch (e) {
      // Jika cloud gagal, pakai data lokal sebagai fallback
      await LogHelper.writeLog(
        "SYNC: Cloud gagal, memuat dari cache lokal - $e",
        source: _source,
        level: 1,
      );
      await loadFromDisk();
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  // ===== RELOAD: Refresh data dari cloud tanpa loading indicator =====
  // Dipanggil setelah insert untuk mendapatkan _id dari MongoDB
  Future<void> _reloadFromCloud() async {
    try {
      final cloudLogs = await _mongoService.getLogs();
      _allLogs = cloudLogs;
      _refreshDisplay();
      saveToDisk();
    } catch (e) {
      await LogHelper.writeLog(
        "SYNC: Reload gagal - $e",
        source: _source,
        level: 1,
      );
    }
  }

  // ===== SAVE TO DISK: Cache lokal (SharedPreferences) =====
  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      _allLogs.map((e) => e.toMap()).toList(),
    );
    await prefs.setString(_storageKey, encodedData);
  }

  // ===== LOAD FROM DISK: Fallback offline =====
  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      final List decoded = jsonDecode(data);
      _allLogs = decoded.map((e) => LogModel.fromMap(e)).toList();
      logsNotifier.value = List.from(_allLogs);
    }
  }
}
