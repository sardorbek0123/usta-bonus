import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// App Store talabi: foydalanuvchi akkauntini ilova ichidan o'chira olishi kerak.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() => _loading = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      final text = context.tr('account_deleted');
      final session = ref.read(sessionProvider.notifier);
      popToRoot(context);
      await session.deleteAccount();
      messenger.showSnackBar(SnackBar(content: Text(text)));
    } catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = context.tr('delete_word');
    final int balance = ref.watch(summaryProvider).when<int>(
          data: (s) => s.balance,
          loading: () => 0,
          error: (_, _) => 0,
        );
    final confirmed = _controller.text.trim().toUpperCase() == word.toUpperCase();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('delete_account'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 64),
          const SizedBox(height: 16),
          Text(
            context.tr('delete_warning', {'points': formatNumber(balance)}),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),
          Text(context.tr('delete_type', {'word': word}),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(hintText: word),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: confirmed && !_loading ? _delete : null,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : Text(context.tr('delete_account')),
          ),
        ],
      ),
    );
  }
}
