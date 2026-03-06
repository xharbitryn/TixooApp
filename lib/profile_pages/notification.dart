import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final status = await Permission.notification.status;
    setState(() {
      _isEnabled = status.isGranted;
    });
  }

  Future<void> _toggleNotification(bool value) async {
    if (value) {
      final status = await Permission.notification.status;
      if (status.isGranted) {
        // Already granted
        setState(() => _isEnabled = true);
      } else {
        // Request permission
        PermissionStatus requestStatus = await Permission.notification
            .request();
        if (requestStatus.isGranted) {
          setState(() => _isEnabled = true);
        } else {
          setState(() => _isEnabled = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Notification permission denied")),
          );
        }
      }
    } else {
      // You can't really "turn off" notification permission programmatically
      setState(() => _isEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
            ),
            title: const Text(
              "Push Notification",
              style: TextStyle(color: Colors.white),
            ),
            trailing: Switch(
              value: _isEnabled,
              onChanged: _toggleNotification,
              activeColor: Colors.green,
            ),
          ),
        ),
      ),
    );
  }
}
