// login_view.dart
import 'package:flutter/material.dart';
// Import Controller milik sendiri (masih satu folder)
import 'package:logbook_app_082/features/auth/login_controller.dart';
// Import View dari fitur lain (Logbook) untuk navigasi
import 'package:logbook_app_082/features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Inisialisasi Otak dan Controller Input
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  int failedAttempts =
      0; // Menambahkan variabel untuk menghitung percobaan gagal
  bool isLocked = false; // Menambahkan variabel untuk status terkunci
  bool _obscurePassword =
      true; // Menambahkan variabel untuk toggle visibility password

  void _handleLogin() {
    String user = _userController.text;
    String pass = _passController.text;

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username dan Password tidak boleh kosong!"),
          backgroundColor: Color( 0xFFE57373), // Warna merah untuk error
        ),
      );
      return;
    }

    bool isSuccess = _controller.login(user, pass);

    if (isSuccess) {
      failedAttempts = 0; // Reset percobaan gagal jika login berhasil
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // Di sini kita kirimkan variabel 'user' ke parameter 'username' di CounterView
          builder: (context) => LogView(username: user),
        ),
      );
    } else {
      setState(() {
        failedAttempts++;
      });

      if (failedAttempts >= 3) {
        setState(() {
          isLocked = true;
        }); // Kunci login setelah 3 percobaan gagal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Terlalu banyak percobaan gagal! Tunggu 10 detik."),
            backgroundColor: Color(0xFFE57373), // Warna merah untuk error
          ),  
        );
        Future.delayed(const Duration(seconds: 10), () {
          setState(() {
            failedAttempts = 0; // Reset percobaan gagal setelah waktu tunggu
            isLocked = false; // Buka kunci login
          });
        });
      } else
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Gagal! percobaan ke-$failedAttempts dari 3."),
            backgroundColor: const Color(0xFFE57373), // Warna merah untuk error
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Gatekeeper")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passController,
              obscureText: _obscurePassword, // Menyembunyikan teks password
              decoration: InputDecoration(
                labelText: "Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLocked ? null : _handleLogin,
              child: Text(isLocked ? "Tunggu..." : "Masuk"),
            ),
          ],
        ),
      ),
    );
  }
}
