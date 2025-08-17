import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PatientHistoryScreen extends StatelessWidget {
  final String deviceSerial;

  const PatientHistoryScreen({super.key, required this.deviceSerial});

  @override
  Widget build(BuildContext context) {
    final dataRef = FirebaseFirestore.instance
        .collection('devices')
        .doc(deviceSerial)
        .collection('data')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text("Urine Output History")),
      body: StreamBuilder<QuerySnapshot>(
        stream: dataRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No history data available."));
          }

          final Map<String, List<double>> blockVolumes = {};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final ts = (data['timestamp'] as Timestamp).toDate();
            final volume = (data['volume'] ?? 0).toDouble();

            final blockStart = DateTime(ts.year, ts.month, ts.day, ts.hour);
            final label = DateFormat('yyyy-MM-dd HH:mm').format(blockStart);

            blockVolumes.putIfAbsent(label, () => []);
            blockVolumes[label]!.add(volume);
          }

          final sortedKeys = blockVolumes.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final label = sortedKeys[index];
              final readings = blockVolumes[label]!;
              final max = readings.reduce((a, b) => a > b ? a : b);
              final min = readings.reduce((a, b) => a < b ? a : b);
              final diff = max - min;

              return ListTile(
                title: Text("Block: $label"),
                subtitle: Text("Output: ${diff.toStringAsFixed(1)} mL"),
              );
            },
          );
        },
      ),
    );
  }
}