import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';

import 'notification_types.dart';

enum PushResult {
  /// FCM accepted the message.
  sent,

  /// The device token is dead (app uninstalled / token rotated). Remove it.
  invalidToken,

  /// Network / permission / payload problem. See the debug console.
  failed,

  /// assets/config/service_account.json is missing or still the placeholder.
  notConfigured,
}

/// Sends push notifications through the FCM HTTP v1 API directly from the app.
///
/// WHY THIS EXISTS: on the free Spark plan you cannot run Cloud Functions, so
/// the app itself has to call FCM. FCM v1 needs an OAuth token, which is
/// created from a service-account key stored in
/// `assets/config/service_account.json`.
///
/// SECURITY WARNING: anything bundled in an APK can be extracted. Use a
/// service account that ONLY has the role "Firebase Cloud Messaging API
/// Admin" (see the setup steps), never the default admin key. For a real
/// production release move this class's logic into a Cloud Function / small
/// server and keep the rest of the app unchanged.
class PushSender {
  PushSender._();

  static const String _assetPath = 'assets/config/service_account.json';
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  static AutoRefreshingAuthClient? _client;
  static String? _projectId;
  static bool _setupFailed = false;

  // --------------------------------------------------------------------
  // Public API
  // --------------------------------------------------------------------

  static Future<PushResult> sendToToken({
    required String token,
    required String title,
    required String body,
    Map<String, String> data = const {},
    bool dataOnly = false,
  }) {
    return _send(
      _buildMessage(
        token: token,
        title: title,
        body: body,
        data: data,
        dataOnly: dataOnly,
      ),
    );
  }

  static Future<PushResult> sendToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, String> data = const {},
    bool dataOnly = false,
  }) {
    return _send(
      _buildMessage(
        topic: topic,
        title: title,
        body: body,
        data: data,
        dataOnly: dataOnly,
      ),
    );
  }

  // --------------------------------------------------------------------
  // Internals
  // --------------------------------------------------------------------

  static Map<String, dynamic> _buildMessage({
    String? token,
    String? topic,
    required String title,
    required String body,
    required Map<String, String> data,
    required bool dataOnly,
  }) {
    // title/body are duplicated inside `data` so that data-only messages
    // (and the in-app handlers) can still render the text.
    final payload = <String, String>{
      ...data,
      'title': title,
      'body': body,
    };

    return {
      if (token != null) 'token': token,
      if (topic != null) 'topic': topic,
      if (!dataOnly) 'notification': {'title': title, 'body': body},
      'data': payload,
      'android': {
        'priority': 'HIGH',
        if (!dataOnly)
          'notification': {
            'channel_id': NotificationChannels.highImportance,
            'sound': 'default',
          },
      },
      'apns': {
        'headers': {'apns-priority': '10'},
        'payload': {
          'aps': {'sound': 'default'},
        },
      },
    };
  }

  static Future<bool> _ensureReady() async {
    if (_client != null && _projectId != null) return true;
    if (_setupFailed) return false;

    try {
      final raw = await rootBundle.loadString(_assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;

      final privateKey = json['private_key']?.toString() ?? '';
      if (!privateKey.startsWith('-----BEGIN')) {
        debugPrint(
          'PushSender: $_assetPath is still the placeholder. '
              'Push sending is disabled until you paste your service-account key.',
        );
        _setupFailed = true;
        return false;
      }

      _projectId = json['project_id']?.toString();
      _client = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson(json),
        _scopes,
      );
      return _projectId != null;
    } catch (e) {
      debugPrint('PushSender setup error: $e');
      _setupFailed = true;
      return false;
    }
  }

  static Future<PushResult> _send(Map<String, dynamic> message) async {
    if (!await _ensureReady()) return PushResult.notConfigured;

    final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
    );

    try {
      final response = await _client!.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) return PushResult.sent;

      final body = response.body;
      final tokenIsDead = response.statusCode == 404 ||
          body.contains('UNREGISTERED') ||
          body.contains('not a valid FCM registration token');

      if (message.containsKey('token') && tokenIsDead) {
        return PushResult.invalidToken;
      }

      debugPrint('FCM send failed (${response.statusCode}): $body');
      return PushResult.failed;
    } catch (e) {
      debugPrint('FCM send error: $e');
      return PushResult.failed;
    }
  }
}
