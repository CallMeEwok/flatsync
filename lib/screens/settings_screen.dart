import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut(); // Sign out the user
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/', // Redirect to the root route (LoginScreen)
          (route) => false, // Remove all routes from the stack
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Household'),
            subtitle: const Text('Join or manage your household'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              if (context.mounted) {
                Navigator.pushNamed(context, '/select-household'); // Navigate to Household Selection
              }
            },
          ),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: true, // Replace with a variable later
            onChanged: (bool value) {
              // Handle enabling/disabling notifications
            },
          ),
          ListTile(
            title: const Text('Clear All Data'),
            subtitle: const Text('Reset the app to its default state'),
            trailing: const Icon(Icons.delete),
            onTap: () {
              // Add functionality to clear local data
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('About FlatSync'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.info),
            onTap: () {
              if (context.mounted) {
                showAboutDialog(
                  context: context,
                  applicationName: 'FlatSync',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2025 FlatSync Inc.',
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Logout'),
            trailing: const Icon(Icons.logout),
            onTap: () => _logout(context), // Call logout function
          ),
        ],
      ),
    );
  }
}
