import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:careerwise_sample/model/job.dart';
import 'package:careerwise_sample/services/job_service.dart';

import 'job_details_screen.dart';
import 'jobs_screen.dart';
import 'career_advisor_screen.dart';
import 'career_history_screen.dart';
import 'my_applications_screen.dart';
import 'profile_screen.dart';
import 'notification_settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    final String userName =
    user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'Career Explorer';

    final String initial =
    userName.isNotEmpty ? userName[0].toUpperCase() : 'C';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ==========================================================
            // HEADER
            // ==========================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CareerWise',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Your AI Career Companion',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const NotificationSettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==========================================================
            // GREETING
            // ==========================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good to see you 👋',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Hello, $userName',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Let AI help you discover your next career opportunity.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==========================================================
            // AI CAREER ADVISOR
            // ==========================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildCareerAdvisorCard(context),
              ),
            ),

            // ==========================================================
            // CAREER OVERVIEW TITLE
            // ==========================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: _buildSectionHeader(
                  title: 'Your Career Overview',
                  subtitle: 'Your current CareerWise journey',
                ),
              ),
            ),

            // ==========================================================
            // CAREER OVERVIEW
            // ==========================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildCareerOverview(),
              ),
            ),

            // ==========================================================
            // RECOMMENDED JOBS TITLE
            // ==========================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 14),
                child: _buildSectionHeader(
                  title: 'Recommended Jobs',
                  subtitle:
                  'Based on your latest AI career recommendation',
                  showViewAll: true,
                  onViewAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const JobsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ==========================================================
            // RECOMMENDED JOBS
            // ==========================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildRecommendedJobs(),
              ),
            ),

            // ==========================================================
            // QUICK ACCESS TITLE
            // ==========================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 14),
                child: _buildSectionHeader(
                  title: 'Quick Access',
                  subtitle: 'Everything you need in one place',
                ),
              ),
            ),

            // ==========================================================
            // QUICK ACCESS
            // ==========================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 35),
                child: _buildQuickAccess(context),
              ),
            ),

            // ==========================================================
            // FOOTER
            // ==========================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 30,
                ),
                child: _buildFooter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // AI CAREER ADVISOR CARD
  // ================================================================
  Widget _buildCareerAdvisorCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF4F46E5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 25,
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'AI POWERED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            'Discover Your Career Path',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Get personalized career recommendations based on your education, skills, interests and goals.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CareerAdvisorScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2563EB),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(
                Icons.auto_awesome,
                size: 19,
              ),
              label: const Text(
                'Get Career Advice',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SECTION HEADER
  // ================================================================
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    bool showViewAll = false,
    VoidCallback? onViewAll,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),

        if (showViewAll)
          GestureDetector(
            onTap: onViewAll,
            child: const Text(
              'View All',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
      ],
    );
  }

  // ================================================================
  // GET ALL USER RECOMMENDATIONS
  // ================================================================
  Stream<QuerySnapshot> _latestRecommendationStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    // Do NOT use orderBy() or limit(1) here.
    //
    // We get all recommendations for this user and
    // sort them by createdAt in Dart.
    //
    // This avoids Firestore index/orderBy problems.
    return FirebaseFirestore.instance
        .collection('career_recommendations')
        .where(
      'userId',
      isEqualTo: user.uid,
    )
        .snapshots();
  }

  // ================================================================
  // GET LATEST RECOMMENDATION DOCUMENT
  // ================================================================
  QueryDocumentSnapshot? _getLatestRecommendation(
      QuerySnapshot snapshot,
      ) {
    if (snapshot.docs.isEmpty) {
      return null;
    }

    final documents =
    List<QueryDocumentSnapshot>.from(snapshot.docs);

    // Sort newest first
    documents.sort((a, b) {
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

    // First document is the newest
    return documents.first;
  }

  // ================================================================
  // PARSE RECOMMENDATION
  // ================================================================
  Map<String, dynamic>? _parseRecommendation(dynamic value) {
    if (value == null) {
      return null;
    }

    try {
      // If recommendation is already a Map
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }

      // If recommendation is stored as JSON String
      if (value is String) {
        final decoded = jsonDecode(value);

        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  // ================================================================
  // GET CAREER FROM RECOMMENDATION
  // ================================================================
  String? _getCareerFromRecommendation(
      dynamic recommendation,
      ) {
    final parsed =
    _parseRecommendation(recommendation);

    if (parsed == null) {
      return null;
    }

    final careers = parsed['careers'];

    if (careers is List && careers.isNotEmpty) {
      final firstCareer = careers.first;

      if (firstCareer is Map) {
        final title = firstCareer['title'];

        if (title != null) {
          final career =
          title.toString().trim();

          if (career.isNotEmpty) {
            return career;
          }
        }
      }
    }

    return null;
  }

  // ================================================================
  // CAREER OVERVIEW
  // ================================================================
  Widget _buildCareerOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: _latestRecommendationStream(),
      builder: (context, snapshot) {
        String education = 'Not added';
        String career = 'Not decided';
        String skills = 'Not added';

        if (snapshot.hasData &&
            snapshot.data!.docs.isNotEmpty) {
          // IMPORTANT:
          // Get the newest recommendation instead of
          // simply taking docs.first.
          final latestDocument =
          _getLatestRecommendation(
            snapshot.data!,
          );

          if (latestDocument != null) {
            final data =
            latestDocument.data()
            as Map<String, dynamic>;

            education =
                (data['education'] ?? 'Not added')
                    .toString()
                    .trim();

            skills =
                (data['skills'] ?? 'Not added')
                    .toString()
                    .trim();

            final careerResult =
            _getCareerFromRecommendation(
              data['recommendation'],
            );

            if (careerResult != null) {
              career = careerResult;
            }
          }
        }

        return Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildOverviewCard(
                icon: Icons.school_outlined,
                title: 'Education',
                value: _shortText(
                  education.isEmpty
                      ? 'Not added'
                      : education,
                  18,
                ),
                iconColor:
                const Color(0xFF2563EB),
                backgroundColor:
                const Color(0xFFEFF6FF),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _buildOverviewCard(
                icon: Icons.route_outlined,
                title: 'Career Path',
                value: _shortText(
                  career,
                  18,
                ),
                iconColor:
                const Color(0xFF7C3AED),
                backgroundColor:
                const Color(0xFFF5F3FF),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _buildOverviewCard(
                icon: Icons.code_rounded,
                title: 'Skills',
                value: _shortText(
                  skills.isEmpty
                      ? 'Not added'
                      : skills,
                  18,
                ),
                iconColor:
                const Color(0xFF059669),
                backgroundColor:
                const Color(0xFFECFDF5),
              ),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // OVERVIEW CARD
  // ================================================================
  Widget _buildOverviewCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      constraints: const BoxConstraints(
        minHeight: 135,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),

          const SizedBox(height: 25),

          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            value,
            maxLines: 2,
            overflow:
            TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight:
              FontWeight.w700,
              color: Color(0xFF111827),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // RECOMMENDED JOBS
  // ================================================================
  Widget _buildRecommendedJobs() {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildEmptyJobs(
        'Please login to see recommended jobs.',
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _latestRecommendationStream(),
      builder: (
          context,
          recommendationSnapshot,
          ) {
        if (recommendationSnapshot
            .connectionState ==
            ConnectionState.waiting) {
          return _buildLoadingJobs();
        }

        if (recommendationSnapshot.hasError) {
          return _buildEmptyJobs(
            'Unable to load your career recommendation.',
          );
        }

        if (!recommendationSnapshot.hasData ||
            recommendationSnapshot
                .data!.docs.isEmpty) {
          return _buildNoCareerRecommendation();
        }

        // IMPORTANT:
        // Do NOT use docs.first.
        //
        // Get the newest recommendation based
        // on createdAt.
        final latestDocument =
        _getLatestRecommendation(
          recommendationSnapshot.data!,
        );

        if (latestDocument == null) {
          return _buildNoCareerRecommendation();
        }

        final data =
        latestDocument.data()
        as Map<String, dynamic>;

        // Get career from latest recommendation
        final career =
        _getCareerFromRecommendation(
          data['recommendation'],
        );

        if (career == null ||
            career.isEmpty) {
          return _buildNoCareerRecommendation();
        }

        // Get jobs related to the latest career
        return StreamBuilder<List<Job>>(
          stream:
          JobService().getRelatedJobs(career),
          builder: (
              context,
              jobSnapshot,
              ) {
            if (jobSnapshot
                .connectionState ==
                ConnectionState.waiting) {
              return _buildLoadingJobs();
            }

            if (jobSnapshot.hasError) {
              return _buildEmptyJobs(
                'Unable to load recommended jobs.',
              );
            }

            final jobs =
                jobSnapshot.data ?? [];

            // Maximum 3 recommended jobs
            final recommendedJobs =
            jobs.take(3).toList();

            if (recommendedJobs.isEmpty) {
              return _buildNoMatchingJobs(
                career,
              );
            }

            return Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(0xFFEFF6FF),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 15,
                        color:
                        Color(0xFF2563EB),
                      ),

                      const SizedBox(width: 7),

                      Flexible(
                        child: Text(
                          'Recommended for $career',
                          overflow:
                          TextOverflow.ellipsis,
                          style:
                          const TextStyle(
                            fontSize: 12,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                ...recommendedJobs.map(
                      (job) => Padding(
                    padding:
                    const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child:
                    _buildRecommendedJobCard(
                      context,
                      job,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================================================================
  // RECOMMENDED JOB CARD
  // ================================================================
  Widget _buildRecommendedJobCard(
      BuildContext context,
      Job job,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                JobDetailsScreen(
                  job: job,
                ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(19),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withOpacity(0.035),
              blurRadius: 12,
              offset:
              const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color:
                const Color(0xFFEFF6FF),
                borderRadius:
                BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.business_center_outlined,
                color:
                Color(0xFF2563EB),
                size: 25,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 15,
                      fontWeight:
                      FontWeight.w800,
                      color:
                      Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    job.company,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 12,
                      color:
                      Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color:
                        Color(0xFF9CA3AF),
                      ),

                      const SizedBox(width: 3),

                      Expanded(
                        child: Text(
                          job.location,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style:
                          const TextStyle(
                            fontSize: 11,
                            color:
                            Color(0xFF6B7280),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Flexible(
                        child: Container(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            const Color(
                              0xFFECFDF5,
                            ),
                            borderRadius:
                            BorderRadius
                                .circular(7),
                          ),
                          child: Text(
                            job.jobType,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style:
                            const TextStyle(
                              fontSize: 9,
                              fontWeight:
                              FontWeight.w700,
                              color:
                              Color(0xFF047857),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.chevron_right_rounded,
              color:
              Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // NO CAREER RECOMMENDATION
  // ================================================================
  Widget _buildNoCareerRecommendation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color:
              const Color(0xFFEFF6FF),
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color:
              Color(0xFF2563EB),
              size: 27,
            ),
          ),

          const SizedBox(height: 13),

          const Text(
            'Get your personalized job recommendations',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Complete the AI Career Advisor to discover jobs that match your career path.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color:
              Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // NO MATCHING JOBS
  // ================================================================
  Widget _buildNoMatchingJobs(
      String career,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color:
          const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.work_off_outlined,
            size: 42,
            color:
            Color(0xFF9CA3AF),
          ),

          const SizedBox(height: 12),

          Text(
            'No jobs found for $career',
            textAlign:
            TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'New opportunities will appear here when matching jobs are available.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color:
              Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // LOADING JOBS
  // ================================================================
  Widget _buildLoadingJobs() {
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
        ),
      ),
    );
  }

  // ================================================================
  // EMPTY JOBS
  // ================================================================
  Widget _buildEmptyJobs(
      String message,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color:
          const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        message,
        textAlign:
        TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color:
          Color(0xFF6B7280),
        ),
      ),
    );
  }

  // ================================================================
  // QUICK ACCESS
  // ================================================================
  Widget _buildQuickAccess(
      BuildContext context,
      ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickAction(
                context,
                icon:
                Icons.work_outline_rounded,
                title:
                'Find Jobs',
                subtitle:
                'Explore opportunities',
                color:
                const Color(0xFF2563EB),
                background:
                const Color(0xFFEFF6FF),
                page:
                const JobsScreen(),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildQuickAction(
                context,
                icon:
                Icons.assignment_outlined,
                title:
                'Applications',
                subtitle:
                'Track applications',
                color:
                const Color(0xFF7C3AED),
                background:
                const Color(0xFFF5F3FF),
                page:
                const MyApplicationsScreen(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildQuickAction(
                context,
                icon:
                Icons.history_rounded,
                title:
                'Career History',
                subtitle:
                'View AI recommendations',
                color:
                const Color(0xFF059669),
                background:
                const Color(0xFFECFDF5),
                page:
                const CareerHistoryScreen(),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildQuickAction(
                context,
                icon:
                Icons.person_outline_rounded,
                title:
                'Profile',
                subtitle:
                'Manage your account',
                color:
                const Color(0xFFEA580C),
                background:
                const Color(0xFFFFF7ED),
                page:
                const ProfileScreen(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================================================================
  // QUICK ACTION CARD
  // ================================================================
  Widget _buildQuickAction(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required Color background,
        required Widget page,
      }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => page,
          ),
        );
      },
      child: Container(
        padding:
        const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(18),
          border: Border.all(
            color:
            const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration:
              BoxDecoration(
                color: background,
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 21,
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 10,
                      color:
                      Color(0xFF6B7280),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // FOOTER
  // ================================================================
  Widget _buildFooter() {
    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
        const Color(0xFF111827),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
            BoxDecoration(
              color:
              Colors.white.withOpacity(0.1),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Build your future with CareerWise',
                  style:
                  TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Your career. Your skills. Your future.',
                  style:
                  TextStyle(
                    color:
                    Color(0xFF9CA3AF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SHORT TEXT
  // ================================================================
  String _shortText(
      String text,
      int maxLength,
      ) {
    if (text.length <= maxLength) {
      return text;
    }

    return '${text.substring(0, maxLength)}...';
  }
}