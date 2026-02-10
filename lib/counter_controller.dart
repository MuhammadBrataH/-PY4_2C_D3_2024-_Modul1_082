class CounterController {
  int _counter = 0; // Variabel private (Enkapsulasi)
  int get value => _counter; // Getter untuk akses data

  int _step = 5; // Langkah default
  int get step => _step; // Getter untuk langkah

  List<String> _history = []; // Contoh tambahan atribut
  List<String> get history => _history; // Getter untuk riwayat

  DateTime _lastUpdated = DateTime.now(); // Atribut tambahan
  DateTime get lastUpdated => _lastUpdated; // Getter untuk lastUpdated

  set step(int newStep) => _step = newStep; // Setter untuk langkah
  void increment() {
    _counter += _step; // Menambah langkah sebesar 5
    _history.add("Incremented by $_step to $_counter at $_lastUpdated");
    if (_history.length > 5) {
      _history.removeAt(0); // Menjaga riwayat tetap 10 entri
    }
    _lastUpdated = DateTime.now();
  }

  void decrement() {
    if (_counter > 0) {
      _counter -= _step;
      _history.add("Decremented by $_step to $_counter at $_lastUpdated");
    }
    if (_history.length > 5) {
      _history.removeAt(0); // Menjaga riwayat tetap 10 entri
    }
    _lastUpdated = DateTime.now();
  }

  void reset() {
    _counter = 0;
    _history.clear();
    _history.add("Counter reset to 0 at $_lastUpdated");
  }
}
