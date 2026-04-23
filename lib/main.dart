import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'conf/theme_provider.dart';
import 'conf/user_profile_provider.dart';
import 'screens/auth/role_selection_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'JobMatch App',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.grey,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.grey,
        useMaterial3: true,
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const RoleSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}