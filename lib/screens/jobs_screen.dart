import 'package:flutter/material.dart';

import 'package:careerwise_sample/model/job.dart';
import 'package:careerwise_sample/services/job_service.dart';
import 'package:careerwise_sample/widgets/job_card.dart';

import 'job_details_screen.dart';

class JobsScreen extends StatelessWidget {
  final String? career;

  const JobsScreen({
    super.key,
    this.career,
  });

  @override
  Widget build(BuildContext context) {
    final JobService jobService = JobService();

    final bool isFiltered =
        career != null &&
            career!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isFiltered
              ? 'Jobs for ${career!}'
              : 'Available Jobs',
        ),
      ),

      body: StreamBuilder<List<Job>>(
        stream: isFiltered
            ? jobService.getRelatedJobs(
          career!,
        )
            : jobService.getJobs(),

        builder: (context, snapshot) {

          // ==================================================
          // Loading
          // ==================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ==================================================
          // Error
          // ==================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading jobs:\n\n'
                      '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // ==================================================
          // Jobs
          // ==================================================

          final jobs =
              snapshot.data ?? [];

          // ==================================================
          // No Jobs
          // ==================================================

          if (jobs.isEmpty) {
            return _buildNoJobs(context);
          }

          // ==================================================
          // Job List
          // ==================================================

          return ListView.builder(
            padding:
            const EdgeInsets.all(16),

            itemCount: jobs.length,

            itemBuilder: (
                context,
                index,
                ) {
              final job =
              jobs[index];

              return JobCard(
                job: job,

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          JobDetailsScreen(
                            job: job,
                          ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ==========================================================
  // No Jobs
  // ==========================================================

  Widget _buildNoJobs(
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
              Icons.work_off_outlined,
              size: 70,
              color: Colors.grey,
            ),

            const SizedBox(height: 20),

            Text(
              career != null
                  ? 'No related jobs found'
                  : 'No jobs available',

              style: const TextStyle(
                fontSize: 21,
                fontWeight:
                FontWeight.bold,
              ),

              textAlign:
              TextAlign.center,
            ),

            const SizedBox(height: 10),

            Text(
              career != null
                  ? 'We could not find jobs related to '
                  '"$career" right now.'
                  : 'There are currently no jobs available.',
              textAlign:
              TextAlign.center,

              style: const TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),

            if (career != null) ...[
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const JobsScreen(),
                    ),
                  );
                },

                icon: const Icon(
                  Icons.work_outline,
                ),

                label: const Text(
                  'View All Jobs',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}