import 'dart:async';
import 'package:vibration/vibration.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stride Watch',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const StridePage(),
    );
  }
}

class StridePage extends StatefulWidget {
  const StridePage({super.key});

  @override
  State<StridePage> createState() => _StridePageState();
}

class _StridePageState extends State<StridePage> {
  List<int> strides = [30, 45, 60];

  int currentIndex = 0;
  int remaining = 0;

  bool isRunning = false;
  Timer? ticker;

  Future<void> vibrate({int times = 1}) async {
    if (await Vibration.hasVibrator() ?? false) {
      for (int i = 0; i < times; i++) {
        Vibration.vibrate(duration: 200);
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  void start() {
    if (strides.isEmpty) return;

    setState(() {
      isRunning = true;

      if (remaining == 0 || currentIndex >= strides.length) {
        currentIndex = 0;
        remaining = strides[currentIndex];
      }
    });

    startTicker();
  }

  void pause() {
    setState(() {
      isRunning = false;
    });
    stopTicker();
  }

  void reset() {
    stopTicker();
    setState(() {
      isRunning = false;
      currentIndex = 0;
      remaining = strides.isNotEmpty ? strides[0] : 0;
    });
  }

  void startTicker() {
    ticker ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (remaining > 0) {
          remaining--;

          // Vibrate once at 5 seconds remaining
          if (remaining == 5) {
            vibrate(times: 1);
          }
        } else {
          // Vibrate twice when interval ends
          vibrate(times: 2);

          // Next interval
          currentIndex++;
          if (currentIndex >= strides.length) {
            currentIndex = 0; // loop
            vibrate(times: 4);
          }

          remaining = strides[currentIndex];
        }
      });
    });
  }

  void stopTicker() {
    ticker?.cancel();
    ticker = null;
  }

  @override
  void dispose() {
    stopTicker();
    super.dispose();
  }

  void changeInterval(int index, int delta) {
    if (isRunning) return;

    setState(() {
      strides[index] = (strides[index] + delta).clamp(5, 3600);

      if (!isRunning && index == currentIndex) {
        remaining = strides[index];
      }
    });
  }

  void addInterval() {
    if (isRunning) return;

    setState(() {
      strides.add(30);
      if (strides.length == 1) {
        currentIndex = 0;
        remaining = 30;
      }
    });
  }

  void removeInterval(int index) {
    if (isRunning) return;

    setState(() {
      strides.removeAt(index);

      if (strides.isEmpty) {
        currentIndex = 0;
        remaining = 0;
        return;
      }

      if (currentIndex >= strides.length) {
        currentIndex = strides.length - 1;
      }

      remaining = strides[currentIndex];
    });
  }

  String formatSeconds(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;

    if (m == 0) return "$s s";
    return "${m}m ${s.toString().padLeft(2, '0')}s";
  }

  @override
  Widget build(BuildContext context) {
    final hasStrides = strides.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text("Stride Watch"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (hasStrides) ...[
              Text(
                "Stride ${currentIndex + 1}/${strides.length}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Text(
                  formatSeconds(remaining),
                  style: const TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Expanded(
              child: ListView.builder(
                itemCount: strides.length,
                itemBuilder: (context, index) {
                  final seconds = strides[index];
                  final isCurrent = index == currentIndex;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          AdjustButton(
                            label: '--',
                            onTap: isRunning
                                ? null
                                : () => changeInterval(index, -10),
                          ),
                          AdjustButton(
                            label: '-',
                            onTap: isRunning
                                ? null
                                : () => changeInterval(index, -5),
                          ),
                          const SizedBox(width: 4),

                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? Colors.blue
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  formatSeconds(seconds),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 4),

                          AdjustButton(
                            label: '+',
                            onTap: isRunning
                                ? null
                                : () => changeInterval(index, 5),
                          ),
                          AdjustButton(
                            label: '++',
                            onTap: isRunning
                                ? null
                                : () => changeInterval(index, 10),
                          ),

                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: isRunning
                                ? null
                                : () => removeInterval(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isRunning ? null : addInterval,
                icon: const Icon(Icons.add),
                label: const Text("Add interval"),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: hasStrides ? (isRunning ? pause : start) : null,
                    child: Text(isRunning ? "Pause" : "Start"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: hasStrides ? reset : null,
                    child: const Text("Reset"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdjustButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const AdjustButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    IconData icon;

    switch (label) {
      case '--':
        icon = Icons.fast_rewind;
        break;
      case '-':
        icon = Icons.remove;
        break;
      case '+':
        icon = Icons.add;
        break;
      case '++':
        icon = Icons.fast_forward;
        break;
      default:
        icon = Icons.help;
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        child: IconButton(
          icon: Icon(icon),
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(40, 40),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 1,
          ),
        ),
      ),
    );
  }
}
