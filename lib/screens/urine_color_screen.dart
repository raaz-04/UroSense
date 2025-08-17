import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UrineColorScreen extends StatefulWidget {
  final String deviceSerial;
  const UrineColorScreen({super.key, required this.deviceSerial});

  @override
  State<UrineColorScreen> createState() => _UrineColorScreenState();
}

class _UrineColorScreenState extends State<UrineColorScreen> {
  Color? urineColor;
  String colorLabel = "Unknown";

  @override
  void initState() {
    super.initState();
    _listenToColor();
  }

  void _listenToColor() {
    FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceSerial)
        .collection('data')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      final data = snapshot.docs.first.data();
      final r = data['r'] ?? 255;
      final g = data['g'] ?? 255;
      final b = data['b'] ?? 255;

      final color = Color.fromARGB(255, r, g, b);
      final label = _getColorLabel(r, g, b);

      setState(() {
        urineColor = color;
        colorLabel = label;
      });
    });
  }

  String _getColorLabel(int r, int g, int b) {
    if (r > 150 && g < 100 && b < 100) return "Blood Presence";
    if (r > 180 && g > 160 && b < 100) return "Bilirubin";
    if (r < 100 && g < 100 && b > 180) return "Abnormal (Blue Tint)";
    if (r > 230 && g > 230 && b > 230) return "Clear";
    return "Normal";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Urine Color Monitor")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              colorLabel,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              backgroundColor: urineColor ?? Colors.grey,
              radius: 50,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Back"),
            )
          ],
        ),
      ),
    );
  }
}