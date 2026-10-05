import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:careerwise_sample/model/job.dart';
import 'package:careerwise_sample/services/notification_service.dart';
import 'package:careerwise_sample/services/report_service.dart';

class JobDetailsScreen extends StatefulWidget {
  final Job job;

  const JobDetailsScreen({
    super.key,
    required this.job,
  });

  @override
  State<JobDetailsScreen> createState() =>
      _JobDetailsScreenState();
}

class _JobDetailsScreenState
    extends State<JobDetailsScreen> {
  bool isApplying = false;
  bool hasApplied = false;

  @override
  void initState() {
    super.initState();
    checkApplicationStatus();
  }

  // ==========================================================
  // Check whether user already applied
  // ==========================================================

  Future<void> checkApplicationStatus() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final result = await FirebaseFirestore
          .instance
          .collection('applications')
          .where(
        'userId',
        isEqualTo: user.uid,
      )
          .where(
        'jobId',
        isEqualTo: widget.job.id,
      )
          .limit(1)
          .get();

      if (!mounted) return;

      setState(() {
        hasApplied = result.docs.isNotEmpty;
      });
    } catch (e) {
      debugPrint(
        'Application status error: $e',
      );
    }
  }

  // ==========================================================
  // Apply for Job
  // ==========================================================

  Future<void> applyForJob() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please login before applying.',
          ),
        ),
      );
      return;
    }

    if (hasApplied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You have already applied for this job.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isApplying = true;
    });

    try {
      // Find out who published this job so they can be notified.
      String publisherId = widget.job.publisherId;

      if (publisherId.isEmpty) {
        final jobDoc = await FirebaseFirestore.instance
            .collection('jobs')
            .doc(widget.job.id)
            .get();

        publisherId =
            jobDoc.data()?['publisherId']?.toString() ?? '';
      }

      final applicationRef = await FirebaseFirestore.instance
          .collection('applications')
          .add({
        'userId': user.uid,
        'jobId': widget.job.id,
        'jobTitle': widget.job.title,
        'company': widget.job.company,
        'publisherId': publisherId,
        'status': 'Applied',
        'appliedAt':
        FieldValue.serverTimestamp(),
      });

      // NOTIFICATIONS: local "Application received" for the applicant +
      // push "New application" for the publisher. Not awaited so the UI
      // never waits for the network.
      unawaited(
        NotificationService.instance.notifyApplicationSubmitted(
          applicationId: applicationRef.id,
          jobId: widget.job.id,
          jobTitle: widget.job.title,
          company: widget.job.company,
          publisherId: publisherId,
        ),
      );

      if (!mounted) return;

      setState(() {
        hasApplied = true;
        isApplying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Application submitted successfully!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isApplying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit application: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // Report this post  (notifies every admin)
  // ==========================================================

  Future<void> _showReportDialog() async {
    String selectedReason = ReportService.reasons.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Report this post'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ReportService.reasons.map((reason) {
                    final selected = reason == selectedReason;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selected ? Colors.blue : Colors.grey,
                      ),
                      title: Text(reason),
                      onTap: () {
                        setDialogState(() {
                          selectedReason = reason;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Report'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await ReportService.reportJob(
        jobId: widget.job.id,
        jobTitle: widget.job.title,
        reason: selectedReason,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks. The post was reported to our admins.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to report post: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Report this post',
            icon: const Icon(Icons.flag_outlined),
            onPressed: _showReportDialog,
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            // ==================================================
            // Job Header
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius:
                BorderRadius.circular(16),
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  const Icon(
                    Icons.business_center,
                    size: 50,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 15),

                  Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    job.company,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight:
                      FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // Job Information
            // ==================================================

            const Text(
              'Job Information',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _buildInfoCard(
              Icons.location_on_outlined,
              'Location',
              job.location,
            ),

            _buildInfoCard(
              Icons.payments_outlined,
              'Salary',
              job.salary,
            ),

            _buildInfoCard(
              Icons.access_time,
              'Job Type',
              job.jobType,
            ),

            const SizedBox(height: 20),

            // ==================================================
            // Description
            // ==================================================

            const Text(
              'Job Description',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              elevation: 2,
              child: Padding(
                padding:
                const EdgeInsets.all(18),

                child: Text(
                  job.description,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // Apply Button
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed:
                isApplying || hasApplied
                    ? null
                    : applyForJob,

                icon: isApplying
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : Icon(
                  hasApplied
                      ? Icons.check_circle
                      : Icons.send,
                ),

                label: Text(
                  isApplying
                      ? 'Applying...'
                      : hasApplied
                      ? 'Applied'
                      : 'Apply Now',

                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
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
  // Information Card
  // ==========================================================

  Widget _buildInfoCard(
      IconData icon,
      String title,
      String value,
      ) {
    return Card(
      elevation: 1,
      margin:
      const EdgeInsets.only(bottom: 10),

      child: Padding(
        padding:
        const EdgeInsets.all(15),

        child: Row(
          children: [

            Container(
              padding:
              const EdgeInsets.all(10),

              decoration: BoxDecoration(
                color:
                Colors.blue.withOpacity(0.1),

                borderRadius:
                BorderRadius.circular(10),
              ),

              child: Icon(
                icon,
                color: Colors.blue,
              ),
            ),

            const SizedBox(width: 15),

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

                  const SizedBox(height: 4),

                  Text(
                    value.isEmpty
                        ? 'Not specified'
                        : value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.w500,
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
}