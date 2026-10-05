import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CareerHistoryScreen extends StatelessWidget {
  const CareerHistoryScreen({super.key});

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Date unavailable';
    }

    final date = timestamp.toDate();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year • $hour:$minute $period';
  }

  Future<void> deleteRecommendation(
      BuildContext context,
      String documentId,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Recommendation?'),
          content: const Text(
            'Are you sure you want to delete this recommendation?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('career_recommendations')
          .doc(documentId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Recommendation deleted successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete recommendation: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Career History'),
        ),
        body: const Center(
          child: Text(
            'Please log in to view your career history.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career History'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('career_recommendations')
            .where(
          'userId',
          isEqualTo: user.uid,
        )
            .snapshots(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to load career history.\n\n'
                      '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          // Empty
          if (documents.isEmpty) {
            return _buildEmptyState(context);
          }

          // Sort newest first
          final sortedDocuments =
          List<QueryDocumentSnapshot>.from(documents);

          sortedDocuments.sort((a, b) {
            final dataA =
            a.data() as Map<String, dynamic>;

            final dataB =
            b.data() as Map<String, dynamic>;

            final timestampA =
            dataA['createdAt'] as Timestamp?;

            final timestampB =
            dataB['createdAt'] as Timestamp?;

            if (timestampA == null &&
                timestampB == null) {
              return 0;
            }

            if (timestampA == null) {
              return 1;
            }

            if (timestampB == null) {
              return -1;
            }

            return timestampB.compareTo(timestampA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDocuments.length,
            itemBuilder: (context, index) {
              final document =
              sortedDocuments[index];

              final data =
              document.data()
              as Map<String, dynamic>;

              final education =
                  data['education']?.toString() ??
                      'Not provided';

              final skills =
                  data['skills']?.toString() ??
                      'Not provided';

              final interests =
                  data['interests']?.toString() ??
                      'Not provided';

              final careerGoal =
                  data['careerGoal']?.toString() ??
                      'Not provided';

              final recommendation =
                  data['recommendation']?.toString() ??
                      '';

              final createdAt =
              data['createdAt'] as Timestamp?;

              return _buildRecommendationCard(
                context: context,
                documentId: document.id,
                education: education,
                skills: skills,
                interests: interests,
                careerGoal: careerGoal,
                recommendation: recommendation,
                createdAt: createdAt,
              );
            },
          );
        },
      ),
    );
  }

  // ==========================================================
  // Recommendation Card
  // ==========================================================

  Widget _buildRecommendationCard({
    required BuildContext context,
    required String documentId,
    required String education,
    required String skills,
    required String interests,
    required String careerGoal,
    required String recommendation,
    required Timestamp? createdAt,
  }) {
    final careers = _extractCareers(recommendation);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Text(
                    'AI Career Analysis',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                IconButton(
                  tooltip: 'Delete',
                  onPressed: () {
                    deleteRecommendation(
                      context,
                      documentId,
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Date
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 7),
                Text(
                  formatDate(createdAt),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // User information
            _buildInfoRow(
              Icons.school_outlined,
              'Education',
              education,
            ),

            const SizedBox(height: 10),

            _buildInfoRow(
              Icons.flag_outlined,
              'Career Goal',
              careerGoal,
            ),

            const SizedBox(height: 18),

            // Top careers
            if (careers.isNotEmpty) ...[
              const Text(
                'Recommended Career Paths',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              ...careers.take(3).toList().asMap().entries.map(
                    (entry) {
                  final career = entry.value;

                  final title =
                      career['title']?.toString() ??
                          'Career';

                  return Container(
                    margin:
                    const EdgeInsets.only(bottom: 8),
                    padding:
                    const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.06),
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          child: Text(
                            '${entry.key + 1}',
                            style:
                            const TextStyle(
                              fontSize: 13,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            title,
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 12),

            // View full result
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CareerHistoryDetailScreen(
                            education: education,
                            skills: skills,
                            interests: interests,
                            careerGoal: careerGoal,
                            recommendation:
                            recommendation,
                            date: formatDate(
                              createdAt,
                            ),
                          ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.visibility_outlined,
                ),
                label: const Text(
                  'View Full Recommendation',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // Extract careers from JSON
  // ==========================================================

  List<Map<String, dynamic>> _extractCareers(
      String recommendation,
      ) {
    try {
      final decoded =
      jsonDecode(recommendation);

      if (decoded is Map<String, dynamic>) {
        final careers =
        decoded['careers'];

        if (careers is List) {
          return careers
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      }
    } catch (_) {
      // Old recommendation format
    }

    return [];
  }

  // ==========================================================
  // Info Row
  // ==========================================================

  Widget _buildInfoRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.blue,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                maxLines: 2,
                overflow:
                TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // Empty State
  // ==========================================================

  Widget _buildEmptyState(
      BuildContext context,
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [

            const Icon(
              Icons.history,
              size: 70,
              color: Colors.blue,
            ),

            const SizedBox(height: 20),

            const Text(
              'No Career History Yet',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Generate your first AI career '
                  'recommendation and it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.auto_awesome,
              ),
              label: const Text(
                'Get Career Advice',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DETAIL SCREEN
// ============================================================

class CareerHistoryDetailScreen
    extends StatelessWidget {
  final String education;
  final String skills;
  final String interests;
  final String careerGoal;
  final String recommendation;
  final String date;

  const CareerHistoryDetailScreen({
    super.key,
    required this.education,
    required this.skills,
    required this.interests,
    required this.careerGoal,
    required this.recommendation,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? result;

    try {
      final decoded =
      jsonDecode(recommendation);

      if (decoded is Map<String, dynamic>) {
        result = decoded;
      }
    } catch (_) {
      result = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Career Recommendation',
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            const Text(
              'Your Career Assessment',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              date,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Your Information',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _detailBox(
              Icons.school_outlined,
              'Education',
              education,
            ),

            _detailBox(
              Icons.code_outlined,
              'Skills',
              skills,
            ),

            _detailBox(
              Icons.favorite_outline,
              'Interests',
              interests,
            ),

            _detailBox(
              Icons.flag_outlined,
              'Career Goal',
              careerGoal,
            ),

            const SizedBox(height: 15),

            const Text(
              'AI Career Recommendation',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            if (result != null)
              _buildStructuredResult(result!)
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    recommendation,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // Structured Result
  // ==========================================================

  Widget _buildStructuredResult(
      Map<String, dynamic> result,
      ) {
    final careers =
        result['careers'] as List<dynamic>? ?? [];

    final strengths =
        result['strengths'] as List<dynamic>? ?? [];

    final actionPlan =
        result['actionPlan'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [

        // Careers
        const Text(
          'Top 3 Career Paths',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        ...careers.asMap().entries.map(
              (entry) {
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

            return _careerCard(
              number: entry.key + 1,
              title: title,
              whySuitable: whySuitable,
              skills: skills,
              learningAreas: learningAreas,
              technologies: technologies,
            );
          },
        ),

        // Strengths
        if (strengths.isNotEmpty) ...[
          const SizedBox(height: 18),

          const Text(
            'Current Strengths',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          ...strengths.map(
                (item) => _bullet(
              item.toString(),
              Icons.check_circle_outline,
            ),
          ),
        ],

        // Action plan
        if (actionPlan.isNotEmpty) ...[
          const SizedBox(height: 18),

          const Text(
            'Short-Term Action Plan',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          ...actionPlan.asMap().entries.map(
                (entry) {
              return Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 8,
                ),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key + 1}.',
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style:
                        const TextStyle(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
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

  Widget _careerCard({
    required int number,
    required String title,
    required String whySuitable,
    required List<dynamic> skills,
    required List<dynamic> learningAreas,
    required List<dynamic> technologies,
  }) {
    return Card(
      elevation: 2,
      margin:
      const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    '$number',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    title,
                    style:
                    const TextStyle(
                      fontSize: 19,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            const Text(
              'Why suitable',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              whySuitable,
              style:
              const TextStyle(
                height: 1.5,
              ),
            ),

            if (skills.isNotEmpty) ...[
              const SizedBox(height: 12),

              const Text(
                'Skills to develop',
                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              ...skills.map(
                    (skill) => _bullet(
                  skill.toString(),
                  Icons.code,
                ),
              ),
            ],

            if (learningAreas.isNotEmpty) ...[
              const SizedBox(height: 12),

              const Text(
                'Learning areas',
                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              ...learningAreas.map(
                    (area) => _bullet(
                  area.toString(),
                  Icons.menu_book_outlined,
                ),
              ),
            ],

            if (technologies.isNotEmpty) ...[
              const SizedBox(height: 12),

              const Text(
                'Technologies',
                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              ...technologies.map(
                    (technology) => _bullet(
                  technology.toString(),
                  Icons.computer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // Detail Box
  // ==========================================================

  Widget _detailBox(
      IconData icon,
      String title,
      String value,
      ) {
    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius:
        BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // Bullet
  // ==========================================================

  Widget _bullet(
      String text,
      IconData icon,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
            color: Colors.blue,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}