import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import '../models/log_model.dart';
import 'package:logbook_app_082/services/mongo_service.dart';
import 'package:logbook_app_082/services/access_control_service.dart';
import 'package:logbook_app_082/helpers/log_helper.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);

  // Hive box untuk penyimpanan lokal
  final Box<LogModel> _myBox = Hive.box<LogModel>('offline_logs');

  // User context untuk security checks
  String _userRole = '';
  String _userId = '';

  List<LogModel> _allLogs = []; // Cache untuk semua log (termasuk yang tidak ditampilkan karena filter)

  void setUserContext(String role, String uid) {
    _userRole = role;
    _userId = uid;
  }



  void searchLogs(String query) {
    if (query.isEmpty) {
      logsNotifier.value = List.from(_allLogs);
    } else {
      final lowerQuery = query.toLowerCase();
      logsNotifier.value = _allLogs.where((log) {
        return log.title.toLowerCase().contains(lowerQuery) ||
            log.description.toLowerCase().contains(lowerQuery) ||
            log.category.toLowerCase().contains(lowerQuery);
      }).toList();
    }
  }

  /// 1. LOAD DATA (Offline-First Strategy)
  /// 1. LOAD DATA (Offline-First Strategy)
  Future<void> loadLogs(String teamId) async {
    // Langkah 1: Ambil data dari Hive (Sangat Cepat/Instan)
    // Filter berdasarkan teamId agar konsisten dengan cloud
    final localData = _myBox.values
        .where((log) => log.teamId == teamId)
        .toList();
    _allLogs = localData; // Update cache
    logsNotifier.value = localData;

    // Langkah 2: Sync dari Cloud (Background)
    try {
      final cloudData = await MongoService().getLogs(teamId);

      // PENTING: Jangan clear Hive jika cloud kosong tapi lokal ada data
      // Ini mencegah kehilangan data offline yang belum ter-sync
      if (cloudData.isNotEmpty) {
        // Hapus data tim ini dari Hive, lalu isi dengan data cloud
        final keysToDelete = <dynamic>[];
        for (var i = 0; i < _myBox.length; i++) {
          if (_myBox.getAt(i)?.teamId == teamId) {
            keysToDelete.add(_myBox.keyAt(i));
          }
        }
        for (var key in keysToDelete) {
          await _myBox.delete(key);
        }
        await _myBox.addAll(cloudData);

        _allLogs = cloudData; // Update cache dengan data terbaru dari cloud
        // Update UI dengan data Cloud
        logsNotifier.value = cloudData;
      }

      await LogHelper.writeLog(
        "SYNC: Data berhasil diperbarui dari Atlas (${cloudData.length} items)",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "OFFLINE: Menggunakan data cache lokal (${localData.length} items) - $e",
        level: 2,
      );
      // Data dari Hive sudah di-load di awal, jadi tidak perlu aksi tambahan
    }
  }

  /// 2. ADD DATA (Instant Local + Background Cloud)
  Future<void> addLog(
    String title,
    String desc,
    String authorId,
    String teamId, {
    String category = "Software", // Default kategori
  }) async {
    final newLog = LogModel(
      id: ObjectId().oid, // Menggunakan .oid (String) untuk Hive
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      authorId: authorId,
      teamId: teamId,
      category: category,
    );

    // ACTION 1: Simpan ke Hive (Instan)
    await _myBox.add(newLog);
    _allLogs = [..._allLogs, newLog]; // Update cache
    logsNotifier.value = [...logsNotifier.value, newLog];

    // ACTION 2: Kirim ke MongoDB Atlas (Background)
    try {
      await MongoService().insertLog(newLog);
      await LogHelper.writeLog(
        "SUCCESS: Data tersinkron ke Cloud",
        source: "log_controller.dart",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Data tersimpan lokal, akan sinkron saat online",
        level: 1,
      );
    }
  }

  /// 3. UPDATE DATA dengan Security Check
  Future<void> updateLog(
    int index,
    String title,
    String desc, {
    String? category,
  }) async {
    final target = logsNotifier.value[index];

    // SECURITY CHECK: Validasi izin update
    if (!AccessControlService.canPerform(
      _userRole,
      AccessControlService.actionUpdate,
      isOwner: target.authorId == _userId,
    )) {
      await LogHelper.writeLog(
        "SECURITY BREACH: Unauthorized update attempt",
        level: 1,
      );
      return;
    }

    final updatedLog = LogModel(
      id: target.id,
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      authorId: target.authorId,
      teamId: target.teamId,
      isPublic: target.isPublic,
      category: category ?? target.category,
    );

    // Update Hive
    final hiveIndex = _myBox.values.toList().indexOf(target);
    if (hiveIndex != -1) {
      await _myBox.putAt(hiveIndex, updatedLog);
    }

    // Update UI
    final updatedList = List<LogModel>.from(logsNotifier.value);
    updatedList[index] = updatedLog;
    logsNotifier.value = updatedList;

    // Sync ke Cloud
    try {
      await MongoService().updateLog(updatedLog);
      await LogHelper.writeLog(
        "SUCCESS: Data terupdate di Cloud",
        source: "log_controller.dart",
      );
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Update tersimpan lokal, akan sinkron saat online",
        level: 1,
      );
    }
  }

  /// 4. DELETE DATA dengan Security Check
  Future<void> removeLog(int index) async {
    final target = logsNotifier.value[index];

    // SECURITY CHECK: Validasi izin hapus
    if (!AccessControlService.canPerform(
      _userRole,
      AccessControlService.actionDelete,
      isOwner: target.authorId == _userId,
    )) {
      await LogHelper.writeLog(
        "SECURITY BREACH: Unauthorized delete attempt",
        level: 1,
      );
      return; // Hentikan proses jika tidak punya izin
    }

    // Hapus dari Hive
    final hiveIndex = _myBox.values.toList().indexOf(target);
    if (hiveIndex != -1) {
      await _myBox.deleteAt(hiveIndex);
    }

    // Update UI
    final updatedList = List<LogModel>.from(logsNotifier.value);
    updatedList.removeAt(index);
    logsNotifier.value = updatedList;

    // Sync ke Cloud
    if (target.id != null) {
      try {
        await MongoService().deleteLog(ObjectId.fromHexString(target.id!));
        await LogHelper.writeLog(
          "SUCCESS: Data terhapus dari Cloud",
          source: "log_controller.dart",
        );
      } catch (e) {
        await LogHelper.writeLog(
          "WARNING: Hapus tersimpan lokal, akan sinkron saat online",
          level: 1,
        );
      }
    }
  }
}
