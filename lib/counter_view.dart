import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});
  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LogBook: Versi SRP")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Total Hitungan:", style: TextStyle( fontSize: 18)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonal(
                  onPressed: () => setState(() => _controller.decrement()),
                  child: const Icon(Icons.remove),
                  style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                ),
                const SizedBox(width: 15),
                Text(
                  '${_controller.value}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(width: 15),
                FilledButton.tonal(
                  onPressed: () => setState(() => _controller.increment()),
                  child: const Icon(Icons.add),
                  style: FilledButton.styleFrom(backgroundColor: Colors.greenAccent),
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
              onPressed: () => setState(() =>  _controller.reset()),
              child: const Text("Reset Counter"),
              style: FilledButton.styleFrom(backgroundColor: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
