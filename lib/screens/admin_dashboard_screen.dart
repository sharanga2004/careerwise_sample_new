import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:careerwise_sample/services/notification_service.dart';

import 'add_job_screen.dart';
import 'admin_broadcast_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // =====================================================
  // COLORS
  // =====================================================

  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color darkColor = Color(0xFF111827);
  static const Color lightBackground = Color(0xFFF5F7FB);

  // =====================================================
  // CHECK ADMIN
  // =====================================================

  Future<DocumentSnapshot?> _getAdminDocument() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please login first.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot?>(
      future: _getAdminDocument(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error checking admin access:\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _accessDeniedScreen(
            'You are not an administrator.',
          );
        }

        final data =
        snapshot.data!.data() as Map<String, dynamic>?;

        if (data?['role'] != 'admin') {
          return _accessDeniedScreen(
            'You are not an administrator.',
          );
        }

        final adminName =
        data?['name']?.toString().trim().isNotEmpty == true
            ? data!['name'].toString()
            : 'Admin';

        return _buildDashboard(context, adminName);
      },
    );
  }

  // =====================================================
  // ACCESS DENIED
  // =====================================================

  Widget _accessDeniedScreen(String message) {
    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 50,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Access Denied',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // ADMIN PROFILE
  // =====================================================

  void _showAdminProfile(
      BuildContext context,
      String adminName,
      ) {
    final user = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF4F46E5),
                        Color(0xFF7C3AED),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 42,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  adminName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: darkColor,
                  ),
                ),

                const SizedBox(height: 6),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          user?.email ?? 'No email',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Admin ID',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.uid ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // MAIN DASHBOARD
  // =====================================================

  Widget _buildDashboard(
      BuildContext context,
      String adminName,
      ) {
    return Scaffold(
      backgroundColor: lightBackground,

      // =================================================
      // APP BAR
      // =================================================

      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 12,

        // Responsive AppBar title.
        // The ADMIN badge is hidden on narrow phones so the
        // title cannot collide with the profile/logout icons.
        title: LayoutBuilder(
          builder: (context, constraints) {
            final showAdminBadge = constraints.maxWidth >= 215;

            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4F46E5),
                        Color(0xFF7C3AED),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 21,
                  ),
                ),

                const SizedBox(width: 9),

                const Flexible(
                  child: Text(
                    'CareerWise',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: darkColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                ),

                if (showAdminBadge) ...[
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),

        actions: [
          IconButton(
            tooltip: 'Send announcement',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.campaign_outlined,
              color: primaryColor,
              size: 25,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminBroadcastScreen(),
                ),
              );
            },
          ),

          IconButton(
            tooltip: 'Admin Profile',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: () {
              _showAdminProfile(
                context,
                adminName,
              );
            },
            icon: CircleAvatar(
              radius: 17,
              backgroundColor:
              primaryColor.withOpacity(0.1),
              child: const Icon(
                Icons.person,
                color: primaryColor,
                size: 19,
              ),
            ),
          ),

          IconButton(
            tooltip: 'Logout',
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.redAccent,
              size: 24,
            ),
            onPressed: () async {
              // Stop push notifications for this admin on this device.
              await NotificationService.instance.onBeforeLogout();
              await FirebaseAuth.instance.signOut();
            },
          ),

          const SizedBox(width: 6),
        ],
      ),

      // =================================================
      // BODY
      // =================================================

      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // WELCOME BANNER
              // =================================================

              _welcomeBanner(
                context,
                adminName,
              ),

              const SizedBox(height: 25),

              // =================================================
              // OVERVIEW TITLE
              // =================================================

              _sectionHeader(
                title: 'Dashboard Overview',
                subtitle:
                'Monitor your CareerWise platform.',
                icon: Icons.dashboard_outlined,
              ),

              const SizedBox(height: 15),

              // =================================================
              // STATISTICS
              // =================================================

              _statisticsGrid(),

              const SizedBox(height: 32),

              // =================================================
              // JOB MANAGEMENT
              // =================================================

              _sectionHeader(
                title: 'Job Management',
                subtitle:
                'Manage available career opportunities.',
                icon: Icons.work_outline,
              ),

              const SizedBox(height: 15),

              _addJobButton(context),

              const SizedBox(height: 15),

              _jobsList(context),

              const SizedBox(height: 35),

              // =================================================
              // APPLICATIONS
              // =================================================

              _sectionHeader(
                title: 'Job Applications',
                subtitle:
                'Review applicants and manage application status.',
                icon: Icons.description_outlined,
              ),

              const SizedBox(height: 15),

              _applicationsList(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // WELCOME BANNER
  // =====================================================

  Widget _welcomeBanner(
      BuildContext context,
      String adminName,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isNarrow ? 20 : 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4F46E5),
                Color(0xFF7C3AED),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Good to see you 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      adminName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isNarrow ? 26 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      isNarrow
                          ? 'Manage jobs, applications and career recommendations.'
                          : 'Manage jobs, applications and\ncareer recommendations from here.',
                      maxLines: isNarrow ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Container(
                padding: EdgeInsets.all(
                  isNarrow ? 14 : 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Colors.white,
                  size: isNarrow ? 38 : 45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // SECTION HEADER
  // =====================================================

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 22,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  // STATISTICS GRID
  // =====================================================

  Widget _statisticsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
        constraints.maxWidth >= 750 ? 4 : 2;

        return GridView(
          shrinkWrap: true,
          physics:
          const NeverScrollableScrollPhysics(),
          gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,

            // FIX FOR:
            // "BOTTOM OVERFLOWED BY 35 PIXELS"
            //
            // The old childAspectRatio made phone cards too short.
            // A fixed vertical extent gives the card enough room
            // for the icon row, count, and title.
            mainAxisExtent:
            constraints.maxWidth >= 750
                ? 150
                : 154,
          ),
          children: [
            _statCard(
              collection: 'users',
              title: 'Total Users',
              icon: Icons.people_alt_outlined,
              color: const Color(0xFF4F46E5),
            ),

            _statCard(
              collection: 'jobs',
              title: 'Total Jobs',
              icon: Icons.work_outline,
              color: const Color(0xFF0891B2),
            ),

            _statCard(
              collection: 'applications',
              title: 'Applications',
              icon: Icons.description_outlined,
              color: const Color(0xFFEA580C),
            ),

            _statCard(
              collection: 'career_recommendations',
              title: 'AI Recommendations',
              icon: Icons.psychology_outlined,
              color: const Color(0xFF9333EA),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // STAT CARD
  // =====================================================

  Widget _statCard({
    required String collection,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .snapshots(),
      builder: (context, snapshot) {
        int count = 0;

        if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
        }

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 23,
                    ),
                  ),

                  Icon(
                    Icons.arrow_outward,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),

              const Spacer(),

              Text(
                '$count',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 26,
                  height: 1.0,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.0,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // ADD JOB BUTTON
  // =====================================================

  Widget _addJobButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddJobScreen(),
            ),
          );
        },
        icon: const Icon(
          Icons.add_rounded,
          size: 25,
        ),
        label: const Text(
          'Add New Job',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // =====================================================
  // JOB LIST
  // =====================================================

  Widget _jobsList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .orderBy(
        'createdAt',
        descending: true,
      )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return _loadingCard();
        }

        if (snapshot.hasError) {
          return _errorCard(
            'Error loading jobs:\n\n${snapshot.error}',
          );
        }

        final jobs =
            snapshot.data?.docs ?? [];

        if (jobs.isEmpty) {
          return _emptyCard(
            icon: Icons.work_off_outlined,
            title: 'No jobs found',
            subtitle:
            'Add your first job using the button above.',
          );
        }

        return Column(
          children: jobs.map((document) {
            final data =
            document.data()
            as Map<String, dynamic>;

            return _jobCard(
              context,
              document.id,
              data,
            );
          }).toList(),
        );
      },
    );
  }

  // =====================================================
  // JOB CARD
  // =====================================================

  Widget _jobCard(
      BuildContext context,
      String jobId,
      Map<String, dynamic> data,
      ) {
    final title =
        data['title']?.toString() ??
            'Unknown Job';

    final company =
        data['company']?.toString() ??
            'Unknown Company';

    final location =
        data['location']?.toString() ??
            'Unknown Location';

    final salary =
        data['salary']?.toString() ??
            'Salary not specified';

    final jobType =
        data['jobType']?.toString() ??
            'Full Time';

    final description =
        data['description']?.toString() ??
            '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // =================================================
          // HEADER
          // =================================================

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4F46E5),
                      Color(0xFF7C3AED),
                    ],
                  ),
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.work_outline,
                  color: Colors.white,
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
                      title,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                        color: darkColor,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      company,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Flexible(
                child: Align(
                  alignment:
                  Alignment.topRight,
                  child: Container(
                    constraints:
                    const BoxConstraints(
                      maxWidth: 105,
                    ),
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                      primaryColor.withOpacity(0.1),
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: Text(
                      jobType,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight:
                        FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Divider(),

          const SizedBox(height: 12),

          // =================================================
          // DETAILS
          // =================================================

          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _jobInfo(
                Icons.location_on_outlined,
                location,
              ),
              _jobInfo(
                Icons.payments_outlined,
                salary,
              ),
            ],
          ),

          if (description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                height: 1.45,
                fontSize: 13,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // =================================================
          // BUTTONS
          // =================================================

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                    primaryColor,
                    side: BorderSide(
                      color: primaryColor
                          .withOpacity(0.3),
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    _editJob(
                      context,
                      jobId,
                      data,
                    );
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                  ),
                  label: const Text('Edit'),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                    Colors.redAccent,
                    side: BorderSide(
                      color: Colors.redAccent
                          .withOpacity(0.3),
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    _confirmDeleteJob(
                      context,
                      jobId,
                      title,
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                  ),
                  label:
                  const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // JOB INFO
  // =====================================================

  Widget _jobInfo(
      IconData icon,
      String text,
      ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 260,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: Colors.grey,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // EDIT JOB
  // =====================================================

  Future<void> _editJob(
      BuildContext context,
      String jobId,
      Map<String, dynamic> data,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddJobScreen(
          jobId: jobId,
          existingJob: data,
        ),
      ),
    );
  }

  // =====================================================
  // DELETE CONFIRMATION
  // =====================================================

  void _confirmDeleteJob(
      BuildContext context,
      String jobId,
      String jobTitle,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Job?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete '
                '"$jobTitle"?\n\n'
                'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                Colors.redAccent,
                foregroundColor:
                Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);

                await _deleteJob(
                  context,
                  jobId,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // DELETE JOB
  // =====================================================

  Future<void> _deleteJob(
      BuildContext context,
      String jobId,
      ) async {
    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Job deleted successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete job:\n$e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // APPLICATION LIST
  // =====================================================

  Widget _applicationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return _loadingCard();
        }

        if (snapshot.hasError) {
          return _errorCard(
            'Error loading applications:\n\n${snapshot.error}',
          );
        }

        final applications =
            snapshot.data?.docs ?? [];

        if (applications.isEmpty) {
          return _emptyCard(
            icon: Icons.description_outlined,
            title: 'No applications yet',
            subtitle:
            'Applications will appear here when users apply for jobs.',
          );
        }

        return Column(
          children:
          applications.map((document) {
            final data =
            document.data()
            as Map<String, dynamic>;

            return _applicationCard(
              context,
              document.id,
              data,
            );
          }).toList(),
        );
      },
    );
  }

  // =====================================================
  // APPLICATION CARD
  // =====================================================

  Widget _applicationCard(
      BuildContext context,
      String applicationId,
      Map<String, dynamic> data,
      ) {
    final jobTitle =
        data['jobTitle']?.toString() ??
            'Unknown Job';

    final company =
        data['company']?.toString() ??
            'Unknown Company';

    final userId =
        data['userId']?.toString() ??
            'Unknown User';

    final status =
        data['status']?.toString() ??
            'Applied';

    final appliedAt =
    data['appliedAt'] is Timestamp
        ? data['appliedAt'] as Timestamp
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // =================================================
          // JOB HEADER
          // =================================================

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color:
                  Colors.orange.withOpacity(0.1),
                  borderRadius:
                  BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Colors.orange,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobTitle,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.bold,
                        color: darkColor,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      company,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Flexible(
                child: Align(
                  alignment:
                  Alignment.topRight,
                  child: _statusChip(status),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          const Divider(),

          const SizedBox(height: 12),

          // =================================================
          // APPLICANT
          // =================================================

          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 19,
                color: Colors.grey,
              ),

              const SizedBox(width: 8),

              const Text(
                'Applicant',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  userId,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          if (appliedAt != null) ...[
            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 17,
                  color: Colors.grey,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Applied on ${_formatDate(appliedAt)}',
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 15),

          // =================================================
          // STATUS BUTTON
          // =================================================

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                primaryColor.withOpacity(0.08),
                foregroundColor:
                primaryColor,
                elevation: 0,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                padding:
                const EdgeInsets.symmetric(
                  vertical: 13,
                ),
              ),
              onPressed: () {
                _showStatusDialog(
                  context,
                  applicationId,
                  status,
                );
              },
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
              ),
              label: const Text(
                'Update Application Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // STATUS CHIP
  // =====================================================

  Widget _statusChip(String status) {
    Color color = Colors.blue;
    IconData icon = Icons.schedule;

    switch (status.toLowerCase()) {
      case 'under review':
        color = Colors.orange;
        icon = Icons.visibility_outlined;
        break;

      case 'shortlisted':
        color = Colors.purple;
        icon = Icons.star_outline;
        break;

      case 'interview':
      case 'interviewed':
        color = Colors.indigo;
        icon = Icons.groups_outlined;
        break;

      case 'accepted':
      case 'hired':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;

      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel_outlined;
        break;

      case 'applied':
      default:
        color = Colors.blue;
        icon = Icons.schedule;
    }

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 112,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),

          const SizedBox(width: 4),

          Flexible(
            child: Text(
              status,
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight:
                FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // STATUS DIALOG
  // =====================================================

  String _formatInterviewTime(
      BuildContext context,
      DateTime value,
      ) {
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(value));

    return '${value.day}/${value.month}/${value.year}  $time';
  }

  void _showStatusDialog(
      BuildContext context,
      String applicationId,
      String currentStatus,
      ) {
    final statuses = [
      'Applied',
      'Under Review',
      'Shortlisted',
      'Interview Scheduled',
      'Interviewed',
      'Hired',
      'Rejected',
    ];

    String initialStatus = currentStatus;

    if (currentStatus == 'Interview') {
      initialStatus = 'Interviewed';
    }

    if (currentStatus == 'Accepted') {
      initialStatus = 'Hired';
    }

    if (!statuses.contains(initialStatus)) {
      initialStatus = 'Applied';
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        String selectedStatus = initialStatus;
        DateTime? interviewAt;

        return StatefulBuilder(
          builder: (
              context,
              setState,
              ) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(20),
              ),
              title: const Text(
                'Update Application Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Application Status',
                      border:
                      OutlineInputBorder(),
                    ),
                    items: statuses.map(
                          (status) {
                        return DropdownMenuItem<
                            String>(
                          value: status,
                          child: Text(status),
                        );
                      },
                    ).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedStatus =
                              value;
                        });
                      }
                    },
                  ),

                  // Interview date & time (used for the reminders).
                  if (selectedStatus ==
                      'Interview Scheduled') ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.event),
                      label: Text(
                        interviewAt == null
                            ? 'Pick interview date & time'
                            : _formatInterviewTime(
                          dialogContext,
                          interviewAt!,
                        ),
                      ),
                      onPressed: () async {
                        final now = DateTime.now();

                        final date = await showDatePicker(
                          context: dialogContext,
                          initialDate: interviewAt ??
                              now.add(const Duration(days: 1)),
                          firstDate: now,
                          lastDate: now.add(
                            const Duration(days: 365),
                          ),
                        );

                        if (date == null ||
                            !dialogContext.mounted) {
                          return;
                        }

                        final time = await showTimePicker(
                          context: dialogContext,
                          initialTime: const TimeOfDay(
                            hour: 10,
                            minute: 0,
                          ),
                        );

                        if (time == null) return;

                        setState(() {
                          interviewAt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                  const Text('Cancel'),
                ),
                ElevatedButton(
                  // An interview needs a date & time first.
                  onPressed: (selectedStatus ==
                      'Interview Scheduled' &&
                      interviewAt == null)
                      ? null
                      : () async {
                    try {
                      final applicationRef =
                      FirebaseFirestore
                          .instance
                          .collection(
                          'applications')
                          .doc(applicationId);

                      await applicationRef.update({
                        'status':
                        selectedStatus,
                        if (selectedStatus ==
                            'Interview Scheduled')
                          'interviewAt':
                          Timestamp.fromDate(
                            interviewAt!,
                          )
                        else
                          'interviewAt':
                          FieldValue.delete(),
                        'updatedAt':
                        FieldValue
                            .serverTimestamp(),
                      });

                      // NOTIFICATIONS: push the new status to the
                      // applicant (not awaited, never blocks the UI).
                      final applicationData =
                      (await applicationRef.get())
                          .data();

                      if (applicationData != null) {
                        unawaited(
                          NotificationService.instance
                              .notifyApplicationStatusChanged(
                            applicationId: applicationId,
                            applicantUid:
                            applicationData['userId']
                                ?.toString() ??
                                '',
                            jobTitle:
                            applicationData['jobTitle']
                                ?.toString() ??
                                'your application',
                            company:
                            applicationData['company']
                                ?.toString() ??
                                '',
                            status: selectedStatus,
                            interviewAt: selectedStatus ==
                                'Interview Scheduled'
                                ? interviewAt
                                : null,
                          ),
                        );
                      }

                      if (!dialogContext
                          .mounted) {
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger
                          .of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Application status updated successfully.',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!dialogContext
                          .mounted) {
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger
                          .of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to update status:\n$e',
                          ),
                        ),
                      );
                    }
                  },
                  child:
                  const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =====================================================
  // LOADING CARD
  // =====================================================

  Widget _loadingCard() {
    return Container(
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      ),
    );
  }

  // =====================================================
  // ERROR CARD
  // =====================================================

  Widget _errorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: Colors.red.withOpacity(0.15),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.red,
        ),
      ),
    );
  }

  // =====================================================
  // EMPTY CARD
  // =====================================================

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 12),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: darkColor,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // DATE FORMAT
  // =====================================================

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}