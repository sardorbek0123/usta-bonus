import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/i18n.dart';
import 'data/local_backend.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Backend tayyor bo'lgach shu yerda HttpApiRepository beriladi.
  final repo = await LocalBackend.create();
  final savedLang = await repo.getSavedLanguage();
  final user = await repo.restoreSession();

  runApp(
    ProviderScope(
      // Xato bo'lsa avtomatik qayta so'ramaymiz: ekranda "Qayta urinish" bor.
      retry: (_, _) => null,
      overrides: [
        repoProvider.overrideWithValue(repo),
        bootstrapProvider.overrideWithValue(Bootstrap(
          lang: AppLang.fromCode(savedLang),
          languageChosen: savedLang != null,
          user: user,
        )),
      ],
      child: const UstaBonusApp(),
    ),
  );
}
