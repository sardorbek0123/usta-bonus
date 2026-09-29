import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config.dart';
import 'core/i18n.dart';
import 'core/theme.dart';
import 'features/auth/language_screen.dart';
import 'features/auth/phone_screen.dart';
import 'features/shell/main_shell.dart';
import 'state/providers.dart';

class UstaBonusApp extends ConsumerWidget {
  const UstaBonusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(sessionProvider.select((s) => s.lang));
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      builder: (context, child) =>
          LangScope(lang: lang, child: child ?? const SizedBox.shrink()),
      home: const RootGate(),
    );
  }
}

/// Holatga qarab birinchi ekranni tanlaydi:
/// til tanlanmagan -> til, kirilmagan -> telefon, aks holda asosiy ekran.
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (!session.languageChosen) return const LanguageScreen();
    if (!session.isLoggedIn) return const PhoneScreen();
    return const MainShell();
  }
}
