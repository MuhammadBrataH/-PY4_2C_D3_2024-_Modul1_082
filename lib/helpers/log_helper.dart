import 'dart:developer' as dev;
import 'dart:io'; // TASK 4: Untuk menulis file log
import 'package:intl/intl.dart'; // Tetap kita gunakan untuk presisi waktu
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LogHelper {
  static Future<void> writeLog(
    String message, {
    String source = "Unknown", // Menandakan file/proses asal
    int level = 2,
  }) async {
    // 1. Filter Konfigurasi (ENV)
    final int configLevel = int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;
    final String muteList = dotenv.env['LOG_MUTE'] ?? '';

    if (level > configLevel) return;
    if (muteList.split(',').contains(source)) return;

    try {
      // 2. Format Waktu untuk Konsol
      final now = DateTime.now();
      String timestamp = DateFormat('HH:mm:ss').format(now);
      String label = _getLabel(level);
      String color = _getColor(level);

      // 3. Output ke VS Code Debug Console (Non-blocking)
      dev.log(message, name: source, time: now, level: level * 100);

      // 4. Output ke Terminal (Agar Bapak bisa lihat di PC saat flutter run)
      // Format: [14:30:05] [INFO] [log_view.dart] -> Database Terhubung
      print('$color[$timestamp][$label][$source] -> $message\x1B[0m');

      // ===== TASK 4: Professional Audit Logging — File Log =====
      // Menulis setiap log ke file harian: logs/dd-MM-yyyy.log
      // File terbentuk otomatis per tanggal di folder /logs
      await _writeToFile(
        timestamp: timestamp,
        label: label,
        source: source,
        message: message,
        now: now,
      );
    } catch (e) {
      dev.log("Logging failed: $e", name: "SYSTEM", level: 1000);
    }
  }

  /// TASK 4: Menulis log ke file harian di folder /logs
  /// Format file: dd-MM-yyyy.log (contoh: 15-06-2025.log)
  /// Format baris: [HH:mm:ss][LEVEL][source] -> message
  static Future<void> _writeToFile({
    required String timestamp,
    required String label,
    required String source,
    required String message,
    required DateTime now,
  }) async {
    try {
      // Buat folder 'logs' jika belum ada
      final logDir = Directory('logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // Nama file berdasarkan tanggal: dd-MM-yyyy.log
      final dateStr = DateFormat('dd-MM-yyyy').format(now);
      final logFile = File('${logDir.path}/$dateStr.log');

      // Tulis baris log (tanpa warna ANSI — file harus bersih)
      final logLine = '[$timestamp][$label][$source] -> $message\n';
      await logFile.writeAsString(logLine, mode: FileMode.append);
    } catch (_) {
      // Gagal menulis file (misalnya di platform web) — diabaikan
      // Log tetap tampil di console, file hanya bonus
    }
  }

  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return "ERROR";
      case 2:
        return "INFO";
      case 3:
        return "VERBOSE";
      default:
        return "LOG";
    }
  }

  static String _getColor(int level) {
    switch (level) {
      case 1:
        return '\x1B[31m'; // Merah
      case 2:
        return '\x1B[32m'; // Hijau
      case 3:
        return '\x1B[34m'; // Biru
      default:
        return '\x1B[0m';
    }
  }
}
