import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:logbook_app_082/features/logbook/log_controller.dart';
import 'package:logbook_app_082/features/models/log_model.dart';
import 'package:logbook_app_082/services/access_control_service.dart'; // Import Baru
import 'package:logbook_app_082/features/logbook/log_editor_page.dart'; // Import Baru (Langkah 3)
import 'package:logbook_app_082/features/auth/login_view.dart';
import 'package:lottie/lottie.dart';

class LogView extends StatefulWidget {
  final String username;
  final String role;
  final String uid;
  final String teamId;

  const LogView({
    super.key,
    required this.username,
    required this.role,
    required this.uid,
    required this.teamId,
  });

  // Getter untuk currentUser object (kompatibilitas dengan log_editor_page)
  Map<String, String> get currentUser => {
    'username': username,
    'role': role,
    'uid': uid,
    'teamId': teamId,
  };

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _controller = LogController();
    // Set user context untuk security checks di controller
    _controller.setUserContext(widget.role, widget.uid);
    // Panggil loadLogs dengan teamId milik user yang sedang login
    _controller.loadLogs(widget.teamId);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      // Jika ada koneksi (bukan none)
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        // Reload data untuk trigger sync
        _controller.loadLogs(widget.teamId);
      }
    });

    _searchController = TextEditingController();
    _searchController.addListener(() {
      _controller.searchLogs(_searchController.text);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel(); // PENTING: Cancel listener
    _searchController.dispose(); // Dispose search controller
    super.dispose();
  }

  // Navigasi ke Halaman Editor (Gantikan Dialog Lama)
  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  Color categoryColor(String category) {
    switch (category.trim().toLowerCase()) {
      case "mechanical":
        return const Color.fromARGB(255, 27, 26, 44);
      case "electronic":
        return Colors.red;
      case "software":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook: ${widget.username}"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.loadLogs(widget.teamId),
          ),
          // --- TOMBOL LOGOUT BARU ---
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Konfirmasi Logout"),
                  content: const Text("Apakah Anda yakin ingin keluar?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Tutup dialog
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginView(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        "Ya, Keluar ",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          //search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Cari Judul, deskripsi, atau kategori...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.logsNotifier,
              builder: (context, currentLogs, child) {
                final isSearching = _searchController.text.isNotEmpty;
                final isEmpty = currentLogs.isEmpty;
                // Jika data kosong, tampilkan Empty State yang informatif (Homework)
                Widget buildEmptyState() {
                  if (isSearching) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Lottie.asset(
                            'assets/animations/no_search.json',
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            repeat: true,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada hasil pencarian dari "${_searchController.text}"',
                          ),
                        ],
                      ),
                    );
                  }

                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset(
                          'assets/animations/no_data.json',
                          height: 350,
                          width: 400,
                          repeat: true,
                        ),
                        ElevatedButton(
                          onPressed: () => _goToEditor(),
                          child: const Text("Buat Catatan Pertama"),
                        ),
                      ],
                    ),
                  );
                }

                Widget buildList() {
                  return ListView.builder(
                    itemCount: currentLogs.length,
                    itemBuilder: (context, index) {
                      final log = currentLogs[index];

                      // Cek kepemilikan data untuk Gatekeeper
                      final bool isOwner = log.authorId == widget.uid;
                      final categoryClr = categoryColor(log.category);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        elevation: 5,
                        shadowColor: categoryClr,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: categoryClr, // Warna Outline
                            width: 1.5, // Ketebalan Outline
                          ),
                          borderRadius: BorderRadius.circular(
                            10,
                          ), // Sudut melengkung
                        ),

                        child: ListTile(
                          // Indikator sinkronisasi (Optional: Cloud jika ada ID, lokal jika pending)
                          leading: Icon(
                            log.id != null
                                ? Icons.cloud_done
                                : Icons.cloud_upload_outlined,
                            color: log.id != null
                                ? Colors.green
                                : Colors.orange,
                          ),
                          title: Text(log.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryClr.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: categoryClr),
                                ),
                                child: Text(
                                  log.category,
                                  style: TextStyle(
                                    color: categoryClr,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // GATEKEEPER: Tombol Edit
                              if (AccessControlService.canPerform(
                                widget.role,
                                AccessControlService.actionUpdate,
                                isOwner: isOwner,
                              ))
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () =>
                                      _goToEditor(log: log, index: index),
                                ),

                              // GATEKEEPER: Tombol Delete
                              if (AccessControlService.canPerform(
                                widget.role,
                                AccessControlService.actionDelete,
                                isOwner: isOwner,
                              ))
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _controller.removeLog(index),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                return isEmpty ? buildEmptyState() : buildList();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToEditor(), // Langsung ke Editor Page
        child: const Icon(Icons.add),
      ),
    );
  }
}
