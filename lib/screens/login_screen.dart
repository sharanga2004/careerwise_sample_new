import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

import 'package:careerwise_sample/widgets/custom_button.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  late VideoPlayerController _videoController;

  bool isLoading = false;
  bool isResettingPassword = false;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset(
      'assets/videos/career_background.mp4',
    )
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController.play();
        }
      });
  }

  Future<bool> checkAdmin(String uid) async {
    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();

      if (!adminDoc.exists) {
        return false;
      }

      final data = adminDoc.data();

      return data?['role'] == 'admin';
    } catch (e) {
      debugPrint('Admin check error: $e');
      return false;
    }
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        'Please enter email and password',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final UserCredential credential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        throw Exception('Login failed. User not found.');
      }

      debugPrint('LOGIN SUCCESS: ${user.email}');
      debugPrint('UID: ${user.uid}');

      final bool isAdmin = await checkAdmin(user.uid);

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (isAdmin) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
            const AdminDashboardScreen(),
          ),
              (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'too-many-requests') {
        message =
        'Too many attempts. Please try again later.';
      } else if (e.code == 'network-request-failed') {
        message =
        'Network error. Please check your internet connection.';
      }

      debugPrint('LOGIN ERROR: ${e.code}');
      debugPrint('LOGIN MESSAGE: ${e.message}');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage(message);
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage('Login error: $e');
    }
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showMessage(
        'Please enter your email address first.',
      );
      return;
    }

    setState(() {
      isResettingPassword = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      _showMessage(
        'Password reset email sent. Please check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      String message =
          'Could not send password reset email.';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'network-request-failed') {
        message =
        'Network error. Please check your internet connection.';
      }

      if (!mounted) return;

      _showMessage(message);
    } catch (e) {
      debugPrint('PASSWORD RESET ERROR: $e');

      if (!mounted) return;

      _showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isResettingPassword = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  InputDecoration modernInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: Colors.white.withOpacity(0.75),
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.10),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFF60A5FA),
          width: 1.5,
        ),
      ),
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.55),
        fontSize: 14,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --------------------------------------------------
          // VIDEO BACKGROUND
          // --------------------------------------------------
          Positioned.fill(
            child: _videoController.value.isInitialized
                ? FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width:
                _videoController.value.size.width,
                height:
                _videoController.value.size.height,
                child: VideoPlayer(
                  _videoController,
                ),
              ),
            )
                : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF020617),
                    Color(0xFF0F2A5A),
                    Color(0xFF172554),
                  ],
                ),
              ),
            ),
          ),

          // --------------------------------------------------
          // DARK OVERLAY
          // --------------------------------------------------
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.48),
            ),
          ),

          // --------------------------------------------------
          // BLUE GLOW
          // --------------------------------------------------
          Positioned(
            top: -180,
            right: -120,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB)
                    .withOpacity(0.18),
              ),
            ),
          ),

          Positioned(
            bottom: -200,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6)
                    .withOpacity(0.12),
              ),
            ),
          ),

          // --------------------------------------------------
          // LOGIN CONTENT
          // --------------------------------------------------
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 35,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 470,
                      ),
                      child: _buildGlassLoginCard(),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 22,
          sigmaY: 22,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            32,
            32,
            32,
            30,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.105),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: 45,
                offset: const Offset(0, 25),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // LOGO
              // --------------------------------------------------
              Center(
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 40,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // --------------------------------------------------
              // TITLE
              // --------------------------------------------------
              const Center(
                child: Text(
                  'CareerWise',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
              ),

              const SizedBox(height: 7),

              Center(
                child: Text(
                  'AI-Assisted Career Decision Support',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Welcome back 👋',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                'Sign in to continue your career journey.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 27),

              // --------------------------------------------------
              // EMAIL
              // --------------------------------------------------
              const Text(
                'Email address',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 9),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                decoration: modernInputDecoration(
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 19),

              // --------------------------------------------------
              // PASSWORD
              // --------------------------------------------------
              const Text(
                'Password',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 9),

              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!isLoading) {
                    login();
                  }
                },
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                decoration: modernInputDecoration(
                  hint: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword =
                        !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color:
                      Colors.white.withOpacity(0.75),
                      size: 21,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 5),

              // --------------------------------------------------
              // FORGOT PASSWORD
              // --------------------------------------------------
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed:
                  (isLoading || isResettingPassword)
                      ? null
                      : forgotPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                  ),
                  child: Text(
                    isResettingPassword
                        ? 'Sending...'
                        : 'Forgot Password?',
                    style: const TextStyle(
                      color: Color(0xFF93C5FD),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // --------------------------------------------------
              // SIGN IN BUTTON
              // --------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 55,
                child: CustomButton(
                  text: isLoading
                      ? 'Signing in...'
                      : 'Sign In',
                  onPressed: isLoading ? null : login,
                ),
              ),

              const SizedBox(height: 24),

              // --------------------------------------------------
              // DIVIDER
              // --------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color:
                      Colors.white.withOpacity(0.15),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                    ),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color:
                        Colors.white.withOpacity(0.50),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color:
                      Colors.white.withOpacity(0.15),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // --------------------------------------------------
              // REGISTER BUTTON
              // --------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const RegisterScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color:
                      Colors.white.withOpacity(0.30),
                    ),
                    backgroundColor:
                    Colors.white.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Create New Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // --------------------------------------------------
              // FOOTER
              // --------------------------------------------------
              Center(
                child: Text(
                  'Your Career. Your Future. Your Choice.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}