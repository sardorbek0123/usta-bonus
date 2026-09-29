import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('my_orders'))),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ordersProvider);
          await ref.read(ordersProvider.future);
        },
        child: AsyncView<List<Order>>(
          value: orders,
          onRetry: () => ref.invalidate(ordersProvider),
          builder: (list) {
            if (list.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: context.tr('orders_empty'),
                    actionLabel: context.tr('go_to_shop'),
                    onAction: () {
                      ref.read(tabProvider.notifier).go(2);
                      popToRoot(context);
                    },
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _OrderCard(order: list[i]),
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _cancelling = false;

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(context.tr('cancel_order_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('no')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('yes')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _cancelling = true);
    try {
      await ref.read(repoProvider).cancelOrder(widget.order.id);
      refreshAfterPointsChange(ref);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final repo = ref.read(repoProvider);
    ShopItem? item;
    for (final i in repo.shopCatalog) {
      if (i.id == o.itemId) item = i;
    }
    final info = orderStatusInfo(o.status);

    String delivery;
    if (o.deliveryType == DeliveryType.pickup) {
      PickupPoint? point;
      for (final p in repo.pickupPoints) {
        if (p.id == o.pickupPointId) point = p;
      }
      delivery = point == null ? context.tr('delivery_pickup') : context.loc(point.name);
    } else {
      delivery = o.address;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(context.tr('order_no', {'id': o.id}),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              StatusChip(label: context.tr(info.labelKey), color: info.color),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              if (item != null) ItemIconTile(item: item, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item == null ? o.itemId : context.loc(item.name),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${context.tr('quantity')}: ${o.quantity} · ${formatPoints(context.lang, o.points)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                o.deliveryType == DeliveryType.pickup
                    ? Icons.storefront_rounded
                    : Icons.home_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(delivery,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(formatDateTime(o.createdAt),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          if (o.status == OrderStatus.accepted) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: AppColors.danger,
              ),
              onPressed: _cancelling ? null : _cancel,
              child: _cancelling
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(context.tr('cancel_order')),
            ),
          ],
        ],
      ),
    );
  }
}
