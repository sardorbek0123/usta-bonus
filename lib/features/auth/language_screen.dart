import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/common.dart';

/// Birinchi ekran (splash + til tanlash). Profil sozlamalaridan ham ochiladi.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key, this.fromSettings = false});

  final bool fromSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(sessionProvider.select((s) => s.lang));
    final chosen = ref.watch(sessionProvider.select((s) => s.languageChosen));

    Future<void> select(AppLang lang) async {
      await ref.read(sessionProvider.notifier).setLanguage(lang);
      if (fromSettings && context.mounted) Navigator.of(context).pop();
    }

    final options = Column(
      children: [
        for (final lang in AppLang.values) ...[
          AppCard(
            onTap: () => select(lang),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lang.label,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      if (lang.subLabel.isNotEmpty)
                        Text(lang.subLabel,
                            style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (chosen && lang == current)
                  const Icon(Icons.check_circle_rounded, color: AppColors.brand)
                else
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );

    if (fromSettings) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('language'))),
        body: Padding(padding: const EdgeInsets.all(16), child: options),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const AppLogo(size: 88),
              const SizedBox(height: 10),
              Text(
                context.tr('tagline'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.tr('choose_language'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              options,
            ],
          ),
        ),
      ),
    );
  }
}
