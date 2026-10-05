/// Central place for every constant used by the notification system.
///
/// Keep these strings in sync with whatever you send in the FCM `data`
/// payload (key: `type`) so the app knows where to navigate on tap.

class NotificationChannels {
  NotificationChannels._();

  /// Must match the `default_notification_channel_id` value in
  /// android/app/src/main/AndroidManifest.xml
  static const String highImportance = 'careerwise_high_importance';
  static const String highImportanceName = 'CareerWise Notifications';
  static const String highImportanceDescription =
      'Application updates, job alerts, messages and announcements.';
}

class NotificationTypes {
  NotificationTypes._();

  // ---- Job seeker ---------------------------------------------------
  static const String applicationSubmitted = 'application_submitted';
  static const String applicationStatus = 'application_status';
  static const String interviewReminder = 'interview_reminder';
  static const String profileIncomplete = 'profile_incomplete';
  static const String newJob = 'new_job';

  // ---- Employer / publisher -----------------------------------------
  static const String newApplication = 'new_application';
  static const String jobApproved = 'job_approved';
  static const String jobRejected = 'job_rejected';

  // ---- Chat (both directions) ---------------------------------------
  static const String chatMessage = 'chat_message';

  // ---- Admin --------------------------------------------------------
  static const String flaggedPost = 'flagged_post';

  // ---- Everyone -----------------------------------------------------
  static const String announcement = 'announcement';
}

class NotificationTopics {
  NotificationTopics._();

  /// Every logged-in user (announcements).
  static const String allUsers = 'all_users';

  /// Admin accounts only (flagged posts, fallback for new applications).
  static const String admins = 'admins';

  /// FCM topic for a job category, e.g. "Data & AI" -> "jobs_data_ai".
  /// Topic names may only contain [a-zA-Z0-9-_.~%].
  static String forCategory(String category) {
    final slug = category
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return 'jobs_$slug';
  }
}

class JobCategories {
  JobCategories._();

  static const String fallback = 'Other';

  /// Used by the "Add Job" dropdown and by the job-alert chips.
  static const List<String> all = [
    'Software Development',
    'Mobile Development',
    'Web Development',
    'Data & AI',
    'Cybersecurity',
    'UI/UX Design',
    'Networking & IT Support',
    'Business & Management',
    'Marketing & Sales',
    'Finance & Accounting',
    'Engineering',
    'Healthcare',
    'Education',
    fallback,
  ];
}
