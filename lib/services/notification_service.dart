import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:careerwise_sample/firebase_options.dart';
import 'package:careerwise_sample/model/job.dart';
import 'package:careerwise_sample/screens/job_details_screen.dart';
import 'package:careerwise_sample/screens/my_applications_screen.dart';
import 'package:careerwise_sample/screens/profile_screen.dart';

import 'notification_types.dart';
import 'push_sender.dart';

// =======================================================================
// GLOBALS
// =======================================================================

/// Used by MaterialApp so notifications can open screens without a
/// BuildContext (needed for the "terminated" and "background" states).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// FCM background / terminated handler. MUST be a top-level function.
///
/// Normal "notification" messages are displayed by Android itself, so this
/// only has to do real work for DATA-ONLY messages (no notification block),
/// which we render ourselves with flutter_local_notifications.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (message.notification == null && message.data['title'] != null) {
    await NotificationService.showDataOnlyMessageInBackground(message);
  }
}

/// What the user chose in the Notification Settings screen.
class NotificationPrefs {
  const NotificationPrefs({
    required this.announcements,
    required this.categories,
    required this.isAdmin,
  });

  final bool announcements;
  final Set<String> categories;
  final bool isAdmin;
}

// =======================================================================
// SERVICE
// =======================================================================

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  // ---------------------------------------------------------------------
  // Config
  // ---------------------------------------------------------------------

  /// Profile fields that must be filled for the profile to count as complete.
  /// ADD 'resumeUrl', 'skills', ... here once the profile screen collects
  /// them and the reminder will start using them automatically.
  static const List<String> _requiredProfileFields = [
    'firstName',
    'lastName',
    'phone',
  ];

  static const Duration _profileReminderDelay = Duration(hours: 24);
  static const int _profileReminderId = 4101;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    NotificationChannels.highImportance,
    NotificationChannels.highImportanceName,
    description: NotificationChannels.highImportanceDescription,
    importance: Importance.high,
  );

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      NotificationChannels.highImportance,
      NotificationChannels.highImportanceName,
      channelDescription: NotificationChannels.highImportanceDescription,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static const InitializationSettings _initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    // Permissions are requested through FirebaseMessaging instead.
    iOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
  );

  // ---------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------

  final FlutterLocalNotificationsPlugin _local =
  FlutterLocalNotificationsPlugin();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  bool _initialized = false;
  String? _currentUid;
  bool _isAdmin = false;
  DateTime? _lastInterviewSync;

  /// Notifications only run on Android / iOS builds (not web or desktop).
  static bool get isSupported =>
      !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS);

  bool get isAdmin => _isAdmin;

  // =====================================================================
  // INIT  (call once from main(), after Firebase.initializeApp)
  // =====================================================================

  Future<void> init() async {
    if (_initialized || !isSupported) return;
    _initialized = true;

    tzdata.initializeTimeZones();

    // ---- local notifications ------------------------------------------
    await _local.initialize(
      settings: _initSettings,
      // Fires when the user taps a LOCAL notification while the app is
      // running (foreground or background).
      onDidReceiveNotificationResponse: (response) {
        _handlePayloadString(response.payload);
      },
    );

    await _local
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // ---- permission (Android 13+ and iOS) -----------------------------
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // iOS: show FCM banners while the app is open.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // ---- STATE 1: FOREGROUND ------------------------------------------
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // ---- STATE 2: BACKGROUND (user taps the system notification) ------
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigateWhenReady(message.data);
      unawaited(syncInterviewReminders());
    });

    // ---- STATE 3: TERMINATED (app launched by tapping a notification) -
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      unawaited(_navigateWhenReady(initialMessage.data));
    }

    final launchDetails = await _local.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _handlePayloadString(launchDetails!.notificationResponse?.payload);
    }

    // ---- token + topics follow the logged-in user ---------------------
    messaging.onTokenRefresh.listen(_onTokenRefresh);
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);

    // Re-check interview reminders whenever the app comes back to the front.
    WidgetsBinding.instance.addObserver(_ResumeObserver(_onAppResumed));
  }

  // =====================================================================
  // AUTH / TOKEN / TOPICS
  // =====================================================================

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      _currentUid = null;
      _isAdmin = false;
      return;
    }

    if (_currentUid == user.uid) return;
    _currentUid = user.uid;

    try {
      await _onLogin(user);
    } catch (e) {
      debugPrint('Notification login setup error: $e');
    }
  }

  Future<void> _onLogin(User user) async {
    final uid = user.uid;
    final messaging = FirebaseMessaging.instance;

    _isAdmin = await _checkIsAdmin(uid);

    final settingsRef = _db.collection('notification_settings').doc(uid);
    final snapshot = await settingsRef.get();
    final saved = snapshot.data() ?? <String, dynamic>{};

    final bool announcements = saved['announcements'] as bool? ?? true;
    final List<String> categories =
    List<String>.from(saved['jobCategories'] ?? const <String>[]);

    final token = await messaging.getToken();

    await settingsRef.set({
      'role': _isAdmin ? 'admin' : 'candidate',
      'updatedAt': FieldValue.serverTimestamp(),
      if (token != null) 'tokens': FieldValue.arrayUnion([token]),
      if (!snapshot.exists) 'announcements': true,
      if (!snapshot.exists) 'jobCategories': <String>[],
    }, SetOptions(merge: true));

    // ---- topics ---------------------------------------------------------
    if (announcements) {
      await _subscribe(NotificationTopics.allUsers);
    } else {
      await _unsubscribe(NotificationTopics.allUsers);
    }

    if (_isAdmin) {
      await _subscribe(NotificationTopics.admins);
    } else {
      for (final category in categories) {
        await _subscribe(NotificationTopics.forCategory(category));
      }

      // Job-seeker only local features.
      await syncInterviewReminders();
      await checkProfileCompleteness();
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db.collection('notification_settings').doc(uid).set({
        'tokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Token refresh save error: $e');
    }
  }

  Future<bool> _checkIsAdmin(String uid) async {
    try {
      final doc = await _db.collection('admins').doc(uid).get();
      if (!doc.exists) return false;
      return doc.data()?['role'] == 'admin';
    } catch (_) {
      return false;
    }
  }

  /// Call this BEFORE FirebaseAuth.instance.signOut() so the device stops
  /// receiving the previous user's notifications.
  Future<void> onBeforeLogout() async {
    if (!isSupported) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      final messaging = FirebaseMessaging.instance;

      if (uid != null) {
        final ref = _db.collection('notification_settings').doc(uid);
        final snapshot = await ref.get();
        final categories = List<String>.from(
          snapshot.data()?['jobCategories'] ?? const <String>[],
        );

        final token = await messaging.getToken();
        if (token != null) {
          await ref.set({
            'tokens': FieldValue.arrayRemove([token]),
          }, SetOptions(merge: true));
        }

        await _unsubscribe(NotificationTopics.allUsers);
        await _unsubscribe(NotificationTopics.admins);
        for (final category in categories) {
          await _unsubscribe(NotificationTopics.forCategory(category));
        }
      }

      // Scheduled reminders belong to the user who is leaving.
      await _local.cancelAll();
    } catch (e) {
      debugPrint('Notification logout cleanup error: $e');
    }

    _currentUid = null;
    _isAdmin = false;
  }

  Future<void> _subscribe(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (e) {
      debugPrint('Subscribe $topic failed: $e');
    }
  }

  Future<void> _unsubscribe(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('Unsubscribe $topic failed: $e');
    }
  }

  // =====================================================================
  // SETTINGS SCREEN HELPERS
  // =====================================================================

  Future<NotificationPrefs> loadPrefs() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    bool announcements = true;
    var categories = <String>{};

    if (uid != null) {
      final snapshot =
      await _db.collection('notification_settings').doc(uid).get();
      final data = snapshot.data();
      announcements = data?['announcements'] as bool? ?? true;
      categories = Set<String>.from(data?['jobCategories'] ?? const <String>[]);
      if (!_isAdmin) {
        _isAdmin = await _checkIsAdmin(uid);
      }
    }

    return NotificationPrefs(
      announcements: announcements,
      categories: categories,
      isAdmin: _isAdmin,
    );
  }

  Future<void> setAnnouncementsEnabled(bool enabled) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('notification_settings').doc(uid).set({
      'announcements': enabled,
    }, SetOptions(merge: true));

    if (!isSupported) return;
    if (enabled) {
      await _subscribe(NotificationTopics.allUsers);
    } else {
      await _unsubscribe(NotificationTopics.allUsers);
    }
  }

  Future<void> setCategorySubscribed(String category, bool subscribed) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('notification_settings').doc(uid).set({
      'jobCategories': subscribed
          ? FieldValue.arrayUnion([category])
          : FieldValue.arrayRemove([category]),
    }, SetOptions(merge: true));

    if (!isSupported) return;
    final topic = NotificationTopics.forCategory(category);
    if (subscribed) {
      await _subscribe(topic);
    } else {
      await _unsubscribe(topic);
    }
  }

  Future<bool> areNotificationsAllowed() async {
    if (!isSupported) return false;
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> requestPermission() async {
    if (!isSupported) return;
    await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
  }

  Future<String?> getDeviceToken() async {
    if (!isSupported) return null;
    return FirebaseMessaging.instance.getToken();
  }

  /// Sends a real push to THIS device through FCM (full end-to-end test).
  Future<String> sendTestPush({int delaySeconds = 0}) async {
    final token = await getDeviceToken();
    if (token == null) {
      return 'No FCM token yet. Test on a real Android/iOS device.';
    }

    if (delaySeconds > 0) {
      await Future.delayed(Duration(seconds: delaySeconds));
    }

    final result = await PushSender.sendToToken(
      token: token,
      title: 'CareerWise test notification',
      body: 'If you can read this, push notifications are working.',
      data: _data(NotificationTypes.announcement),
    );

    return _describe(result);
  }

  String _describe(PushResult result) {
    switch (result) {
      case PushResult.sent:
        return 'Notification sent.';
      case PushResult.invalidToken:
        return 'This device token is no longer valid.';
      case PushResult.notConfigured:
        return 'Push sending is not configured. Add your service account key '
            'to assets/config/service_account.json.';
      case PushResult.failed:
        return 'Sending failed. Check the debug console for details.';
    }
  }

  // =====================================================================
  // SHOWING LOCAL NOTIFICATIONS
  // =====================================================================

  void _onForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];
    if (title == null && body == null) return;

    // Android never draws FCM notifications while the app is open, so we
    // draw one ourselves. iOS already shows a banner (see init()), except
    // for data-only messages.
    if (defaultTargetPlatform == TargetPlatform.android ||
        message.notification == null) {
      showLocal(
        title: title ?? 'CareerWise',
        body: body ?? '',
        data: message.data,
      );
    }

    if (message.data['type'] == NotificationTypes.applicationStatus) {
      unawaited(syncInterviewReminders());
    }
  }

  Future<void> showLocal({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    int? id,
  }) async {
    if (!isSupported) return;

    try {
      await _local.show(
        id: id ?? DateTime.now().millisecondsSinceEpoch.remainder(0x7fffffff),
        title: title,
        body: body,
        notificationDetails: _details,
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('Local notification error: $e');
    }
  }

  /// Used by [firebaseMessagingBackgroundHandler] (separate isolate, so it
  /// needs its own plugin instance).
  static Future<void> showDataOnlyMessageInBackground(
      RemoteMessage message,
      ) async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(settings: _initSettings);
    await plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(0x7fffffff),
      title: message.data['title'],
      body: message.data['body'],
      notificationDetails: _details,
      payload: jsonEncode(message.data),
    );
  }

  // =====================================================================
  // NAVIGATION  (what happens when the user taps a notification)
  // =====================================================================

  void _handlePayloadString(String? payload) {
    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        unawaited(_navigateWhenReady(decoded));
      }
    } catch (e) {
      debugPrint('Bad notification payload: $e');
    }
  }

  /// Waits for Firebase Auth and the Navigator to be ready (important when
  /// the app was TERMINATED), then opens the right screen.
  Future<void> _navigateWhenReady(Map<String, dynamic> data) async {
    try {
      await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 8));
    } catch (_) {}

    if (FirebaseAuth.instance.currentUser == null) return;

    for (var i = 0; i < 60 && appNavigatorKey.currentState == null; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    // Give AuthGate a moment to build the home / dashboard screen first.
    await Future.delayed(const Duration(milliseconds: 500));

    await _route(navigator, data);
  }

  Future<void> _route(
      NavigatorState navigator,
      Map<String, dynamic> data,
      ) async {
    final type = data['type']?.toString();

    switch (type) {
    // ---- Job seeker -----------------------------------------------------
      case NotificationTypes.applicationSubmitted:
      case NotificationTypes.applicationStatus:
      case NotificationTypes.interviewReminder:
        navigator.push(
          MaterialPageRoute(builder: (_) => const MyApplicationsScreen()),
        );
        break;

      case NotificationTypes.profileIncomplete:
        navigator.push(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;

      case NotificationTypes.newJob:
        final jobId = data['jobId']?.toString() ?? '';
        if (jobId.isEmpty) return;

        final doc = await _db.collection('jobs').doc(jobId).get();
        final jobData = doc.data();
        if (!doc.exists || jobData == null) return;

        navigator.push(
          MaterialPageRoute(
            builder: (_) => JobDetailsScreen(
              job: Job.fromFirestore(doc.id, jobData),
            ),
          ),
        );
        break;

    // ---- Employer / admin: root screen is the dashboard ------------------
      case NotificationTypes.newApplication:
      case NotificationTypes.flaggedPost:
      case NotificationTypes.jobApproved:
      case NotificationTypes.jobRejected:
        navigator.popUntil((route) => route.isFirst);
        break;

    // ---- Chat -----------------------------------------------------------
      case NotificationTypes.chatMessage:
      // TODO(chat team): push your ChatScreen here using
      //   data['chatId'] and data['senderName'].
        navigator.popUntil((route) => route.isFirst);
        break;

    // ---- announcements & unknown types just open the app ---------------
      default:
        break;
    }
  }

  // =====================================================================
  // SENDING PUSH NOTIFICATIONS (app -> another user / topic)
  // =====================================================================

  /// Sends a push to every device registered for [uid].
  Future<void> sendToUser({
    required String uid,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    if (uid.isEmpty || uid == FirebaseAuth.instance.currentUser?.uid) return;

    final ref = _db.collection('notification_settings').doc(uid);
    final snapshot = await ref.get();
    final tokens = List<String>.from(snapshot.data()?['tokens'] ?? const []);
    if (tokens.isEmpty) return;

    final deadTokens = <String>[];

    for (final token in tokens) {
      final result = await PushSender.sendToToken(
        token: token,
        title: title,
        body: body,
        data: data,
      );

      if (result == PushResult.invalidToken) deadTokens.add(token);
      if (result == PushResult.notConfigured) return;
    }

    if (deadTokens.isNotEmpty) {
      try {
        await ref.update({'tokens': FieldValue.arrayRemove(deadTokens)});
      } catch (_) {
        // Firestore rules may forbid cleaning another user's document.
      }
    }
  }

  Future<PushResult> sendToTopic({
    required String topic,
    required String title,
    required String body,
    required Map<String, String> data,
  }) {
    return PushSender.sendToTopic(
      topic: topic,
      title: title,
      body: body,
      data: data,
    );
  }

  // =====================================================================
  // EVENTS  -  call these from the screens
  // =====================================================================

  /// JOB SEEKER submitted an application.
  ///  * local "Application received" notification for the applicant
  ///  * push "New application" to the job publisher
  Future<void> notifyApplicationSubmitted({
    required String applicationId,
    required String jobId,
    required String jobTitle,
    required String company,
    String? publisherId,
  }) {
    return _guard(() async {
      await showLocal(
        title: 'Application received',
        body: 'Your application for $jobTitle at $company was submitted.',
        data: _data(NotificationTypes.applicationSubmitted, {
          'applicationId': applicationId,
          'jobId': jobId,
        }),
      );

      final title = 'New application received';
      final body = '${_currentUserName()} applied for $jobTitle.';
      final data = _data(NotificationTypes.newApplication, {
        'applicationId': applicationId,
        'jobId': jobId,
      });

      if (publisherId != null && publisherId.isNotEmpty) {
        await sendToUser(
          uid: publisherId,
          title: title,
          body: body,
          data: data,
        );
      } else {
        // Older jobs have no publisherId: let the admins know instead.
        await sendToTopic(
          topic: NotificationTopics.admins,
          title: title,
          body: body,
          data: data,
        );
      }
    });
  }

  /// EMPLOYER / ADMIN changed an application status -> push to the applicant.
  Future<void> notifyApplicationStatusChanged({
    required String applicationId,
    required String applicantUid,
    required String jobTitle,
    required String company,
    required String status,
    DateTime? interviewAt,
  }) {
    return _guard(() async {
      final text = _statusMessage(status, jobTitle, company, interviewAt);

      await sendToUser(
        uid: applicantUid,
        title: text.$1,
        body: text.$2,
        data: _data(NotificationTypes.applicationStatus, {
          'applicationId': applicationId,
          'status': status,
          if (interviewAt != null)
            'interviewAt': interviewAt.toUtc().toIso8601String(),
        }),
      );
    });
  }

  /// CHAT: call this right after a chat message is saved.
  /// Works for recruiter -> applicant AND applicant -> recruiter.
  Future<void> notifyChatMessage({
    required String recipientUid,
    required String senderName,
    required String message,
    required String chatId,
  }) {
    return _guard(() async {
      final preview =
      message.length > 120 ? '${message.substring(0, 117)}...' : message;

      await sendToUser(
        uid: recipientUid,
        title: senderName,
        body: preview,
        data: _data(NotificationTypes.chatMessage, {
          'chatId': chatId,
          'senderName': senderName,
        }),
      );
    });
  }

  /// NEW JOB: broadcast to everyone subscribed to the job's category topic.
  Future<void> notifyNewJobPosted({
    required String jobId,
    required String title,
    required String company,
    required String category,
  }) {
    return _guard(() async {
      await sendToTopic(
        topic: NotificationTopics.forCategory(category),
        title: 'New $category job',
        body: '$title at $company',
        data: _data(NotificationTypes.newJob, {
          'jobId': jobId,
          'category': category,
        }),
      );
    });
  }

  /// REPORT POST: tells all admins that a job was flagged.
  Future<void> notifyJobReported({
    required String jobId,
    required String jobTitle,
    required String reason,
  }) {
    return _guard(() async {
      await sendToTopic(
        topic: NotificationTopics.admins,
        title: 'Job post reported',
        body: '"$jobTitle" was reported: $reason',
        data: _data(NotificationTypes.flaggedPost, {'jobId': jobId}),
      );
    });
  }

  /// MODERATION (for when job approval is built): tells the publisher
  /// whether an admin approved or rejected their post.
  Future<void> notifyJobModeration({
    required String publisherUid,
    required String jobId,
    required String jobTitle,
    required bool approved,
    String? reason,
  }) {
    return _guard(() async {
      await sendToUser(
        uid: publisherUid,
        title: approved ? 'Job post approved' : 'Job post rejected',
        body: approved
            ? '"$jobTitle" is now live.'
            : '"$jobTitle" was rejected${reason == null ? '.' : ': $reason'}',
        data: _data(
          approved ? NotificationTypes.jobApproved : NotificationTypes.jobRejected,
          {'jobId': jobId},
        ),
      );
    });
  }

  /// ADMIN BROADCAST to a topic (defaults to every user).
  Future<PushResult> broadcastAnnouncement({
    required String title,
    required String body,
    String topic = NotificationTopics.allUsers,
  }) {
    return sendToTopic(
      topic: topic,
      title: title,
      body: body,
      data: _data(NotificationTypes.announcement),
    );
  }

  // =====================================================================
  // LOCAL SCHEDULED NOTIFICATIONS
  // =====================================================================

  /// Schedules "tomorrow" (24 h before) and "in 1 hour" reminders on THIS
  /// device. Safe to call repeatedly: old reminders for the same application
  /// are replaced.
  Future<void> scheduleInterviewReminders({
    required String applicationId,
    required String jobTitle,
    required String company,
    required DateTime interviewAt,
  }) async {
    if (!isSupported) return;

    await cancelInterviewReminders(applicationId);

    final now = DateTime.now();
    final slots = <({String key, Duration before, String title})>[
      (key: 'day', before: const Duration(days: 1), title: 'Interview tomorrow'),
      (key: 'hour', before: const Duration(hours: 1), title: 'Interview in 1 hour'),
    ];

    for (final slot in slots) {
      final when = interviewAt.subtract(slot.before);
      if (!when.isAfter(now)) continue;

      try {
        await _local.zonedSchedule(
          id: _stableId('interview_${slot.key}_$applicationId'),
          title: slot.title,
          body: '$jobTitle at $company - ${_formatDateTime(interviewAt)}',
          // An absolute moment in time, so the time-zone database is not needed.
          scheduledDate: tz.TZDateTime.from(when, tz.UTC),
          notificationDetails: _details,
          // Inexact = no special "exact alarm" permission needed on Android 12+.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: jsonEncode(
            _data(NotificationTypes.interviewReminder, {
              'applicationId': applicationId,
            }),
          ),
        );
      } catch (e) {
        debugPrint('Interview reminder schedule error: $e');
      }
    }
  }

  Future<void> cancelInterviewReminders(String applicationId) async {
    if (!isSupported) return;
    await _local.cancel(id: _stableId('interview_day_$applicationId'));
    await _local.cancel(id: _stableId('interview_hour_$applicationId'));
  }

  /// Makes the reminders on this device match the applications stored in
  /// Firestore. Costs one query per run, so it is throttled on app resume.
  Future<void> syncInterviewReminders() async {
    if (!isSupported || _isAdmin) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final query = await _db
          .collection('applications')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'Interview Scheduled')
          .get();

      final activeIds = <String>{};

      for (final doc in query.docs) {
        final data = doc.data();
        final interviewAt = data['interviewAt'];
        if (interviewAt is! Timestamp) continue;

        activeIds.add(doc.id);

        await scheduleInterviewReminders(
          applicationId: doc.id,
          jobTitle: data['jobTitle']?.toString() ?? 'your interview',
          company: data['company']?.toString() ?? '',
          interviewAt: interviewAt.toDate(),
        );
      }

      // Cancel reminders whose interview was cancelled / status changed.
      final pending = await _local.pendingNotificationRequests();
      for (final request in pending) {
        final payload = request.payload;
        if (payload == null) continue;

        try {
          final map = jsonDecode(payload);
          if (map is Map &&
              map['type'] == NotificationTypes.interviewReminder &&
              !activeIds.contains(map['applicationId'])) {
            await _local.cancel(id: request.id);
          }
        } catch (_) {}
      }

      _lastInterviewSync = DateTime.now();
    } catch (e) {
      debugPrint('Interview sync error: $e');
    }
  }

  /// Schedules a "finish your profile" reminder 24 h from now when the profile
  /// is incomplete (and cancels it once it is complete).
  Future<void> checkProfileCompleteness() async {
    if (!isSupported || _isAdmin) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data() ?? <String, dynamic>{};

      final incomplete = _requiredProfileFields.any(
            (field) => (data[field]?.toString().trim() ?? '').isEmpty,
      );

      if (!incomplete) {
        await _local.cancel(id: _profileReminderId);
        return;
      }

      final pending = await _local.pendingNotificationRequests();
      if (pending.any((p) => p.id == _profileReminderId)) return;

      await _local.zonedSchedule(
        id: _profileReminderId,
        title: 'Complete your profile',
        body: 'Finish your profile to get better job matches.',
        scheduledDate: tz.TZDateTime.from(
          DateTime.now().add(_profileReminderDelay),
          tz.UTC,
        ),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: jsonEncode(_data(NotificationTypes.profileIncomplete)),
      );
    } catch (e) {
      debugPrint('Profile reminder error: $e');
    }
  }

  void _onAppResumed() {
    if (_currentUid == null || _isAdmin) return;

    final last = _lastInterviewSync;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(minutes: 10)) {
      return;
    }

    unawaited(syncInterviewReminders());
  }

  // =====================================================================
  // HELPERS
  // =====================================================================

  Map<String, String> _data(
      String type, [
        Map<String, String> extra = const {},
      ]) {
    return {'type': type, ...extra};
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      // A failed notification must never break the real action.
      debugPrint('Notification error: $e');
    }
  }

  String _currentUserName() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;

    final email = user?.email ?? '';
    if (email.contains('@')) return email.split('@').first;

    return 'A candidate';
  }

  (String, String) _statusMessage(
      String status,
      String jobTitle,
      String company,
      DateTime? interviewAt,
      ) {
    switch (status) {
      case 'Under Review':
        return (
        'Application under review',
        'Your application for $jobTitle at $company is being reviewed.',
        );
      case 'Shortlisted':
        return (
        'You have been shortlisted!',
        'Good news - $company shortlisted you for $jobTitle.',
        );
      case 'Interview Scheduled':
        return (
        'Interview scheduled',
        interviewAt == null
            ? 'An interview was scheduled for $jobTitle at $company.'
            : 'Your interview for $jobTitle at $company is on '
            '${_formatDateTime(interviewAt)}.',
        );
      case 'Interviewed':
        return (
        'Interview completed',
        'Thanks for interviewing for $jobTitle at $company. '
            'We will update you soon.',
        );
      case 'Hired':
        return (
        'Congratulations, you are hired!',
        '$company offered you the $jobTitle position.',
        );
      case 'Rejected':
        return (
        'Application update',
        'Unfortunately $company decided not to move forward with your '
            'application for $jobTitle.',
        );
      default:
        return (
        'Application status updated',
        'Your application for $jobTitle at $company is now "$status".',
        );
    }
  }

  String _formatDateTime(DateTime value) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';

    return '${weekdays[local.weekday - 1]}, ${local.day} '
        '${months[local.month - 1]} ${local.year} at $hour:$minute $suffix';
  }

  /// Same text -> same notification id on every launch (so it can be cancelled).
  int _stableId(String text) {
    var hash = 0x811c9dc5;
    for (final unit in text.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this.onResumed);

  final VoidCallback onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResumed();
  }
}
