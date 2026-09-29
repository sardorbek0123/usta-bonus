import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/profile_form.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider.select((s) => s.user));
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('edit_profile'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          ProfileForm(
            initial: user,
            submitLabel: context.tr('save'),
            onSubmit: (input) async {
              final updated = await ref.read(repoProvider).updateProfile(input);
              ref.read(sessionProvider.notifier).userUpdated(updated);
              if (!context.mounted) return;
              showMessage(context, context.tr('profile_saved'));
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
