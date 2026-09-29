import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repoProvider);

    void copy(String text) {
      Clipboard.setData(ClipboardData(text: text));
      showMessage(context, '${context.tr('copied')}: $text');
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('help'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          SectionHeader(title: context.tr('faq')),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final item in repo.faq)
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(context.loc(item.question),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedAlignment: Alignment.centerLeft,
                      children: [
                        Text(context.loc(item.answer),
                            style: const TextStyle(height: 1.5, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(title: context.tr('contact_us')),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone_rounded, color: AppColors.brand),
                  title: Text(context.tr('support_phone')),
                  subtitle: const Text(AppConfig.supportPhone),
                  trailing: const Icon(Icons.copy_rounded, size: 20),
                  onTap: () => copy(AppConfig.supportPhone),
                ),
                const Divider(indent: 56),
                ListTile(
                  leading: const Icon(Icons.send_rounded, color: AppColors.brand),
                  title: const Text('Telegram'),
                  subtitle: const Text(AppConfig.supportTelegram),
                  trailing: const Icon(Icons.copy_rounded, size: 20),
                  onTap: () => copy(AppConfig.supportTelegram),
                ),
              ],
            ),
          ),
          if (AppConfig.demoMode) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: SectionHeader(title: context.tr('demo_codes'))),
                const DemoBadge(),
              ],
            ),
            Text(context.tr('demo_codes_sub'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final code in repo.demoCodes)
                  ActionChip(
                    label: Text(code, style: const TextStyle(fontFamily: 'monospace')),
                    onPressed: () => copy(code),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
