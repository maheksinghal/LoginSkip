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
  late List<AppInfo> _installedApps;
  late List<AppInfo> _searchResult;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _installedApps = [];
    _searchResult = [];
    _searchController = TextEditingController();
    _getInstalledApps();
  }

  Future<void> _getInstalledApps() async {
    List<AppInfo> apps = await InstalledApps.getInstalledApps(false, true);
    setState(() {
      _installedApps = apps;
      _searchResult = List.from(apps);
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

  void _searchApp(String query) {
    List<AppInfo> searchResult = _installedApps.where((app) {
      String name = app.name.toLowerCase() ?? '';
      String packageName = app.packageName.toLowerCase();
      return name.contains(query.toLowerCase()) ||
          packageName.contains(query.toLowerCase());
    }).toList();
    setState(() {
      _searchResult = searchResult;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Installed Apps (${_installedApps.length})'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchApp('');
                  },
                ),
              ),
              onChanged: _searchApp,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResult.length,
              itemBuilder: (context, index) {
                final app = _searchResult[index];
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
          ),
        ],
      ),
    );
  }
}
