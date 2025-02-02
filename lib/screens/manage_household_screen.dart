// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageHouseholdScreen extends StatefulWidget {
  const ManageHouseholdScreen({super.key});

  @override
  State<ManageHouseholdScreen> createState() => _ManageHouseholdScreenState();
}

class _ManageHouseholdScreenState extends State<ManageHouseholdScreen> {
  String? householdId;
  String? currentUserId;
  String? currentUserRole;
  bool _isLoading = true;
  List<Map<String, dynamic>> members = [];

  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _loadHouseholdData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      currentUserId = user.uid;
      print('Fetching user document for: $currentUserId');

      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        print('User document fetched: ${userDoc.data()}');

        if (mounted) {
          setState(() {
            householdId = userDoc.data()?['householdId'];
            currentUserRole = userDoc.data()?['role'];
          });

          print('User householdId: $householdId, role: $currentUserRole');

          if (householdId != null) {
            await _fetchHouseholdMembers();
            await _ensureHouseholdHasOwner();
          } else {
            print('No household found for user.');
          }
        }
      } catch (e) {
        print('Error loading household data: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchHouseholdMembers() async {
    if (householdId == null) {
      print('No household ID found. Skipping member fetch.');
      return;
    }

    print('Fetching members for household: $householdId');

    try {
      final membersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('householdId', isEqualTo: householdId)
          .get();

      if (mounted) {
        setState(() {
          members = membersQuery.docs.map((doc) => {
                ...doc.data(),
                'uid': doc.id,
              }).toList();
        });

        print('Household members fetched: ${members.length}');
      }
    } catch (e) {
      print('Error fetching household members: $e');
    }
  }

  Future<void> _ensureHouseholdHasOwner() async {
    if (householdId == null) return;

    try {
      final membersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('householdId', isEqualTo: householdId)
          .get();

      if (membersQuery.docs.length == 1) {
        final singleMember = membersQuery.docs.first;
        final memberRole = singleMember['role'];

        if (memberRole != 'Owner') {
          await FirebaseFirestore.instance.collection('users').doc(singleMember.id).update({
            'role': 'Owner',
          });
          print('Single household member promoted to Owner');
        }
      }
    } catch (e) {
      print('Error ensuring household has an owner: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHouseholdData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (householdId == null) {
      return const Scaffold(
        body: Center(child: Text('You are not part of a household.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Household'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text('Invite Members'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, '/generate-invite');
              },
            ),
            const Text(
              'Household Members',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            members.isEmpty
                ? const Center(child: Text('No members found.'))
                : Expanded(
                    child: ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        // ignore: unused_local_variable
                        final memberId = member['uid'];
                        final memberName = member['name'] ?? 'Unknown';
                        final memberRole = member['role'] ?? 'Member';

                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(memberName),
                          subtitle: Text(member['email'] ?? 'No email'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                memberRole,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: memberRole == 'Owner' ? Colors.blue : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
