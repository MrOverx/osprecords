import 'package:flutter/material.dart';
import 'package:osprecords/pages/osprecords_home.dart';
import 'package:osprecords/providers/user_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Load user from prefs after provider is created
    Future.microtask(() async {
      final userProvider = UserProvider();
      await userProvider.loadUserFromPrefs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Add other providers here if needed
      ],
      child: MaterialApp(
        title: 'OSP Records',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          fontFamily: 'Arial',
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const OSPHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
