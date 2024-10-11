import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:loginskipp/spanswer_view.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:flutter/services.dart';
import 'apps_view.dart';
import 'contacts_view.dart';
import 'custom_fab.dart';
import 'location_view.dart';
import 'compass.dart';
import 'package:url_launcher/url_launcher.dart';

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
  int _selectedIndex = 1;
  bool _isFabExpanded = false;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

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

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData; // Capture QR code result
        _sharedText = result!.code!;
        _generateSmartLinkFromSharedText(_sharedText);
      });
    });
  }

  Future<void> goToWebPage(String urlString) async {
    final Uri _url = Uri.parse(urlString);

    if (await canLaunchUrl(_url)) {
      await launchUrl(_url,
          mode: LaunchMode.externalApplication); // Opens in an external browser
    } else {
      print('Could not launch $_url');
      throw 'Could not launch $_url';
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
    const String apiUrl = 'https://api-opnr.onrender.com/createOpenURL';

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

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
    });
  }

  @override
  void dispose() {
    controller?.dispose(); // Dispose of the QR controller properly
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xff040D21),
      appBar: AppBar(
        backgroundColor: Color(0xff040D21),
        title: const Text(
          'Login Skip',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: screenHeight * 0.45,
                  child: QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                    overlay: QrScannerOverlayShape(
                      borderColor: Colors.white,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: screenHeight * 0.3,
                    ),
                  ),
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
                                content:
                                    Text('Smart link copied to clipboard.'),
                              ),
                            );
                          },
                          child: const Text('Copy'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicator: const BoxDecoration(),
                  onTap: (index) {
                    setState(() {
                      if (index != 1) {
                        _selectedIndex = index;
                      }
                    });
                  },
                  tabs: [
                    _buildTab('Get Location', 0),
                    Tab(
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/spawnser.png',
                          height: 46,
                          width: 46,
                          fit: BoxFit
                              .cover, // Ensures the image fits within the circular shape
                        ),
                      ),
                    ),
                    _buildTab('Get Contacts', 2),
                  ],
                ),
                SizedBox(
                  height: screenHeight * 0.3,
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      LocationView(),
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            Center(
                              child: SpanswerView(
                                radius:
                                    140, // Adjust the radius to fit your design
                                itemCount: 5, // Number of circular icons
                                /*onIconPressed: (index) {
                                  // Handle icon presses
                                  print('Icon $index pressed');
                                },*/
                              ),
                            ),
                          ],
                        ),
                      ),
                      ContactsView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: screenHeight * 0.35,
            right: 5,
            child: Container(
              width: 56.0, // Set your custom width
              height:
                  56.0, // Set your custom height (same as width for a perfect circle)
              decoration: const BoxDecoration(
                color: Color(0xff040D21), // Background color
                shape: BoxShape.circle, // Circular shape
              ),
              child: IconButton(
                icon: Image.asset("assets/images/AppOpener.png"),
                onPressed: _toggleFab,
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.35,
            left: 3,
            child: Container(
              width: 80.0, // Set your custom width
              height:
                  60.0, // Set your custom height (same as width for a perfect circle)
              decoration: const BoxDecoration(
                color: Color(0xff040D21), // Background color
                shape: BoxShape.circle, // Circular shape
              ),
              child: const Compass(),
            ),
          ),
          if (_isFabExpanded) ...[
            Positioned(
              top: screenHeight * 0.35 - 80,
              right: 5,
              child: Container(
                width: 56.0, // Set your custom width
                height:
                    56.0, // Set your custom height (same as width for a perfect circle)
                decoration: const BoxDecoration(
                  color: Color(0xff040D21), // Background color
                  shape: BoxShape.circle, // Circular shape
                ),
                child: IconButton(
                  icon: Image.asset(
                    "assets/images/rocket-solid.png",
                    height: 25,
                    width: 25,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    await goToWebPage("https://www.appopener.com/");
                  },
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.35 + 80,
              right: 5,
              child: Container(
                width: 56.0, // Set your custom width
                height:
                    56.0, // Set your custom height (same as width for a perfect circle)
                decoration: const BoxDecoration(
                  color: Color(0xff040D21), // Background color
                  shape: BoxShape.circle, // Circular shape
                ),
                child: IconButton(
                  icon: Image.asset(
                    "assets/images/arrow-trend-up-solid.png",
                    height: 25,
                    width: 25,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    await goToWebPage("https://www.appopener.com/trending");
                  },
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.35,
              right: 85,
              child: Container(
                width: 56.0, // Set your custom width
                height:
                    56.0, // Set your custom height (same as width for a perfect circle)
                decoration: const BoxDecoration(
                  color: Color(0xff040D21), // Background color
                  shape: BoxShape.circle, // Circular shape
                ),
                child: IconButton(
                  icon: Image.asset(
                    "assets/images/book-open-reader-solid.png",
                    height: 25,
                    width: 25,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    await goToWebPage("https://www.appopener.com/blog");
                  },
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: CustomFAB(
        onPressed: _generateSmartLink,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTab(String text, int index) {
    bool isSelected = _selectedIndex == index;

    return Tab(
      child: Container(
        decoration: BoxDecoration(
            color:
                isSelected ? Colors.grey.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: //isSelected
                Border.all(
                    color: Colors.grey, width: 1) // Border for selected tab
            //: null, // No border for unselected tabs
            ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
