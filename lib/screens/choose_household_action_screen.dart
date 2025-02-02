import 'package:flutter/material.dart';

class ChooseHouseholdActionScreen extends StatelessWidget {
  const ChooseHouseholdActionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Household Action'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton(context, 'Create Household', '/setup-household'),
            const SizedBox(height: 20),
            _buildActionButton(context, 'Join Household', '/join-household'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, String route) {
    return ElevatedButton(
      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, route, (route) => false),
      child: Text(label),
    );
  }
}
