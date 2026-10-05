import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

/// "Report post" feature. Saves the report and alerts every admin.
class ReportService {
  ReportService._();

  static const List<String> reasons = [
    'Fake or scam job',
    'Misleading information',
    'Inappropriate content',
    'Duplicate post',
    'Other',
  ];

  /// One report per user per job (re-reporting just updates it), which also
  /// keeps Firestore writes low.
  static Future<void> reportJob({
    required String jobId,
    required String jobTitle,
    required String reason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Please login to report a post.');
    }

    await FirebaseFirestore.instance
        .collection('reports')
        .doc('${jobId}_${user.uid}')
        .set({
      'jobId': jobId,
      'jobTitle': jobTitle,
      'reason': reason,
      'reporterId': user.uid,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Fire and forget: the report is already saved.
    NotificationService.instance.notifyJobReported(
      jobId: jobId,
      jobTitle: jobTitle,
      reason: reason,
    );
  }
}
