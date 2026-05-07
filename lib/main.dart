import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'conf/theme_provider.dart';
import 'conf/user_profile_provider.dart';
import 'screens/auth/complete_profile_prompt_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/offers/agent/agent_main_screen.dart';
import 'screens/offers/client/client_main_screen.dart';
import 'services/auth_service.dart';

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
      home: const AppStartupGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppStartupGate extends StatelessWidget {
  const AppStartupGate({super.key});

  Future<Widget> _resolveStartScreen() async {
    final hasSession = await AuthService.hasActiveSession();

    if (!hasSession) {
      return const RoleSelectionScreen();
    }

    final role = (await AuthService.getStoredRole() ?? '').toUpperCase();
    final hasSeenPrompt = await AuthService.hasSeenCompleteProfilePrompt();

    if (!hasSeenPrompt) {
      return CompleteProfilePromptScreen(role: role);
    }

    if (role == 'CLIENT') {
      return const ClientEntryScreen();
    }

    if (role == 'AGENT') {
      return const AgentEntryScreen();
    }

    return const RoleSelectionScreen();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return FutureBuilder<Widget>(
      future: _resolveStartScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return const RoleSelectionScreen();
        }

        return snapshot.data ?? const RoleSelectionScreen();
      },
    );
  }
}