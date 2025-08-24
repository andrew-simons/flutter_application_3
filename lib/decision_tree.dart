import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_new_project/admin_panel_page.dart';
import 'package:my_new_project/instructions_page.dart';
import 'auth/login_page.dart';
import 'home_page.dart';
import 'upcoming_events_page.dart';
import 'settings_page.dart';
import 'claim_volunteer_hours_page.dart';
import 'dart:async';

import 'dart:developer';

class DecisionTree extends StatefulWidget {
  const DecisionTree({super.key});

  @override
  State<DecisionTree> createState() => _DecisionTreeState();
}

class _DecisionTreeState extends State<DecisionTree> {
  User? user;
  int selectedIndex = 0;
  late StreamSubscription<User?> authSubscription;
  bool isAdmin = false; // Variable to store admin status

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          this.user = user;
          if (user != null) {
            _checkIfAdmin(user.uid);
          } else {
            isAdmin = false;
          }
        });
      }
    });
  }

  Future<void> _checkIfAdmin(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          isAdmin = userDoc['role'] == 'admin';
        });
      }
    } catch (e) {
      // Handle errors if necessary
      log('Error fetching user role: $e');
    }
  }

  @override
  void dispose() {
    authSubscription.cancel();
    super.dispose();
  }

  void onRefresh(User? userCred) {
    if (mounted) {
      setState(() {
        user = userCred;
        if (user != null) {
          _checkIfAdmin(user!.uid); // Null check
        } else {
          isAdmin = false;
        }
      });
    }
  }

  void _navigateTo(int index) {
    if (!mounted) return; // Ensure the widget is still in the tree

    setState(() {
      selectedIndex = index;
    });
    Navigator.pop(context);
  }

  Future<void> _logOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const LoginPage(onSignInAno: null)),
        );
      }
    } catch (e) {
      // Handle sign out error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return LoginPage(onSignInAno: onRefresh);
    }

    Widget currentPage;
    switch (selectedIndex) {
      case 0:
        currentPage = const HomePage();
        break;
      case 1:
        currentPage = const UpcomingEventsPage();
        break;
      case 2:
        currentPage = const InstructionsPage();
        break;
      case 3:
        currentPage = const ClaimVolunteerHoursPage();
        break;
      case 4:
        currentPage = const SettingsPage();
        break;
      case 5:
        currentPage = const AdminPanelPage();
        break;
      default:
        currentPage = const HomePage();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Children\'s Music Brigade Inc.',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color.fromARGB(255, 31, 114, 156),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w500),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => _navigateTo(0),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Sign Up for Upcoming Events'),
              onTap: () => _navigateTo(1),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('View Performance Instructions'),
              onTap: () => _navigateTo(2),
            ),
            ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: const Text('Volunteer Hours'),
              onTap: () => _navigateTo(3),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Account / Settings'),
              onTap: () => _navigateTo(4),
            ),
            if (isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Admin Panel'),
                onTap: () => _navigateTo(5),
              ),
            ],
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Log Out',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () => _logOut(),
            ),
          ],
        ),
      ),
      body: currentPage,
    );
  }
}
