import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/ai_service.dart';
import 'jobs_screen.dart';

class CareerAdvisorScreen extends StatefulWidget {
  const CareerAdvisorScreen({super.key});

  @override
  State<CareerAdvisorScreen> createState() =>
      _CareerAdvisorScreenState();
}

class _CareerAdvisorScreenState
    extends State<CareerAdvisorScreen> {

  // ==========================================================
  // Controllers
  // ==========================================================

  final TextEditingController educationController =
  TextEditingController();

  final TextEditingController skillsController =
  TextEditingController();

  final TextEditingController interestsController =
  TextEditingController();

  final TextEditingController goalsController =
  TextEditingController();

  // ==========================================================
  // AI Service
  // ==========================================================

  final AIService _aiService = AIService();

  // ==========================================================
  // State
  // ==========================================================

  bool isLoading = false;

  Map<String, dynamic>? result;

  @override
  void dispose() {
    educationController.dispose();
    skillsController.dispose();
    interestsController.dispose();
    goalsController.dispose();

    super.dispose();
  }

  // ==========================================================
  // Get Career Advice
  // ==========================================================

  Future<void> getCareerAdvice() async {

    // Validate
    if (educationController.text.trim().isEmpty ||
        skillsController.text.trim().isEmpty ||
        interestsController.text.trim().isEmpty ||
        goalsController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete all fields first.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
      result = null;
    });

    try {

      // ======================================================
      // Call Gemini
      // ======================================================

      final aiResult =
      await _aiService.getCareerRecommendation(
        education:
        educationController.text.trim(),
        skills:
        skillsController.text.trim(),
        interests:
        interestsController.text.trim(),
        careerGoal:
        goalsController.text.trim(),
      );

      // ======================================================
      // Save JSON as String in Firestore
      // ======================================================

      final user =
          FirebaseAuth.instance.currentUser;

      if (user != null) {
        await _aiService.saveCareerRecommendation(
          userId: user.uid,
          education:
          educationController.text.trim(),
          skills:
          skillsController.text.trim(),
          interests:
          interestsController.text.trim(),
          careerGoal:
          goalsController.text.trim(),
          recommendation:
          jsonEncode(aiResult),
        );
      }

      if (!mounted) return;

      setState(() {
        result = aiResult;
        isLoading = false;
      });

    } catch (e) {

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // Build
  // ==========================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Career Advisor',
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // =================================================
            // Title
            // =================================================

            const Text(
              'Find Your Career Path 🚀',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Tell us about yourself and get '
                  'personalized career recommendations.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            // =================================================
            // Education
            // =================================================

            const Text(
              'Education',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: educationController,
              decoration: const InputDecoration(
                hintText:
                'e.g. BSc Computer Science',
                border: OutlineInputBorder(),
                prefixIcon:
                Icon(Icons.school),
              ),
            ),

            const SizedBox(height: 20),

            // =================================================
            // Skills
            // =================================================

            const Text(
              'Skills',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: skillsController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                'e.g. Java, Flutter, Dart, SQL',
                border: OutlineInputBorder(),
                prefixIcon:
                Icon(Icons.code),
              ),
            ),

            const SizedBox(height: 20),

            // =================================================
            // Interests
            // =================================================

            const Text(
              'Interests',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
              interestsController,
              maxLines: 3,
              decoration:
              const InputDecoration(
                hintText:
                'e.g. Software Development, AI, Web Development',
                border: OutlineInputBorder(),
                prefixIcon:
                Icon(Icons.favorite),
              ),
            ),

            const SizedBox(height: 20),

            // =================================================
            // Career Goal
            // =================================================

            const Text(
              'Career Goals',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
              goalsController,
              maxLines: 3,
              decoration:
              const InputDecoration(
                hintText:
                'e.g. Become a Full Stack Developer',
                border: OutlineInputBorder(),
                prefixIcon:
                Icon(Icons.flag),
              ),
            ),

            const SizedBox(height: 30),

            // =================================================
            // Button
            // =================================================

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed:
                isLoading
                    ? null
                    : getCareerAdvice,

                icon: isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.smart_toy,
                ),

                label: Text(
                  isLoading
                      ? 'Analyzing...'
                      : 'Get Career Advice',

                  style:
                  const TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ),

            // =================================================
            // AI Result
            // =================================================

            if (result != null) ...[
              const SizedBox(height: 35),

              _buildCareerResults(),

              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // Career Results
  // ==========================================================

  Widget _buildCareerResults() {

    final careers =
        result!['careers'] as List<dynamic>? ?? [];

    final strengths =
        result!['strengths'] as List<dynamic>? ?? [];

    final actionPlan =
        result!['actionPlan'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [

        const Text(
          'AI Career Recommendation',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 18),

        // ======================================================
        // Top 3 Careers
        // ======================================================

        const Text(
          'Top 3 Career Paths',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        ...careers.asMap().entries.map(
              (entry) {

            final index = entry.key;
            final career =
            entry.value as Map<String, dynamic>;

            final title =
                career['title']?.toString() ??
                    'Career';

            final whySuitable =
                career['whySuitable']
                    ?.toString() ??
                    '';

            final skills =
                career['skillsToDevelop']
                as List<dynamic>? ??
                    [];

            final learningAreas =
                career['learningAreas']
                as List<dynamic>? ??
                    [];

            final technologies =
                career['technologies']
                as List<dynamic>? ??
                    [];

            return _buildCareerCard(
              number: index + 1,
              title: title,
              whySuitable: whySuitable,
              skills: skills,
              learningAreas:
              learningAreas,
              technologies:
              technologies,
            );
          },
        ),

        // ======================================================
        // Strengths
        // ======================================================

        if (strengths.isNotEmpty) ...[
          const SizedBox(height: 15),

          const Text(
            'Your Current Strengths',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          ...strengths.map(
                (strength) => _buildBulletItem(
              strength.toString(),
              Icons.check_circle_outline,
            ),
          ),
        ],

        // ======================================================
        // Action Plan
        // ======================================================

        if (actionPlan.isNotEmpty) ...[
          const SizedBox(height: 20),

          const Text(
            'Short-Term Action Plan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          ...actionPlan.asMap().entries.map(
                (entry) {
              return _buildActionItem(
                number: entry.key + 1,
                text: entry.value.toString(),
              );
            },
          ),
        ],
      ],
    );
  }

  // ==========================================================
  // Career Card
  // ==========================================================

  Widget _buildCareerCard({
    required int number,
    required String title,
    required String whySuitable,
    required List<dynamic> skills,
    required List<dynamic> learningAreas,
    required List<dynamic> technologies,
  }) {

    return Card(
      elevation: 3,
      margin:
      const EdgeInsets.only(bottom: 18),

      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(16),
      ),

      child: Padding(
        padding:
        const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // =================================================
            // Career title
            // =================================================

            Row(
              children: [

                Container(
                  width: 42,
                  height: 42,
                  alignment:
                  Alignment.center,

                  decoration:
                  BoxDecoration(
                    color: Colors.blue,
                    borderRadius:
                    BorderRadius.circular(12),
                  ),

                  child: Text(
                    '$number',
                    style:
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    title,
                    style:
                    const TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // =================================================
            // Why suitable
            // =================================================

            const Text(
              'Why this career is suitable',
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              whySuitable,
              style: const TextStyle(
                height: 1.5,
              ),
            ),

            // =================================================
            // Skills
            // =================================================

            if (skills.isNotEmpty) ...[
              const SizedBox(height: 15),

              const Text(
                'Skills to develop',
                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              ...skills.map(
                    (skill) => _buildBulletItem(
                  skill.toString(),
                  Icons.code,
                ),
              ),
            ],

            // =================================================
            // Learning Areas
            // =================================================

            if (learningAreas.isNotEmpty) ...[
              const SizedBox(height: 15),

              const Text(
                'Learning Areas',
                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              ...learningAreas.map(
                    (area) => _buildBulletItem(
                  area.toString(),
                  Icons.menu_book_outlined,
                ),
              ),
            ],

            // =================================================
            // Technologies
            // =================================================

            if (technologies.isNotEmpty) ...[
              const SizedBox(height: 15),

              const Text(
                'Recommended Technologies',
                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              ...technologies.map(
                    (technology) =>
                    _buildBulletItem(
                      technology.toString(),
                      Icons.computer,
                    ),
              ),
            ],

            const SizedBox(height: 18),

            // =================================================
            // Related Jobs Button
            // =================================================

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          JobsScreen(
                            career: title,
                          ),
                    ),
                  );

                },

                icon: const Icon(
                  Icons.work_outline,
                ),

                label: const Text(
                  'Find Related Jobs',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // Bullet Item
  // ==========================================================

  Widget _buildBulletItem(
      String text,
      IconData icon,
      ) {

    return Padding(
      padding:
      const EdgeInsets.only(bottom: 7),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            size: 18,
            color: Colors.blue,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              text,
              style:
              const TextStyle(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Action Item
  // ==========================================================

  Widget _buildActionItem({
    required int number,
    required String text,
  }) {

    return Padding(
      padding:
      const EdgeInsets.only(bottom: 10),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Text(
            '$number.',
            style:
            const TextStyle(
              fontWeight:
              FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              text,
              style:
              const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}