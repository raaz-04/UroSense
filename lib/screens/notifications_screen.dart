import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient_details_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Icon _getIcon(String type) {
    switch (type) {
      case 'low_volume':
        return const Icon(Icons.warning, color: Colors.orange);
      case 'high_volume':
        return const Icon(Icons.warning_amber, color: Colors.deepOrange);
      case 'color_blood':
        return const Icon(Icons.water_drop, color: Colors.red);
      case 'color_bilirubin':
        return const Icon(Icons.water_drop, color: Colors.purple);
      case 'color_abnormal':
        return const Icon(Icons.water_drop, color: Colors.blue);
      default:
        return const Icon(Icons.notification_important, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alerts")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .orderBy('time', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading alerts"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No alerts yet."));
          }

          final alerts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final data = alerts[index].data() as Map<String, dynamic>;
              final type = data['type'] ?? 'unknown';
              final patientName = data['patientName'] ?? 'Unknown';
              final message = data['message'] ?? 'No details';
              final time = (data['time'] as Timestamp).toDate().toLocal();
              final patientId = data['patientId'];

              return ListTile(
                leading: _getIcon(type),
                title: Text("$patientName: $message"),
                subtitle: Text("Time: ${time.toString().substring(0, 16)}"),
                onTap: () {
                  if (patientId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientDetailsScreen(patientId: patientId),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}


