// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HouseholdSelectionScreen extends StatefulWidget {
  const HouseholdSelectionScreen({super.key});

  @override
  State<HouseholdSelectionScreen> createState() => _HouseholdSelectionScreenState();
}

class _HouseholdSelectionScreenState extends State<HouseholdSelectionScreen> {
  bool _isChecking = true; // Track if check is in progress

  @override
  void initState() {
    super.initState();
    _checkHousehold(); // Start household check immediately
  }

  Future<void> _checkHousehold() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      setState(() {
        _isChecking = false;
      });
      return;
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final householdId = userDoc.data()?['householdId'];

      if (!mounted) return; // Ensure widget is still in the tree before navigation

      if (householdId != null) {
        print("Navigating to Manage Household");
        Navigator.pushReplacementNamed(context, '/manage-household');
      } else {
        print("Navigating to Choose Household Action");
        Navigator.pushReplacementNamed(context, '/choose-household-action');
      }
    } catch (e) {
      print("Error fetching household info: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking household: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isChecking
            ? const CircularProgressIndicator()
            : const Text('Redirecting...'),
      ),
    );
  }
}
