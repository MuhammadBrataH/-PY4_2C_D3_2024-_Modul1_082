import 'package:flutter/material.dart';
import 'package:logbook_app_082/features/logbook/log_controller.dart';
import 'package:logbook_app_082/features/models/log_model.dart';
import 'package:logbook_app_082/features/onboarding/onboarding_view.dart';
import 'package:intl/intl.dart';
import 'package:logbook_app_082/services/mongo_service.dart';
import 'package:logbook_app_082/helpers/log_helper.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  // ===== TASK 3: Controller dan State (Async-Reactive Flow) =====
  late LogController _controller;

  // FutureBuilder membutuhkan Future yang di-track untuk menentukan state (waiting/done/error)
  // Kita simpan Future dari _initDatabase() agar FutureBuilder bisa memantau prosesnya
  late Future<void> _initFuture;
  bool _isOffline = false; // Connection Guard: true saat koneksi gagal

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // ===== Controller untuk search field =====
  final TextEditingController _searchController = TextEditingController();

  // ===== TASK 3: initState + _initDatabase dengan FutureBuilder =====
  @override
  void initState() {
    super.initState();
    _controller = LogController();

    // Simpan Future agar FutureBuilder bisa memantau status koneksi
    _initFuture = _initDatabase();
  }

  /// ===== CONNECTION GUARD =====
  /// Inisialisasi koneksi + muat data. Jika gagal → Offline Mode (bukan crash).
  Future<void> _initDatabase() async {
    await LogHelper.writeLog(
      "UI: Memulai inisialisasi database...",
      source: "log_view.dart",
    );

    try {
      // Mencoba koneksi ke MongoDB Atlas (Cloud)
      await MongoService().connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception(
          "Koneksi Cloud Timeout. Periksa sinyal/IP Whitelist.",
        ),
      );

      await LogHelper.writeLog(
        "UI: Koneksi MongoService BERHASIL.",
        source: "log_view.dart",
      );

      // Ambil data dari Cloud
      await _controller.loadFromCloud();
      _isOffline = false;

      await LogHelper.writeLog(
        "UI: Data berhasil dimuat dari Cloud.",
        source: "log_view.dart",
      );
    } catch (e) {
      // CONNECTION GUARD: Jangan crash — fallback ke Offline Mode
      await LogHelper.writeLog(
        "UI: Koneksi gagal, masuk Offline Mode - $e",
        source: "log_view.dart",
        level: 1,
      );
      _isOffline = true;
      await _controller.loadFromDisk();

      await LogHelper.writeLog(
        "UI: Data dimuat dari cache lokal (Offline Mode).",
        source: "log_view.dart",
      );
    }
  }

  /// Refresh data — rebuild FutureBuilder dari awal
  void _refreshData() {
    setState(() {
      _isOffline = false;
      _initFuture = _initDatabase();
    });
  }

  /// ===== PULL-TO-REFRESH =====
  /// Dipanggil saat user menarik layar ke bawah (RefreshIndicator)
  /// Tidak rebuild FutureBuilder — hanya refresh data di background
  Future<void> _handlePullRefresh() async {
    try {
      await MongoService().connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception("Timeout"),
      );
      await _controller.loadFromCloud();
      if (mounted) setState(() => _isOffline = false);
    } catch (e) {
      await LogHelper.writeLog(
        "UI: Pull-to-refresh gagal - $e",
        source: "log_view.dart",
        level: 1,
      );
      if (mounted) {
        setState(() => _isOffline = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Gagal memuat dari Cloud. Mode Offline aktif."),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // ===== BARU: Daftar kategori yang tersedia =====
  final List<String> _categories = ['Pribadi', 'Himpunan', 'Akademik'];

  // ===== BARU: Helper — Warna berdasarkan kategori =====
  // Fungsi ini mengembalikan warna yang BERBEDA untuk setiap kategori
  // Dipakai untuk mewarnai Card agar mudah dibedakan secara visual
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Himpunan':
        return Colors.blue.shade50; // Biru muda
      case 'Akademik':
        return Colors.red.shade50; // Merah muda
      case 'Pribadi':
      default:
        return Colors.green.shade50; // Hijau muda
    }
  }

  // ===== BARU: Helper — Icon berdasarkan kategori =====
  // Memberikan icon yang relevan dengan jenis kategori
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Himpunan':
        return Icons.group_rounded;
      case 'Akademik':
        return Icons.school_rounded;
      case 'Pribadi':
      default:
        return Icons.person_rounded;
    }
  }

  // ===== BARU: Helper — Warna icon berdasarkan kategori =====
  Color _getCategoryIconColor(String category) {
    switch (category) {
      case 'Himpunan':
        return Colors.blue;
      case 'Akademik':
        return Colors.red;
      case 'Pribadi':
      default:
        return Colors.green;
    }
  }

  String _getGreeting() {
    int jam = DateTime.now().hour;
    if (jam >= 6 && jam < 11) return "Selamat Pagi";
    if (jam >= 11 && jam < 15) return "Selamat Siang";
    if (jam >= 15 && jam < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  // ===== TIMESTAMP FORMATTING: Relatif + Absolut (Indonesia) =====
  // Menggunakan library intl (DateFormat) untuk format waktu lokal Indonesia
  // Contoh: "Baru saja", "2 menit yang lalu", "25 Jan 2026, 14:30"
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      // Format RELATIF untuk waktu yang "dekat" — gaya Indonesia
      if (difference.isNegative) {
        return DateFormat('d MMM yyyy, HH:mm').format(date);
      }
      if (difference.inSeconds < 60) return "Baru saja";
      if (difference.inMinutes < 60) {
        return "${difference.inMinutes} menit yang lalu";
      }
      if (difference.inHours < 24) {
        return "${difference.inHours} jam yang lalu";
      }
      if (difference.inDays < 7) {
        return "${difference.inDays} hari yang lalu";
      }

      // Format ABSOLUT untuk waktu > 7 hari — menggunakan library intl
      return DateFormat('d MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // ===== CONNECTION GUARD: Widget Banner untuk Offline Mode =====
  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange.shade800, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Offline Mode — Menampilkan data dari cache lokal. "
              "Tarik ke bawah untuk mencoba koneksi ulang.",
              style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddLogDialog() {
    // Reset nilai dropdown ke default setiap kali dialog dibuka
    String selectedCategory = 'Pribadi';

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder memungkinkan setState() di DALAM dialog
        // Tanpa ini, dropdown tidak akan berubah saat user pilih opsi
        // karena dialog punya context sendiri yang terpisah dari parent
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Tambah Catatan Baru"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: "Judul Catatan",
                    ),
                  ),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      hintText: "Isi Deskripsi",
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ===== DROPDOWN KATEGORI =====
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: "Kategori",
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Row(
                          children: [
                            Icon(
                              _getCategoryIcon(category),
                              color: _getCategoryIconColor(category),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(category),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      // setDialogState agar dropdown menampilkan pilihan baru
                      setDialogState(() {
                        selectedCategory = newValue!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // ===== BARU: async untuk sinkronisasi ke Cloud =====
                    await _controller.addLog(
                      _titleController.text,
                      _contentController.text,
                      category: selectedCategory,
                    );
                    _titleController.clear();
                    _contentController.clear();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditLogDialog(int index, LogModel log) {
    _titleController.text = log.title;
    _contentController.text = log.description;
    // Pre-fill dropdown dengan kategori yang sudah ada
    String selectedCategory = log.category;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Catatan"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: _titleController),
                  TextField(controller: _contentController),
                  const SizedBox(height: 12),
                  // ===== DROPDOWN KATEGORI (pre-filled) =====
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: "Kategori",
                      border: OutlineInputBorder(),
                    ),
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Row(
                          children: [
                            Icon(
                              _getCategoryIcon(category),
                              color: _getCategoryIconColor(category),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(category),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedCategory = newValue!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // ===== BARU: async untuk sinkronisasi ke Cloud =====
                    await _controller.updateLog(
                      index,
                      _titleController.text,
                      _contentController.text,
                      category: selectedCategory,
                    );
                    _titleController.clear();
                    _contentController.clear();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Logbook: ${widget.username}"),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        leading: const Icon(Icons.book, color: Colors.white),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 77, 80, 255),
        actions: [
          // ===== TASK 3: Tombol refresh — rebuild FutureBuilder =====
          IconButton(
            icon: const Icon(Icons.cloud_sync, color: Colors.white),
            tooltip: "Refresh dari Cloud",
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingView()),
              );
            },
          ),
        ],
      ),

      // ===== TASK 3: BODY dengan FutureBuilder (Async-Reactive Flow) =====
      // FutureBuilder otomatis mengelola 3 state: waiting, error, done
      // Tidak perlu bool _isLoading manual — Flutter yang atur
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          // ──── STATE 1: ConnectionState.waiting → Loading ────
          // FutureBuilder otomatis tahu kapan Future belum selesai
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Menghubungkan ke MongoDB Atlas..."),
                ],
              ),
            );
          }

          // ──── STATE 2: snapshot.hasError → Gagal koneksi ────
          // Jika _initDatabase() throw Exception, FutureBuilder tangkap di sini
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    "Gagal terhubung: ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Coba Lagi"),
                  ),
                ],
              ),
            );
          }

          // ──── STATE 3: ConnectionState.done → Data siap ────
          // Setelah Future selesai tanpa error, gunakan ValueListenableBuilder
          // untuk reactive updates (search, CRUD real-time)
          return ValueListenableBuilder<List<LogModel>>(
            valueListenable: _controller.logsNotifier,
            builder: (context, currentLogs, child) {
              // 3a. Data Kosong — dengan Pull-to-Refresh + Connection Guard
              if (currentLogs.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _handlePullRefresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      // Connection Guard: Banner offline jika koneksi gagal
                      if (_isOffline) _buildOfflineBanner(),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.25,
                      ),
                      const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Center(child: Text("Data Kosong")),
                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton(
                          onPressed: _showAddLogDialog,
                          child: const Text("Buat Catatan Pertama"),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // 3b. Data ada — tampilkan List
              return Column(
                children: [
                  // ===== CONNECTION GUARD: Banner Offline Mode =====
                  if (_isOffline) _buildOfflineBanner(),

                  // ===== GREETING =====
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "${_getGreeting()}, ${widget.username}!",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // ===== SEARCH FIELD =====
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        _controller.searchLogs(value);
                      },
                      decoration: InputDecoration(
                        hintText: "Cari catatan berdasarkan judul...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _controller.searchLogs('');
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  // ===== LIST CATATAN + PULL-TO-REFRESH =====
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _handlePullRefresh,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: currentLogs.length,
                        itemBuilder: (context, index) {
                          final log = currentLogs[index];

                          return Dismissible(
                            key: ValueKey('${log.title}_${log.date}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.delete_forever,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Hapus",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Hapus Catatan"),
                                  content: Text(
                                    "Yakin ingin menghapus \"${log.title}\"?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Batal"),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Hapus"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) async {
                              await _controller.removeLog(index);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "\"${log.title}\" telah dihapus",
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },

                            // ===== CHILD: Card yang dipercantik =====
                            child: Card(
                              color: _getCategoryColor(log.category),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // --- Baris atas: Icon + Judul + Tombol Edit ---
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor:
                                              _getCategoryIconColor(
                                                log.category,
                                              ).withOpacity(0.15),
                                          child: Icon(
                                            _getCategoryIcon(log.category),
                                            color: _getCategoryIconColor(
                                              log.category,
                                            ),
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                log.title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatDate(log.date),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit_outlined,
                                            color: Colors.grey.shade400,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              _showEditLogDialog(index, log),
                                        ),
                                      ],
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      child: Divider(
                                        height: 1,
                                        color: _getCategoryIconColor(
                                          log.category,
                                        ).withOpacity(0.15),
                                      ),
                                    ),

                                    Text(
                                      log.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    const SizedBox(height: 10),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getCategoryIconColor(
                                              log.category,
                                            ).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getCategoryIcon(log.category),
                                                size: 14,
                                                color: _getCategoryIconColor(
                                                  log.category,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                log.category,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: _getCategoryIconColor(
                                                    log.category,
                                                  ),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.swipe_left_rounded,
                                              size: 14,
                                              color: Colors.grey.shade300,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "geser untuk hapus",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade300,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLogDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
