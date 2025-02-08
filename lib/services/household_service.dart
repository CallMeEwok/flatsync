import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HouseholdService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, String>>> getHouseholdMembers() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final householdId = userDoc.data()?['householdId'];
    if (householdId == null) return [];

    final householdSnapshot = await _firestore
        .collection('users')
        .where('householdId', isEqualTo: householdId)
        .get();

    return householdSnapshot.docs.map((doc) {
      return {
        'uid': doc.id,
        'name': doc.data()['name']?.toString() ?? 'Unknown', // ✅ Ensuring proper type casting
      };
    }).toList();
  }
}
