import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:flutter/services.dart';
import 'apps_view.dart';
import 'contacts_view.dart';
import 'custom_fab.dart';
import 'location_view.dart';
import 'compass.dart';

class MyInstalledApps extends StatefulWidget {
  const MyInstalledApps({Key? key}) : super(key: key);

  @override
  State<MyInstalledApps> createState() => _MyInstalledAppsState();
}

class _MyInstalledAppsState extends State<MyInstalledApps>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sharedText = '';
  String _smartLink = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Subscribe to shared media stream
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile>? value) {
      if (value != null && value.isNotEmpty) {
        _handleSharedMedia(value);
      }
    });

    // For handling incoming shares while the app is active
    ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          _handleSharedMedia(value);
        }
      },
      onError: (err) {
        print("getMediaStream error: $err");
      },
    );
  }

  void _handleSharedMedia(List<SharedMediaFile> mediaFiles) async {
    for (SharedMediaFile mediaFile in mediaFiles) {
      if (mediaFile.path.isNotEmpty) {
        String sharedText = await _extractTextFromMedia(mediaFile);
        print(sharedText);
        setState(() {
          _sharedText = sharedText;
          _generateSmartLinkFromSharedText(sharedText);
        });
      }
    }
  }

  Future<String> _extractTextFromMedia(SharedMediaFile mediaFile) async {
    return mediaFile.path;
  }

  void _generateSmartLinkFromSharedText(String link) async {
    print(link);
    String smartLink = await _createSmartLink(link);
    //print(smartLink);

    setState(() {
      _smartLink = smartLink;
    });
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
    print(enteredLink);
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Smart link: $smartLink'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: smartLink));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Smart link copied to clipboard.'),
                ),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
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
        String shortId = data['shortid'] ?? '';

        shortId = 'https://appopener.com/web/$shortId';

        return shortId;
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Skip'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: screenHeight * 0.5,
            child: Compass(),
          ),
          if (_smartLink.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Smart link: $_smartLink'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _smartLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Smart link copied to clipboard.'),
                        ),
                      );
                    },
                    child: const Text('Copy'),
                  ),
                ],
              ),
            ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Get Location'),
              Tab(text: 'Get Contacts'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                LocationView(),
                ContactsView(),
              ],
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
