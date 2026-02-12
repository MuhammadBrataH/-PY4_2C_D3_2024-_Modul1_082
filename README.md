## Self-Reflection: Prinsip SRP dan Fitur History Logger

Bagaimana prinsip SRP membantu saat menambah fitur History Logger?

Dengan menerapkan prinsip SRP, kode terpisah menjadi:
- Counter_Controller -> bertanggung jawab di logika bisnis (hitung, reset, riwayat)
- Counter_View -> bertanggung jawab di tampilan UI

Saat menambahkan fitur History Logger, saya hanya perlu menambahkan atribut `_history` dan logika pencatatan riwayat di `CounterController` tanpa perlu mengubah struktur UI. 

Di bagian View, saya cukup menambahkan widget `ListView.builder` untuk menampilkan data history yang sudah disediakan oleh Controller.

Jika semua kode dicampur jadi satu file, menambah fitur baru akan lebih sulit karena harus memilah mana logika dan mana tampilan. SRP membuat kode lebih mudah dipahami, diubah, dan diperbaiki.