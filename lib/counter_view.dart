import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});
  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Reset"),
          content: const Text("Apakah Anda yakin ingin mereset counter?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _controller.reset();
                });
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: const Text("Ya"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LogBook: Versi SRP"),
        titleTextStyle: const TextStyle(
          fontSize: 23,
          color: Color.fromARGB(255, 255, 255, 255),
        ),
        leading: const Icon(
          Icons.book,
          color: Color.fromARGB(255, 255, 255, 255),
        ),
        centerTitle: true,
          backgroundColor: const Color.fromARGB(255, 77, 80, 255),
      ),
      body: Column(
            children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: const Text(
                      "Total Hitungan:",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.tonal(
                        onPressed: () =>
                            setState(() => _controller.decrement()),
                        child: const Icon(Icons.remove),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        '${_controller.value}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(width: 15),
                      FilledButton.tonal(
                        onPressed: () =>
                            setState(() => _controller.increment()),
                        child: const Icon(Icons.add),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            19,
                            216,
                            121,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: _controller.step.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _controller.step.toString(),
                    onChanged: (double value) {
                      setState(() {
                        _controller.step = value.toInt();
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton.tonal(
                    onPressed: () => _confirmReset(),
                    child: const Text("Reset Counter"),
                    style: FilledButton.styleFrom(backgroundColor: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Riwayat Perubahan:",
                    style: TextStyle(fontSize: 18),
                  ),
                  Expanded(
                    child:  ListView.builder(
                      itemCount: _controller.history.length,
                      itemBuilder: (context, index) {

                         final item = _controller.history.reversed.toList()[index];

                         Color cardColor;
                         IconData iconData;
                          if (item.startsWith('Incremented')) {
                            cardColor = Colors.greenAccent;
                            iconData = Icons.add;
                          } else if (item.startsWith('Decremented')) {
                            cardColor = Colors.redAccent;
                            iconData = Icons.remove;
                          } else {
                            cardColor = Colors.grey;
                            iconData = Icons.refresh;
                          }

                          return Card(
                            color: cardColor,
                            child: ListTile(
                              leading: Icon(iconData),
                              title: Text(item),
                            ),
                          );

                         
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}           