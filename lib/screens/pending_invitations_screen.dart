import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PendingInvitationsScreen extends StatefulWidget {
  const PendingInvitationsScreen({super.key});

  @override
  State<PendingInvitationsScreen> createState() => _PendingInvitationsScreenState();
}

class _PendingInvitationsScreenState extends State<PendingInvitationsScreen> {
  final String? userEmail = FirebaseAuth.instance.currentUser?.email;
  bool _isLoading = false;

  Future<String> _getHouseholdName(String householdId) async {
    try {
      final householdDoc = await FirebaseFirestore.instance.collection('households').doc(householdId).get();
      return (householdDoc.exists && householdDoc.data() != null)
          ? (householdDoc.data()?['name'] as String? ?? 'Unnamed Household')
          : 'Unknown Household';
    } catch (e) {
      return 'Unknown Household';
    }
  }

  Future<void> _acceptInvitation(String invitationId, String householdId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'householdId': householdId,
      });

      await FirebaseFirestore.instance.collection('household_invitations').doc(invitationId).update({
        'status': 'Accepted',
      });

      if (!mounted) return; // Ensure the widget is still active
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have joined the household!')),
      );

      Navigator.pushReplacementNamed(context, '/manage-household');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept invitation: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _declineInvitation(String invitationId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('household_invitations').doc(invitationId).update({
        'status': 'Declined',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation declined')),
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline invitation: $e')),
      );
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
    if (userEmail == null) {
      return const Scaffold(
        body: Center(child: Text('No user signed in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Invitations')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('household_invitations')
            .where('email', isEqualTo: userEmail)
            .where('status', isEqualTo: 'Pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final invitations = snapshot.data!.docs;
          if (invitations.isEmpty) {
            return const Center(child: Text('No pending invitations'));
          }

          return ListView.builder(
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              final invitationId = invitation.id;
              final householdId = invitation['householdId'];

              return FutureBuilder<String>(
                future: _getHouseholdName(householdId),
                builder: (context, householdSnapshot) {
                  final householdName = householdSnapshot.data ?? 'Loading...';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text('Invitation to join: $householdName'),
                      trailing: _isLoading
                          ? const CircularProgressIndicator()
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () => _acceptInvitation(invitationId, householdId),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () => _declineInvitation(invitationId),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
