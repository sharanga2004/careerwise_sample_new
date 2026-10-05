import 'package:flutter/material.dart';
import 'package:careerwise_sample/model/job.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.work),
        ),
        title: Text(
          job.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${job.company}\n${job.location}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}