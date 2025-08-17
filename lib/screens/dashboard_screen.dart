import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient_details_screen.dart';
import 'discharged_patients_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patientsRef = FirebaseFirestore.instance
        .collection('patients')
        .where('status', isNotEqualTo: 'discharged')
        .orderBy('status') // Required when using isNotEqualTo
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Patients"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Discharged Patients",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DischargedPatientsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: patientsRef,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("Firestore error: ${snapshot.error}");
            return const Center(child: Text("Something went wrong"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No patients admitted yet."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['name'] ?? 'Unknown'),
                subtitle: Text("Device: ${data['deviceSerial'] ?? 'N/A'}"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PatientDetailsScreen(patientId: doc.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
