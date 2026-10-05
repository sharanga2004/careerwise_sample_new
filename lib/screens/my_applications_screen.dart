import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Applications'),
        ),
        body: const Center(
          child: Text(
            'Please login to view your applications.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where(
          'userId',
          isEqualTo: user.uid,
        )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
              ),
            );
          }

          final applications =
              snapshot.data?.docs ?? [];

          if (applications.isEmpty) {
            return _emptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final document =
              applications[index];

              final data =
              document.data()
              as Map<String, dynamic>;

              return _applicationCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _applicationCard(
      Map<String, dynamic> data) {
    final jobTitle =
        data['jobTitle']?.toString() ??
            'Unknown Job';

    final company =
        data['company']?.toString() ??
            'Unknown Company';

    final status =
        data['status']?.toString() ??
            'Applied';

    final appliedAt =
    data['appliedAt'] as Timestamp?;

    return Card(
      margin:
      const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.work_outline,
                  size: 35,
                  color: Colors.blue,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        jobTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        company,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            const Divider(),

            const SizedBox(height: 10),

            Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                _statusChip(status),
              ],
            ),

            const SizedBox(height: 15),

            _timeline(status),

            const SizedBox(height: 15),

            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Applied on ${_formatDate(appliedAt)}',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color = Colors.blue;
    IconData icon = Icons.schedule;

    if (status.toLowerCase() ==
        'under review') {
      color = Colors.orange;
      icon = Icons.visibility;
    } else if (status.toLowerCase() ==
        'shortlisted') {
      color = Colors.purple;
      icon = Icons.star;
    } else if (status.toLowerCase() ==
        'interview') {
      color = Colors.indigo;
      icon = Icons.groups;
    } else if (status.toLowerCase() ==
        'accepted') {
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (status.toLowerCase() ==
        'rejected') {
      color = Colors.red;
      icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
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
            size: 16,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeline(String status) {
    if (status.toLowerCase() ==
        'rejected') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius:
          BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.cancel,
              color: Colors.red,
            ),
            SizedBox(width: 10),
            Text(
              'Application Rejected',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final statuses = [
      'Applied',
      'Under Review',
      'Shortlisted',
      'Interview',
      'Accepted',
    ];

    int currentIndex = 0;

    // Map the statuses an employer can set onto this progress list.
    final progressStatus =
    (status == 'Interview Scheduled' || status == 'Interviewed')
        ? 'Interview'
        : status == 'Hired'
        ? 'Accepted'
        : status;

    for (int i = 0;
    i < statuses.length;
    i++) {
      if (statuses[i].toLowerCase() ==
          progressStatus.toLowerCase()) {
        currentIndex = i;
      }
    }

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const Text(
          'Application Progress',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 12),

        for (int i = 0;
        i < statuses.length;
        i++)
          Row(
            children: [
              Icon(
                i <= currentIndex
                    ? Icons.check_circle
                    : Icons
                    .radio_button_unchecked,
                color: i <= currentIndex
                    ? Colors.blue
                    : Colors.grey,
                size: 20,
              ),

              const SizedBox(width: 10),

              Text(
                statuses[i],
                style: TextStyle(
                  fontWeight:
                  i <= currentIndex
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: i <= currentIndex
                      ? Colors.blue
                      : Colors.grey,
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _formatDate(
      Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Date unavailable';
    }

    final date =
    timestamp.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget _emptyState(
      BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 70,
              color: Colors.grey,
            ),

            const SizedBox(height: 20),

            const Text(
              'No Applications Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'When you apply for a job, '
                  'your application will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Browse Jobs',
              ),
            ),
          ],
        ),
      ),
    );
  }
}