import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:careerwise_sample/services/notification_service.dart';
import 'package:careerwise_sample/services/notification_types.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final Color primaryBlue = const Color(0xFF1565C0);

  bool isLoading = true;
  bool permissionAllowed = true;
  bool isSendingTest = false;
  String? loadError;

  NotificationPrefs prefs = const NotificationPrefs(
    announcements: true,
    categories: <String>{},
    isAdmin: false,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final loaded = await NotificationService.instance.loadPrefs();
      final allowed = await NotificationService.instance.areNotificationsAllowed();

      if (!mounted) return;
      setState(() {
        prefs = loaded;
        permissionAllowed = allowed || !NotificationService.isSupported;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadError = '$e';
        isLoading = false;
      });
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _toggleAnnouncements(bool value) async {
    final previous = prefs;
    setState(() {
      prefs = NotificationPrefs(
        announcements: value,
        categories: prefs.categories,
        isAdmin: prefs.isAdmin,
      );
    });

    try {
      await NotificationService.instance.setAnnouncementsEnabled(value);
    } catch (e) {
      if (!mounted) return;
      setState(() => prefs = previous);
      _snack('Could not update setting: $e');
    }
  }

  Future<void> _toggleCategory(String category, bool selected) async {
    final previous = prefs;
    final updated = Set<String>.from(prefs.categories);
    selected ? updated.add(category) : updated.remove(category);

    setState(() {
      prefs = NotificationPrefs(
        announcements: prefs.announcements,
        categories: updated,
        isAdmin: prefs.isAdmin,
      );
    });

    try {
      await NotificationService.instance.setCategorySubscribed(
        category,
        selected,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => prefs = previous);
      _snack('Could not update job alerts: $e');
    }
  }

  Future<void> _enablePermission() async {
    await NotificationService.instance.requestPermission();
    final allowed = await NotificationService.instance.areNotificationsAllowed();

    if (!mounted) return;
    setState(() => permissionAllowed = allowed);

    if (!allowed) {
      _snack('Please enable notifications for CareerWise in system settings.');
    }
  }

  Future<void> _sendTest() async {
    setState(() => isSendingTest = true);
    final message = await NotificationService.instance.sendTestPush();
    if (!mounted) return;
    setState(() => isSendingTest = false);
    _snack(message);
  }

  Future<void> _copyToken() async {
    final token = await NotificationService.instance.getDeviceToken();
    if (token == null) {
      _snack('No FCM token available on this platform.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: token));
    _snack('FCM token copied. Paste it in Firebase Console > Messaging > Send test message.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load settings:\n\n$loadError',
            textAlign: TextAlign.center,
          ),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!permissionAllowed) _permissionCard(),
          _card(
            title: 'Announcements',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Platform announcements'),
              subtitle: const Text(
                'Maintenance notices, new features and events.',
              ),
              value: prefs.announcements,
              onChanged: _toggleAnnouncements,
            ),
          ),
          if (!prefs.isAdmin) _jobAlertsCard(),
          _card(
            title: 'Always on',
            child: const Text(
              'Application updates, interview reminders and '
                  'messages are always delivered.',
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
          ),
          _card(
            title: 'Test this device',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sends a real push through FCM to this phone. '
                      'Press it, then put the app in the background '
                      'to test that state.',
                  style: TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isSendingTest ? null : _sendTest,
                      icon: isSendingTest
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.notifications_active_outlined),
                      label: const Text('Send test'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _copyToken,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy FCM token'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_outlined, color: Colors.orange),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Notifications are turned off for this app.'),
          ),
          TextButton(
            onPressed: _enablePermission,
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  Widget _jobAlertsCard() {
    return _card(
      title: 'Job alerts',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Get notified when a new job is posted in the categories you pick.',
            style: TextStyle(color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: JobCategories.all.map((category) {
              final selected = prefs.categories.contains(category);
              return FilterChip(
                label: Text(category),
                selected: selected,
                selectedColor: primaryBlue.withOpacity(0.15),
                checkmarkColor: primaryBlue,
                onSelected: (value) => _toggleCategory(category, value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
