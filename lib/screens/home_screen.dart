import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in.")),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ModalRoute.of(context)?.settings.name != '/login') {
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
          return const Scaffold(
            body: Center(child: Text("User data not found. Redirecting...")),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String? householdId = userData['householdId'];

        if (householdId == null || householdId.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ModalRoute.of(context)?.settings.name != '/choose-household-action') {
              Navigator.pushReplacementNamed(context, '/choose-household-action');
            }
          });
          return const Scaffold(
            body: Center(child: Text("No household found. Redirecting...")),
          );
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('households').doc(householdId).snapshots(),
          builder: (context, householdSnapshot) {
            if (householdSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (!householdSnapshot.hasData || !householdSnapshot.data!.exists) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ModalRoute.of(context)?.settings.name != '/choose-household-action') {
                  Navigator.pushReplacementNamed(context, '/choose-household-action');
                }
              });
              return const Scaffold(
                body: Center(child: Text("Household data not found. Redirecting...")),
              );
            }

            final householdData = householdSnapshot.data!.data() as Map<String, dynamic>;
            final String householdName = householdData['name'] ?? "Unknown Household";

            return Scaffold(
              appBar: AppBar(
                title: Text('FlatSync - $householdName'),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/shopping-list');
                      },
                      child: const Text('Go to Shopping List'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/chores');
                      },
                      child: const Text('Go to Chores'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/expense-tracker');
                      },
                      child: const Text('Go to Expense Tracker'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/message-board');
                      },
                      child: const Text('Go to Message Board'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/settings-page');
                      },
                      child: const Text('Go to Settings'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
