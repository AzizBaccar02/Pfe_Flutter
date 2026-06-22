import 'theme_provider.dart';
import 'user_profile_provider.dart';

/// Root providers — use from async code instead of [BuildContext.read].
abstract final class AppProviders {
  static late final ThemeProvider theme;
  static late final UserProfileProvider profile;

  static void register({
    required ThemeProvider themeProvider,
    required UserProfileProvider profileProvider,
  }) {
    theme = themeProvider;
    profile = profileProvider;
  }
}
