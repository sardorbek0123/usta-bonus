import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/profile_form.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key, required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('register_title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(
              context.tr('register_subtitle'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ProfileForm(
              submitLabel: context.tr('finish_registration'),
              onSubmit: (input) async {
                final user = await ref.read(repoProvider).register(phone, input);
                ref.read(sessionProvider.notifier).signedIn(user);
                if (context.mounted) popToRoot(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
