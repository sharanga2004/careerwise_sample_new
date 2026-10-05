import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    providerWeb: WebDebugProvider(
      debugToken: 'a97a2c69-82c0-4c5f-8801-e9ffdbcff5d2',
    ),
  );

  // ==============================
  // NOTIFICATIONS
  // ==============================

  // Register background handler before runApp()
  if (NotificationService.isSupported) {
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );
  }

  // Initialize notification service
  await NotificationService.instance.init();

  runApp(const CareerWiseApp());
}

class CareerWiseApp extends StatelessWidget {
  const CareerWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CareerWise',

      // Allows notifications to navigate to app screens
      navigatorKey: appNavigatorKey,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),

      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> checkAdmin(String uid) async {
    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();

      if (!adminDoc.exists) {
        return false;
      }

      final data = adminDoc.data() as Map<String, dynamic>;

      return data['role'] == 'admin';
    } catch (e) {
      debugPrint('Admin check error: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ==============================
        // LOADING
        // ==============================
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // ==============================
        // USER LOGGED IN
        // ==============================
        if (snapshot.hasData) {
          final user = snapshot.data!;

          return FutureBuilder<bool>(
            future: checkAdmin(user.uid),
            builder: (context, adminSnapshot) {
              // Checking admin status
              if (adminSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // ==============================
              // ADMIN
              // ==============================
              if (adminSnapshot.data == true) {
                return const AdminDashboardScreen();
              }

              // ==============================
              // NORMAL USER
              // ==============================
              return const HomeScreen();
            },
          );
        }

        // ==============================
        // NOT LOGGED IN
        // ==============================
        return const LoginScreen();
      },
    );
  }
}