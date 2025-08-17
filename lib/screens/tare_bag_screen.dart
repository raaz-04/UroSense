// --- PHASE 1: Tare + Bag Volume Setting Screen ---
// New Screen: TareBagScreen (appears after patient admission or bag replacement)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TareBagScreen extends StatefulWidget {
  final String deviceId;
  const TareBagScreen({super.key, required this.deviceId});

  @override
  State<TareBagScreen> createState() => _TareBagScreenState();
}

class _TareBagScreenState extends State<TareBagScreen> {
  String? selectedVolume;
  final List<String> presetVolumes = ['500', '1000', '1500', '2000'];

  bool isLoading = false;

  void _tareAndSave() async {
    if (selectedVolume == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a bag volume")),
      );
      return;
    }

    setState(() => isLoading = true);

    await FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId)
        .update({
      'isTared': true,
      'tareTime': Timestamp.now(),
      'bagCapacity': int.parse(selectedVolume!),
      'bagReplaced': true,
    });

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Device tared and bag volume set!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tare & Set Bag Volume")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Select catheter bag volume (ml):",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: presetVolumes.map((volume) {
                return ChoiceChip(
                  label: Text("$volume ml"),
                  selected: selectedVolume == volume,
                  onSelected: (_) => setState(() => selectedVolume = volume),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : _tareAndSave,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Tare Device & Save"),
            )
          ],
        ),
      ),
    );
  }
}

// ✅ TODO NEXT:
// In AddPatientScreen and PatientDetailsScreen → After patient admitted or bag replaced,
// push this TareBagScreen with the respective deviceId.

// PHASE 2 will include volume tracking from tareTime per time blocks.
// PHASE 3 will include RGB color detection logic and alerts.