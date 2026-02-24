// login_controller.dart
class LoginController {
  // Database sederhana (Hardcoded)
  final Map<String, String> _users = {"admin": "123", "brata": "123"};

  // Fungsi pengecekan (Logic-Only)
  // Fungsi ini mengembalikan true jika cocok, false jika salah.
  bool login(String username, String password) {
    if (_users.containsKey(username) && _users[username] == password) {
      return _users[username] == password;
    }
    return false;
  }
}
