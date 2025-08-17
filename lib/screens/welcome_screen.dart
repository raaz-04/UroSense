import 'package:flutter/material.dart';
import 'login_screen.dart'; // Import LoginScreen
import 'package:cloud_firestore/cloud_firestore.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 120,
            ),
            const SizedBox(height: 40),
            const Text(
              "Welcome to UroSense",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              "Monitor urine output. Detect abnormality. Assist patients in real-time.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // 🔁 Firestore connection test
                FirebaseFirestore.instance
                    .collection('test')
                    .doc('hello')
                    .set({'message': 'UroSense connected to Firestore!'});

                // 🔁 Navigate to login screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text("Get Started"),
            )

          ],
        ),
      ),
    );
  }
}
