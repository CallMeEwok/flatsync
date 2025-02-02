// Core Flutter and Firebase packages
import 'package:flatsync_app/screens/generate_invite_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Firebase configuration
import 'firebase_options.dart';

// Screens
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/household_selection_screen.dart';
import 'screens/household_setup_screen.dart';
import 'screens/manage_household_screen.dart';
import 'screens/shopping_list_screen.dart';
import 'screens/chores_screen.dart';
import 'screens/expense_tracker_screen.dart';
import 'screens/message_board_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/pending_invitations_screen.dart';
import 'screens/choose_household_action_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FlatSyncApp());
}

class FlatSyncApp extends StatelessWidget {
  const FlatSyncApp({super.key});

  Future<String?> _getHouseholdId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null; // No logged-in user
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc["householdId"]; // Return household ID
      }
    } catch (e) {
      debugPrint("Error fetching household ID: $e");
    }
    return null; // Fallback in case of an error
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlatSync',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) {
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData) {
                return const HomeScreen(); // User is logged in
              } else {
                return const WelcomeScreen(); // User is not logged in
              }
            },
          );
        },
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/choose-household-action': (context) => const ChooseHouseholdActionScreen(),
        '/select-household': (context) => const HouseholdSelectionScreen(),
        '/setup-household': (context) => const HouseholdSetupScreen(),
        '/manage-household': (context) => const ManageHouseholdScreen(),
        '/pending-invitations': (context) => const PendingInvitationsScreen(),
        '/shopping-list': (context) => const ShoppingListScreen(),
        '/chores': (context) => const ChoresScreen(),
        '/expense-tracker': (context) => const ExpenseTrackerScreen(),
        '/message-board': (context) => const MessageBoardScreen(),
        '/settings-page': (context) => const SettingsScreen(),

        // ✅ Fixed: Fetches `householdId` before navigating to `GenerateInviteScreen`
        '/generate-invite': (context) {
          return FutureBuilder<String?>(
            future: _getHouseholdId(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData && snapshot.data != null) {
                return GenerateInviteScreen(householdId: snapshot.data!);
              } else {
                return const Scaffold(
                  body: Center(child: Text("Error: Household ID not found")),
                );
              }
            },
          );
        },
      },
    );
  }
}
