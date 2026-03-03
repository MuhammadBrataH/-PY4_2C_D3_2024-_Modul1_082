import 'package:flutter/material.dart';
import 'package:logbook_app_082/features/logbook/log_controller.dart';
import 'package:logbook_app_082/features/logbook/models/log_model.dart';
import 'package:logbook_app_082/features/onboarding/onboarding_view.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final LogController _controller = LogController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // ===== BARU: Controller untuk search field =====
  final TextEditingController _searchController = TextEditingController();

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
                  onPressed: () {
                    _controller.addLog(
                      _titleController.text,
                      _contentController.text,
                      category: selectedCategory,
                    );
                    _titleController.clear();
                    _contentController.clear();
                    Navigator.pop(context);
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
                  onPressed: () {
                    _controller.updateLog(
                      index,
                      _titleController.text,
                      _contentController.text,
                      category: selectedCategory,
                    );
                    _titleController.clear();
                    _contentController.clear();
                    Navigator.pop(context);
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

      // ===== BODY =====
      body: Column(
        children: [
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

          // ===== BARU: SEARCH FIELD =====
          Padding(
            // fromLTRB = from Left, Top, Right, Bottom
            // Mengatur jarak dari setiap sisi secara terpisah
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,

              // onChanged dipanggil SETIAP KALI teks berubah (setiap ketukan)
              // Inilah yang membuat pencarian "real-time"
              // value = teks terbaru yang diketik user
              onChanged: (value) {
                _controller.searchLogs(value);
              },

              decoration: InputDecoration(
                hintText: "Cari catatan berdasarkan judul...",

                // prefixIcon = icon di AWAL (kiri) TextField
                prefixIcon: const Icon(Icons.search),

                // suffixIcon = icon di AKHIR (kanan) TextField
                // Tombol X untuk menghapus teks pencarian
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    // Kosongkan search field
                    _searchController.clear();
                    // Tampilkan semua catatan kembali
                    _controller.searchLogs('');
                  },
                ),

                // border = garis tepi TextField
                // OutlineInputBorder = border berbentuk kotak dengan sudut bulat
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                // contentPadding = jarak antara teks dan border
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // ===== LIST CATATAN =====
          // Expanded = mengambil SEMUA sisa ruang yang tersedia
          // Tanpa Expanded, ListView tidak tahu batasnya dan akan error
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.logsNotifier,
              builder: (context, currentLogs, child) {
                if (currentLogs.isEmpty) {
                  // ===== EMPTY STATE: Ilustrasi menarik saat list kosong =====
                  final bool isSearching = _searchController.text.isNotEmpty;

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        // MainAxisAlignment.center = posisikan children di TENGAH vertikal
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // --- Icon besar sebagai ilustrasi ---
                          Icon(
                            isSearching
                                ? Icons.search_off_rounded
                                : Icons.menu_book_rounded,
                            size: 100,
                            color: Colors.grey.shade300,
                          ),

                          const SizedBox(height: 24),

                          // --- Judul pesan ---
                          Text(
                            isSearching
                                ? "Catatan tidak ditemukan"
                                : "Belum ada catatan",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // --- Deskripsi/sub-judul ---
                          Text(
                            isSearching
                                ? "Tidak ada catatan dengan judul \"${_searchController.text}\""
                                : "Mulai catat aktivitas harianmu!\nTekan tombol + di bawah untuk memulai.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),

                          // --- Tombol ajakan (hanya muncul jika BUKAN sedang search) ---
                          if (!isSearching) ...[
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _showAddLogDialog,
                              icon: const Icon(Icons.add),
                              label: const Text("Tambah Catatan Pertama"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  77,
                                  80,
                                  255,
                                ),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: currentLogs.length,
                  itemBuilder: (context, index) {
                    final log = currentLogs[index];
                    return Card(
                      // ===== WARNA KARTU BERDASARKAN KATEGORI =====
                      color: _getCategoryColor(log.category),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        // ===== ICON BERDASARKAN KATEGORI =====
                        leading: CircleAvatar(
                          backgroundColor: _getCategoryIconColor(
                            log.category,
                          ).withOpacity(0.2),
                          child: Icon(
                            _getCategoryIcon(log.category),
                            color: _getCategoryIconColor(log.category),
                          ),
                        ),
                        title: Text(log.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log.description),
                            const SizedBox(height: 4),
                            // ===== CHIP KATEGORI =====
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryIconColor(
                                  log.category,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                log.category,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _getCategoryIconColor(log.category),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditLogDialog(index, log),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _controller.removeLog(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLogDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
