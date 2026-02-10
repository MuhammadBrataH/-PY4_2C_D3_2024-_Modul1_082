class CounterController {
  int _counter = 0; // Variabel private (Enkapsulasi)

  int get value => _counter; // Getter untuk akses data

  int _step = 5; // Langkah default
  int get step => _step; // Getter untuk langkah
  set step(int newStep) => _step = newStep; // Setter untuk langkah
  void increment() => _counter += _step; // Menambah langkah sebesar 5
  void decrement() {
    if (_counter > 0) _counter -= _step;
  }

  void reset() => _counter = 0;
}
