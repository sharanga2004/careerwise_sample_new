class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final String description;
  final String salary;
  final String jobType;

  /// Job category used for category job-alert topics (e.g. "Data & AI").
  final String category;

  /// UID of the user who published the job.
  /// Used for sending "new application" notifications.
  final String publisherId;

  Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.salary,
    required this.jobType,
    this.category = '',
    this.publisherId = '',
  });

  factory Job.fromFirestore(
      String id,
      Map<String, dynamic> data,
      ) {
    return Job(
      id: id,
      title: data['title'] ?? '',
      company: data['company'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      salary: data['salary'] ?? '',
      jobType: data['jobType'] ?? '',
      category: data['category'] ?? '',
      publisherId: data['publisherId'] ?? '',
    );
  }
}