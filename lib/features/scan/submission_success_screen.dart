import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import 'scan_screen.dart';

class SubmissionSuccessScreen extends ConsumerWidget {
  const SubmissionSuccessScreen({super.key, required this.result, required this.product});

  final SubmissionResult result;
  final ProductType product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = result.submission;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: AppColors.success, size: 72),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '+${formatPoints(context.lang, s.points)}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('success_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('success_sub', {'code': s.code}),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                context.loc(product.name),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${context.tr('new_balance')}: ',
                        style: const TextStyle(color: AppColors.textSecondary)),
                    Text(formatPoints(context.lang, result.newBalance),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => replace<void>(context, const ScanScreen()),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: Text(context.tr('scan_more')),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  ref.read(tabProvider.notifier).go(0);
                  popToRoot(context);
                },
                child: Text(context.tr('to_home')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
