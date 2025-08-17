import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_new_project/admin_panel_page.dart';
import 'package:my_new_project/instructions_page.dart';
import 'package:my_new_project/settings_page.dart';

import 'decision_tree.dart';
import 'auth/login_page.dart';
import 'home_page.dart';
import 'auth/sign_up_page.dart';
import 'upcoming_events_page.dart';
import 'claim_volunteer_hours_page.dart';

import 'dart:developer';
import 'dart:io'; // To check the platform

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // Use initialRoute instead of home
      routes: {
        '/': (context) =>
            const InitializationScreen(), // Set InitializationScreen as the default route
        '/login': (context) => const LoginPage(onSignInAno: null),
        '/home': (context) => const HomePage(),
        '/signup': (context) => const SignUpPage(),
        '/settings': (context) => const SettingsPage(),
        '/upcoming_events': (context) => const UpcomingEventsPage(),
        '/claim_volunteer_hours': (context) => const ClaimVolunteerHoursPage(),
        '/instructions': (context) => const InstructionsPage(),
        '/admin': (context) => const AdminPanelPage(),
      },
    );
  }
}

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  InitializationScreenState createState() => InitializationScreenState();
}

class InitializationScreenState extends State<InitializationScreen> {
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      FirebaseOptions firebaseOptions;

      if (Platform.isIOS) {
        firebaseOptions = const FirebaseOptions(
          apiKey: 'AIzaSyCPO-3FdKZ727XMFR4W7NWY8sING9mG8BI',
          appId: '1:1053330545319:ios:3f4d1a0aad71f7af269982',
          messagingSenderId: '1053330545319',
          projectId: 'childrensmusicbrigade3',
          storageBucket: 'childrensmusicbrigade3.appspot.com',
        );
      } else if (Platform.isAndroid) {
        firebaseOptions = const FirebaseOptions(
          apiKey: 'AIzaSyB5z52BJ2aoNAzrRyLX8lxeWBK5dzk7xIw',
          appId: '1:557882758965:android:275b6bedb16d443f791e7c',
          messagingSenderId: '1053330545319',
          projectId: 'childrensmusicbrigade3',
          storageBucket: 'childrensmusicbrigade3.appspot.com',
        );
      } else {
        throw UnsupportedError("Platform not supported");
      }

      await Firebase.initializeApp(
        options: firebaseOptions,
      );

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      log('Error initializing Firebase: $e');
      setState(() {
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return const Scaffold(
        body: Center(child: Text('Error initializing Firebase')),
      );
    }

    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If Firebase is initialized, navigate to the main screen
    return const DecisionTree();
  }
}
