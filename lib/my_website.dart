import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:external_app_launcher/external_app_launcher.dart';

class MyInstalledApps extends StatefulWidget {
  const MyInstalledApps({Key? key}) : super(key: key);

  @override
  State<MyInstalledApps> createState() => _MyInstalledAppsState();
}

class _MyInstalledAppsState extends State<MyInstalledApps> {
  List<AppInfo> _installedApps = [];

  @override
  void initState() {
    super.initState();
    _getInstalledApps();
  }

  Future<void> _getInstalledApps() async {
    List<AppInfo> apps = await InstalledApps.getInstalledApps(false, true);
    setState(() {
      _installedApps = apps;
    });
  }

  Future<void> _openApp(String packageName) async {
    final isInstalled = await LaunchApp.isAppInstalled(
        androidPackageName: packageName, iosUrlScheme: packageName);
    if (isInstalled) {
      await LaunchApp.openApp(
          androidPackageName: packageName, iosUrlScheme: packageName);
    } else {
      print('App $packageName is not installed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installed Apps'),
      ),
      body: ListView.builder(
        itemCount: _installedApps.length,
        itemBuilder: (context, index) {
          final app = _installedApps[index];
          final icon = app.icon;
          Widget iconWidget;

          if (icon != null && icon.isNotEmpty) {
            iconWidget = Image.memory(icon);
          } else {
            iconWidget = const Icon(Icons.android);
          }

          return ListTile(
            leading: iconWidget,
            title: Text(app.name ?? 'Unknown'),
            subtitle: Text(app.packageName),
            onTap: () {
              _openApp(app.packageName);
            },
          );
        },
      ),
    );
  }
}
