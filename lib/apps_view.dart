import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

enum AppFilter {
  userApps,
  systemApps,
  allApps,
}

class AppsView extends StatefulWidget {
  const AppsView({Key? key}) : super(key: key);

  @override
  _AppsViewState createState() => _AppsViewState();
}

class _AppsViewState extends State<AppsView>
    with AutomaticKeepAliveClientMixin {
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
    if (mounted) {
      setState(() {
        _installedApps = apps;
        _searchResult = List.from(apps);
      });
    }
  }

  /*void _searchApp(String query) {
    List<AppInfo> searchResult = _installedApps.where((app) {
      String name = app.name.toLowerCase() ?? '';
      String packageName = app.packageName.toLowerCase();
      return name.contains(query.toLowerCase()) ||
          packageName.contains(query.toLowerCase());
    }).toList();
    setState(() {
      _searchResult = searchResult;
    });
  }*/

  /*void _applyFilter(AppFilter filter) {
    _searchController.clear();
    switch (filter) {
      case AppFilter.userApps:
        _title = 'User Apps';
        _filterUserApps();
        break;
      case AppFilter.systemApps:
        _title = 'System Apps';
        _filterSystemApps();
        break;
      case AppFilter.allApps:
        _title = 'All Apps';
        setState(() {
          _searchResult = List.from(_installedApps);
        });
        break;
    }
  }*/

  /* Future<void> _filterUserApps() async {
    List<AppInfo> filteredApps = [];
    for (var app in _installedApps) {
      bool? isSystemApp = await InstalledApps.isSystemApp(app.packageName);
      if (isSystemApp != null && !isSystemApp) {
        filteredApps.add(app);
      }
    }
    if (mounted) {
      setState(() {
        _searchResult = filteredApps;
      });
    }
  }*/

  /*Future<void> _filterSystemApps() async {
    List<AppInfo> filteredApps = [];
    for (var app in _installedApps) {
      bool? isSystemApp = await InstalledApps.isSystemApp(app.packageName);
      if (isSystemApp != null && isSystemApp) {
        filteredApps.add(app);
      }
    }
    if (mounted) {
      setState(() {
        _searchResult = filteredApps;
      });
    }
  }*/

  Future<void> _openApp(String packageName) async {
    await InstalledApps.startApp(packageName);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        /*Padding(
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
        ),*/
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
                title: Text(app.name),
                subtitle: Text(app.packageName),
                onTap: () {
                  _openApp(app.packageName);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
