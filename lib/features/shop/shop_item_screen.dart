import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import 'checkout_screen.dart';

class ShopItemScreen extends ConsumerWidget {
  const ShopItemScreen({super.key, required this.view});

  final ShopItemView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = view.item;
    final summary = ref.watch(summaryProvider);
    final int? balance = summary.when<int?>(
      data: (s) => s.balance,
      loading: () => null,
      error: (_, _) => null,
    );
    final outOfStock = view.stock <= 0;
    final missing = balance == null ? 0 : item.price - balance;

    String buttonLabel;
    VoidCallback? onPressed;
    if (outOfStock) {
      buttonLabel = context.tr('out_of_stock');
    } else if (balance == null) {
      buttonLabel = context.tr('get');
    } else if (missing > 0) {
      buttonLabel = context.tr('not_enough', {'n': formatPoints(context.lang, missing)});
    } else {
      buttonLabel = context.tr('get');
      onPressed = () => push<void>(
            context,
            CheckoutScreen(view: view, balance: balance),
          );
    }

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Icon(item.icon, size: 110, color: item.color),
          ),
          const SizedBox(height: 20),
          Text(context.loc(item.name),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: AppColors.brand),
              const SizedBox(width: 6),
              Text(formatPoints(context.lang, item.price),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const Spacer(),
              StatusChip(
                label: outOfStock
                    ? context.tr('out_of_stock')
                    : context.tr('in_stock', {'n': view.stock}),
                color: outOfStock ? AppColors.danger : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(context.tr('description'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(context.loc(item.description), style: const TextStyle(height: 1.5)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
        ),
      ),
    );
  }
}
