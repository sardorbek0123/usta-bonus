import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import 'orders_screen.dart';
import 'shop_item_screen.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(shopItemsProvider);
    final summary = ref.watch(summaryProvider);
    final categories = ref.read(repoProvider).shopCategories;
    final int? balance = summary.when<int?>(
      data: (s) => s.balance,
      loading: () => null,
      error: (_, _) => null,
    );

    Widget chip(String? id, String label) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: _category == id,
            onSelected: (_) => setState(() => _category = id),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('shop_title')),
        actions: [
          IconButton(
            tooltip: context.tr('my_orders'),
            onPressed: () => push<void>(context, const OrdersScreen()),
            icon: const Icon(Icons.local_shipping_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Balans
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: AppColors.brand),
                  const SizedBox(width: 8),
                  Text(context.tr('your_balance')),
                  const Spacer(),
                  Text(
                    balance == null ? '—' : formatPoints(context.lang, balance),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                chip(null, context.tr('filter_all')),
                for (final c in categories) chip(c.id, context.loc(c.name)),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(shopItemsProvider);
                ref.invalidate(summaryProvider);
                await ref.read(shopItemsProvider.future);
              },
              child: AsyncView<List<ShopItemView>>(
                value: items,
                onRetry: () => ref.invalidate(shopItemsProvider),
                builder: (all) {
                  final list = _category == null
                      ? all
                      : all.where((v) => v.item.categoryId == _category).toList();
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _ItemCard(
                      view: list[i],
                      balance: balance,
                      onTap: () => push<void>(context, ShopItemScreen(view: list[i])),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.view, required this.balance, required this.onTap});

  final ShopItemView view;
  final int? balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final item = view.item;
    final outOfStock = view.stock <= 0;
    final affordable = balance != null && balance! >= item.price;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Opacity(
                opacity: outOfStock ? 0.4 : 1,
                child: ItemIconTile(item: item, size: 88),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.loc(item.name),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.25),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.stars_rounded,
                  size: 18, color: affordable ? AppColors.brand : AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  formatNumber(item.price),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: affordable ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            outOfStock
                ? context.tr('out_of_stock')
                : context.tr('in_stock', {'n': view.stock}),
            style: TextStyle(
              fontSize: 12,
              color: outOfStock ? AppColors.danger : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
