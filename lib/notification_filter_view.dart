import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

class NotificationFilterView extends StatefulWidget {
  const NotificationFilterView({Key? key}) : super(key: key);

  @override
  State<NotificationFilterView> createState() => _NotificationFilterViewState();
}

class _NotificationFilterViewState extends State<NotificationFilterView> {
  List<String> blockedApps = [];
  List<String> recentNotifications = [];
  bool isListenerEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBlockedApps();
    _checkNotificationPermission();
    _startListeningToNotifications();
  }

  /// Load blocked apps from SharedPreferences
  Future<void> _loadBlockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      blockedApps = prefs.getStringList('blockedApps') ?? [];
    });
  }

  /// Save blocked apps to SharedPreferences
  Future<void> _saveBlockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blockedApps', blockedApps);
  }

  /// Check if the notification listener permission is granted
  Future<void> _checkNotificationPermission() async {
    final status = await NotificationListenerService.isPermissionGranted();
    setState(() {
      isListenerEnabled = status;
    });
  }

  /// Start listening to notifications
  void _startListeningToNotifications() {
    NotificationListenerService.notificationsStream.listen((notification) {
      if (!blockedApps.contains(notification.packageName)) {
        setState(() {
          recentNotifications.insert(
            0,
            '${notification.packageName}: ${notification.title} - ${notification.content}',
          );
          if (recentNotifications.length > 20) {
            recentNotifications.removeLast();
          }
        });
      }
    });
  }

  /// Request permission to access notifications
  Future<void> _requestPermission() async {
    await NotificationListenerService.requestPermission();
    _checkNotificationPermission();
  }

  /// Toggle blocking an app
  void _toggleAppBlock(String packageName) {
    setState(() {
      if (blockedApps.contains(packageName)) {
        blockedApps.remove(packageName);
      } else {
        blockedApps.add(packageName);
      }
    });
    _saveBlockedApps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff040D21),
      body: Column(
        children: [
          if (!isListenerEnabled)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: _requestPermission,
                child: const Text('Enable Notification Access'),
              ),
            ),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'Recent Notifications'),
                      Tab(text: 'Blocked Apps'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildRecentNotifications(),
                        _buildBlockedApps(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the recent notifications tab
  Widget _buildRecentNotifications() {
    return ListView.builder(
      itemCount: recentNotifications.length,
      itemBuilder: (context, index) {
        return Card(
          color: const Color(0xff1A1F25),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(
              recentNotifications[index],
              style: const TextStyle(color: Colors.white),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.block, color: Colors.red),
              onPressed: () {
                final packageName = recentNotifications[index].split(':')[0];
                _toggleAppBlock(packageName);
              },
            ),
          ),
        );
      },
    );
  }

  /// Build the blocked apps tab
  Widget _buildBlockedApps() {
    return ListView.builder(
      itemCount: blockedApps.length,
      itemBuilder: (context, index) {
        return Card(
          color: const Color(0xff1A1F25),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(
              blockedApps[index],
              style: const TextStyle(color: Colors.white),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _toggleAppBlock(blockedApps[index]),
            ),
          ),
        );
      },
    );
  }
}
