import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'conf/app_colors.dart';
import 'conf/app_providers.dart';
import 'conf/theme_provider.dart';
import 'conf/user_profile_provider.dart';
import 'screens/auth/complete_profile_prompt_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/offers/agent/agent_main_screen.dart';
import 'screens/offers/client/client_main_screen.dart';
import 'services/app_navigator.dart';
import 'services/auth_service.dart';
import 'widgets/global_notification_overlay.dart';

void main() {
  final themeProvider = ThemeProvider();
  final profileProvider = UserProfileProvider();

  AppProviders.register(
    themeProvider: themeProvider,
    profileProvider: profileProvider,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: profileProvider),
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
      navigatorKey: AppNavigator.key,
      builder: (context, child) {
        return GlobalNotificationOverlay(
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          primary: AppColors.accent,
          secondary: AppColors.accentReadable,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(
            color: AppColors.accentReadable,
            size: 18,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          primary: AppColors.accent,
          secondary: AppColors.accentReadableOnDark,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(
            color: AppColors.accentReadableOnDark,
            size: 18,
          ),
        ),
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