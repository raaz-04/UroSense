import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditPatientScreen extends StatefulWidget {
  final String patientId;
  const EditPatientScreen({super.key, required this.patientId});

  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController? nameController;
  TextEditingController? ageController;
  String gender = 'Male';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    final doc = await FirebaseFirestore.instance
        .collection('patients')
        .doc(widget.patientId)
        .get();
    final data = doc.data()!;
    setState(() {
      nameController = TextEditingController(text: data['name']);
      ageController = TextEditingController(text: data['age'].toString());
      gender = data['gender'];
      isLoading = false;
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .update({
        'name': nameController!.text.trim(),
        'age': int.parse(ageController!.text),
        'gender': gender,
      });

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Patient info updated")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || nameController == null || ageController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Patient")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (val) =>
                val == null || val.isEmpty ? "Enter name" : null,
              ),
              TextFormField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Age"),
                validator: (val) =>
                val == null || val.isEmpty ? "Enter age" : null,
              ),
              DropdownButtonFormField<String>(
                value: gender,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text("Male")),
                  DropdownMenuItem(value: 'Female', child: Text("Female")),
                  DropdownMenuItem(value: 'Other', child: Text("Other")),
                ],
                onChanged: (val) => setState(() => gender = val!),
                decoration: const InputDecoration(labelText: "Gender"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: _save, child: const Text("Save Changes")),
            ],
          ),
        ),
      ),
    );
  }
}