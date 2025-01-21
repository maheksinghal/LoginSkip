import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'my_website.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'AIzaSyBYhKnMicD8d2pDC-w_w9Hje0P8oF6A7I4',
        appId: '1:315628564065:android:ed8388489b31c1ced20420',
        messagingSenderId: '315628564065',
        projectId: 'loginskip-bf6ab',
        storageBucket: 'loginskip-bf6ab.firebasestorage.app',
      ));
  runApp(const MyApp());
  //FirebaseAnalytics.instance.logAppOpen();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyInstalledApps(),
    );
  }
}
