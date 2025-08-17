import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DischargedPatientsScreen extends StatelessWidget {
  const DischargedPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dischargedRef = FirebaseFirestore.instance
        .collection('patients')
        .where('status', isEqualTo: 'discharged')
        .orderBy('dischargedTime', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text("Discharged Patients")),
      body: StreamBuilder<QuerySnapshot>(
        stream: dischargedRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text("No discharged patients."));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? 'Unknown'),
                subtitle: Text("Device: ${data['deviceSerial'] ?? 'N/A'}"),
                trailing: Text(
                  (data['dischargedTime'] as Timestamp?)?.toDate().toLocal().toString().substring(0, 16) ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}