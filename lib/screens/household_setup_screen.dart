// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HouseholdSetupScreen extends StatefulWidget {
  const HouseholdSetupScreen({super.key});

  @override
  State<HouseholdSetupScreen> createState() => _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends State<HouseholdSetupScreen> {
  final TextEditingController _householdNameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createHousehold() async {
    final householdName = _householdNameController.text.trim();
    if (householdName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a household name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final docRef = FirebaseFirestore.instance.collection('households').doc();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in')),
          );
        }
        return;
      }

      // Create the household document
      await docRef.set({
        'name': householdName,
        'createdAt': FieldValue.serverTimestamp(),
        'owner': user.uid,
      });

      // Update user document with householdId
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'householdId': docRef.id,
        'role': 'Owner', // The creator is always the Owner
      });

      // Verify household assignment
      final updatedUserDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final updatedHouseholdId = updatedUserDoc.data()?['householdId'];

      if (updatedHouseholdId == docRef.id) {
        print('Household ID successfully updated in Firestore.');
      } else {
        print('Household ID update delay detected.');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Household created successfully!')),
        );
        Navigator.pushReplacementNamed(context, '/manage-household');
      }
    } catch (e) {
      print("Error creating household: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create household: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Household')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _householdNameController,
              decoration: const InputDecoration(
                labelText: 'Household Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _createHousehold,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Create Household'),
            ),
          ],
        ),
      ),
    );
  }
}
