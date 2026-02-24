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
  // Controller untuk logika bisnis (CRUD + storage)
  final LogController _controller = LogController();

  // TextEditingController untuk menangkap input dari TextField
  // Ini terpisah dari LogController — fungsinya berbeda
  // _titleController = mengambil teks dari field judul
  // _contentController = mengambil teks dari field deskripsi
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // ===== Greeting berdasarkan waktu =====
  String _getGreeting() {
    int jam = DateTime.now().hour;
    if (jam >= 6 && jam < 11) return "Selamat Pagi";
    if (jam >= 11 && jam < 15) return "Selamat Siang";
    if (jam >= 15 && jam < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  // ===== DIALOG TAMBAH CATATAN BARU =====
  void _showAddLogDialog() {
    showDialog(
      // context = informasi lokasi widget di "pohon widget"
      // builder = fungsi yang membangun widget dialog
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Catatan Baru"),
        content: Column(
          // mainAxisSize: MainAxisSize.min = Column hanya setinggi kontennya
          // tanpa ini, Column akan memenuhi seluruh tinggi dialog
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: "Judul Catatan"),
            ),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(hintText: "Isi Deskripsi"),
            ),
          ],
        ),
        actions: [
          // Tombol Batal — tutup dialog tanpa simpan
          TextButton(
            // Navigator.pop(context) = tutup halaman/dialog paling atas
            // Bayangkan tumpukan kartu: pop = angkat kartu paling atas
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          // Tombol Simpan — simpan data lalu tutup dialog
          ElevatedButton(
            onPressed: () {
              // Panggil addLog di Controller
              _controller.addLog(
                _titleController.text,
                _contentController.text,
              );


              // Bersihkan input field
              _titleController.clear();
              _contentController.clear();

              // Tutup dialog
              Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // ===== DIALOG EDIT CATATAN =====
  void _showEditLogDialog(int index, LogModel log) {
    // Pre-fill: isi TextField dengan data yang sudah ada
    // Sehingga user bisa melihat & mengedit data lama
    _titleController.text = log.title;
    _contentController.text = log.description;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Catatan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleController),
            TextField(controller: _contentController),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              // Panggil updateLog di Controller
              _controller.updateLog(
                index,
                _titleController.text,
                _contentController.text,
              );

              // Bersihkan input
              _titleController.clear();
              _contentController.clear();

              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ===== APP BAR =====
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
              // pushReplacement = ganti halaman saat ini dengan halaman baru
              // Bedanya dengan push: halaman lama DIHAPUS dari stack
              // Jadi user tidak bisa tekan tombol back untuk kembali
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingView()),
              );
            },
          ),
        ],
      ),

      // ===== BODY =====
      // ValueListenableBuilder = widget yang OTOMATIS rebuild saat
      // ValueNotifier yang didengarkannya berubah nilainya
      // Tidak perlu setState() — ini yang dimaksud "reactive"
      body: ValueListenableBuilder<List<LogModel>>(
        // valueListenable = notifier yang mau didengarkan
        valueListenable: _controller.logsNotifier,

        // builder dipanggil SETIAP KALI logsNotifier berubah
        // context = lokasi widget
        // currentLogs = nilai terbaru dari logsNotifier
        // child = widget statis (optimasi, tidak kita pakai di sini)
        builder: (context, currentLogs, child) {
          // Tampilkan pesan jika belum ada catatan
          if (currentLogs.isEmpty) {
            return const Center(child: Text("Belum ada catatan."));
          }

          // ListView.builder = membuat list secara LAZY
          // Hanya widget yang terlihat di layar yang dibangun
          // Efisien untuk data banyak
          return ListView.builder(
            // itemCount = jumlah total item di list
            itemCount: currentLogs.length,

            // itemBuilder = fungsi yang membangun SETIAP item
            // Dipanggil untuk setiap index (0, 1, 2, ...)
            itemBuilder: (context, index) {
              final log = currentLogs[index];

              return Card(
                child: ListTile(
                  // leading = widget di sisi KIRI
                  leading: const Icon(Icons.note),

                  // title = teks utama
                  title: Text(log.title),

                  // subtitle = teks sekunder (di bawah title)
                  subtitle: Text(log.description),

                  // trailing = widget di sisi KANAN
                  // Wrap = seperti Row tapi bisa wrap ke baris baru jika penuh
                  trailing: Wrap(
                    children: [
                      // Tombol Edit
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditLogDialog(index, log),
                      ),
                      // Tombol Delete
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

      // ===== FLOATING ACTION BUTTON =====
      // Tombol mengambang di pojok kanan bawah
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLogDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
