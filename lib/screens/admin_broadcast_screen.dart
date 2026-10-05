import 'package:flutter/material.dart';

import 'package:careerwise_sample/services/notification_service.dart';
import 'package:careerwise_sample/services/notification_types.dart';
import 'package:careerwise_sample/services/push_sender.dart';

/// Admin-only screen: sends an announcement push to a topic.
class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String _audience = NotificationTopics.allUsers;
  bool _isSending = false;

  static const Color _primary = Color(0xFF4F46E5);

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    final result = await NotificationService.instance.broadcastAnnouncement(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      topic: _audience,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    String message;
    switch (result) {
      case PushResult.sent:
        message = 'Announcement sent.';
        _titleController.clear();
        _bodyController.clear();
        break;
      case PushResult.notConfigured:
        message = 'Add your service account key to '
            'assets/config/service_account.json first.';
        break;
      default:
        message = 'Sending failed. Check the debug console.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Send Announcement'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Push notification to users who have announcements turned on.',
                style: TextStyle(color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _audience,
                decoration: const InputDecoration(
                  labelText: 'Audience',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: NotificationTopics.allUsers,
                    child: Text('Everyone'),
                  ),
                  DropdownMenuItem(
                    value: NotificationTopics.admins,
                    child: Text('Admins only'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _audience = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                (value == null || value.trim().isEmpty)
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyController,
                maxLength: 200,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                (value == null || value.trim().isEmpty)
                    ? 'Please enter a message'
                    : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isSending ? null : _send,
                  icon: _isSending
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.campaign_outlined),
                  label: Text(_isSending ? 'Sending...' : 'Send'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
