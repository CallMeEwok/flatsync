import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GenerateInviteScreen extends StatefulWidget {
  final String householdId;

  const GenerateInviteScreen({required this.householdId, super.key});

  @override
  GenerateInviteScreenState createState() => GenerateInviteScreenState();
}

class GenerateInviteScreenState extends State<GenerateInviteScreen> {
  String? generatedInviteCode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchLatestInvite();
  }

  Future<void> fetchLatestInvite() async {
    try {
      debugPrint("Fetching latest invite for household: ${widget.householdId}");

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("invites")
          .where("householdId", isEqualTo: widget.householdId)
          .where("used", isEqualTo: false)
          .orderBy("createdAt", descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint("No active invite found for household ID: ${widget.householdId}");
        setState(() {
          generatedInviteCode = null;
        });
        return;
      }

      var inviteData = snapshot.docs.first.data() as Map<String, dynamic>;
        debugPrint("Invite Data Retrieved: $inviteData");

        // Ensure 'expiresAt' exists before using it
        if (!inviteData.containsKey("expiresAt")) {
          debugPrint("⚠️ Missing field 'expiresAt' in Firestore document. Skipping...");
          return;
        }

        setState(() {
          generatedInviteCode = inviteData["inviteCode"] ?? "UNKNOWN_INVITE_CODE";
        });

    } catch (e) {
      debugPrint("Error fetching invite: $e");
    }
  }

  Future<void> _generateInvite() async {
    setState(() {
      _isLoading = true;
      generatedInviteCode = null; // Reset before generating a new one
    });

    final String inviteCode = const Uuid().v4();
    final Timestamp expiresAt = Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24)));

    try {
      await FirebaseFirestore.instance.collection('invites').doc(inviteCode).set({
        "householdId": widget.householdId,
        "invitedBy": FirebaseAuth.instance.currentUser!.uid,
        "inviteCode": inviteCode,
        "expiresAt": expiresAt,
        "used": false,
        "createdAt": Timestamp.now(),
      });

      if (mounted) {
        setState(() {
          generatedInviteCode = inviteCode;
        });

        debugPrint("✅ Generated Invite Code: $generatedInviteCode");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite generated successfully!')),
        );
      }
    } catch (e) {
      debugPrint("❌ Error generating invite: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate invite: $e')),
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

  Future<void> _revokeInvite(String inviteCode) async {
    try {
      await FirebaseFirestore.instance.collection('invites').doc(inviteCode).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite revoked successfully!')),
        );
      }

      // Refresh the invite list after deletion
      fetchLatestInvite();
    } catch (e) {
      debugPrint("❌ Error revoking invite: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to revoke invite: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Household Invite')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _generateInvite,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Generate Invite Code'),
            ),
            const SizedBox(height: 16),
            if (generatedInviteCode != null && generatedInviteCode!.isNotEmpty) ...[
              const Text('Share this invite code:', style: TextStyle(fontSize: 16)),
              SelectableText(generatedInviteCode!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Center(
                child: QrImageView(
                  data: generatedInviteCode!,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                  ),
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _revokeInvite(generatedInviteCode!),
                child: const Text("Revoke Invite"),
              ),
            ] else ...[
              const SizedBox(height: 16),
              const Text('No invite generated yet', textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            const Text('Active Invites:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('invites')
                    .where('householdId', isEqualTo: widget.householdId)
                    .where('used', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final invites = snapshot.data!.docs;
                  if (invites.isEmpty) {
                    return const Center(child: Text('No active invites'));
                  }

                  return ListView.builder(
                    itemCount: invites.length,
                    itemBuilder: (context, index) {
                      final invite = invites[index];
                      final inviteCode = invite['inviteCode'];

                      return ListTile(
                        title: Text('Invite Code: $inviteCode'),
                        subtitle: Text(
                          invite['expiresAt'] != null
                              ? 'Expires: ${invite['expiresAt'].toDate()}'
                              : 'Expires: Unknown',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _revokeInvite(inviteCode),
                        ),
                      );
                    },
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
