import 'package:flutter/material.dart';
import 'household_setup_screen.dart';
import 'join_household_screen.dart';

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
            _buildActionButton(context, 'Create Household', const HouseholdSetupScreen()),
            const SizedBox(height: 20),
            _buildActionButton(context, 'Join Household', const JoinHouseholdScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, Widget screen) {
    return ElevatedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      ),
      child: Text(label),
    );
  }
}
