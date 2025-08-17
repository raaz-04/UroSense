import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  String? _gender;
  String? _selectedDevice;

  List<String> _availableDevices = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailableDevices();
  }

  Future<void> _fetchAvailableDevices() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('devices')
        .where('assigned', isEqualTo: false)
        .get();

    setState(() {
      _availableDevices =
          snapshot.docs.map((doc) => doc.id.toString()).toList();
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedDevice != null) {
      final patientRef = FirebaseFirestore.instance.collection('patients').doc();
      await patientRef.set({
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text),
        'gender': _gender,
        'deviceSerial': _selectedDevice,
        'admissionTime': Timestamp.now(),
        'status': 'active', // ✅ Add this line
      });

      // Update device status
      await FirebaseFirestore.instance
          .collection('devices')
          .doc(_selectedDevice)
          .update({
        'assigned': true,
        'patientId': patientRef.id,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Patient admitted successfully!")),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Patient")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Patient Name'),
                validator: (value) =>
                value!.isEmpty ? 'Enter patient name' : null,
              ),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
                validator: (value) =>
                value!.isEmpty ? 'Enter age' : null,
              ),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text("Male")),
                  DropdownMenuItem(value: 'Female', child: Text("Female")),
                  DropdownMenuItem(value: 'Other', child: Text("Other")),
                ],
                onChanged: (value) {
                  setState(() {
                    _gender = value;
                  });
                },
                validator: (value) =>
                value == null ? 'Select gender' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDevice,
                decoration:
                const InputDecoration(labelText: 'Assign Device Serial'),
                items: _availableDevices
                    .map((serial) => DropdownMenuItem(
                    value: serial, child: Text(serial)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDevice = value;
                  });
                },
                validator: (value) =>
                value == null ? 'Select a device' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text("Admit Patient"),
              )
            ],
          ),
        ),
      ),
    );
  }
}