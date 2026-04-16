// login_controller.dart
class LoginController {
  // Simulasi database user lengkap dengan role, uid, dan teamId
  final List<Map<String, String>> _users = [
    {
      'username': 'admin',
      'password': '123',
      'role': 'Ketua',
      'uid': 'u001',
      'teamId': 'team_alpha',
    },
    {
      'username': 'brata',
      'password': '123',
      'role': 'Anggota',
      'uid': 'u002',
      'teamId': 'team_alpha',
    },
  ];

  // Return Map user jika berhasil, null jika gagal
  Map<String, String>? login(String username, String password) {
    try {
      return _users.firstWhere(
        (u) => u['username'] == username && u['password'] == password,
      );
    } catch (_) {
      return null;
    }
  }
}
