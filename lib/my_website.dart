import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'custom_fab.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MyInstalledApps extends StatefulWidget {
  const MyInstalledApps({Key? key}) : super(key: key);

  @override
  State<MyInstalledApps> createState() => _MyInstalledAppsState();
}

enum AppFilter { userApps, systemApps, allApps }

class _MyInstalledAppsState extends State<MyInstalledApps> {
  late List<AppInfo> _installedApps;
  late List<AppInfo> _searchResult;
  late TextEditingController _searchController;
  String _title = 'Installed Apps';

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

  Future<void> _openApp(String packageName) async {
    await InstalledApps.startApp(packageName);
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

  void _applyFilter(AppFilter filter) {
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
  }

  Future<void> _filterUserApps() async {
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
  }

  Future<void> _filterSystemApps() async {
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _generateSmartLink() {
    TextEditingController linkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return _buildSmartLinkDialog(linkController);
      },
    );
  }

  Widget _buildSmartLinkDialog(TextEditingController linkController) {
    return AlertDialog(
      title: const Text('Generate Smart Link'),
      content: TextField(
        controller: linkController,
        decoration: const InputDecoration(
          hintText: 'Enter the link here',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            String enteredLink = linkController.text;
            Navigator.of(context)
                .pop(); // Close the dialog before making the request
            _createSmartLinkAndShowDialog(enteredLink);
          },
          child: const Text('Generate'),
        ),
      ],
    );
  }

  Future<void> _createSmartLinkAndShowDialog(String enteredLink) async {
    if (enteredLink.isNotEmpty) {
      // Call the API to generate a smart link
      String smartLink = await _createSmartLink(enteredLink);

      // Show the generated smart link
      if (smartLink.isNotEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) {
              return _buildSmartLinkGeneratedDialog(smartLink);
            },
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate smart link.'),
            ),
          );
        }
      }
    }
  }

  Widget _buildSmartLinkGeneratedDialog(String smartLink) {
    return AlertDialog(
      title: const Text('Smart Link Generated'),
      content: Text('Smart link: $smartLink'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }

  Future<String> _createSmartLink(String originalLink) async {
    const String apiUrl = 'https://api.apopnr.com/createOpenURL';

    try {
      print('Sending request to: $apiUrl');
      print('Payload: ${jsonEncode({'link': originalLink})}');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'link': originalLink,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['shortid'] ?? '';
      } else {
        print(
            'Error: Server responded with status code ${response.statusCode}');
        print('Response body: ${response.body}');
        return '';
      }
    } catch (e) {
      print('Error: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    int count = _searchResult.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('$_title ($count)'),
        actions: [
          PopupMenuButton<AppFilter>(
            onSelected: _applyFilter,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<AppFilter>>[
              const PopupMenuItem<AppFilter>(
                value: AppFilter.userApps,
                child: Text('Show User Apps'),
              ),
              const PopupMenuItem<AppFilter>(
                value: AppFilter.systemApps,
                child: Text('Show System Apps'),
              ),
              const PopupMenuItem<AppFilter>(
                value: AppFilter.allApps,
                child: Text('Show All Apps'),
              ),
            ],
          ),
        ],
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
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomCenter,
        child: CustomFAB(
          onPressed: _generateSmartLink,
        ),
      ),
    );
  }
}
