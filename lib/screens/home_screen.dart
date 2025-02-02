import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlatSync'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Add padding for better layout
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center buttons vertically
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch buttons to full width
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/shopping-list'); // Navigate to Shopping List
              },
              child: const Text('Go to Shopping List'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/chores'); // Navigate to Chores Page
              },
              child: const Text('Go to Chores'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/expense-tracker'); // Navigate to Expense Tracker
              },
              child: const Text('Go to Expense Tracker'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/message-board'); // Navigate to Message Board
              },
              child: const Text('Go to Message Board'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/pending-invitations');
              },
              child: const Text("Go to Pending Invites"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/settings-page'); // Navigate to Settings
              },
              child: const Text('Go to Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
