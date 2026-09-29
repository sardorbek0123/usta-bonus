import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

class PointsHistoryScreen extends ConsumerWidget {
  const PointsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(summaryProvider);
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('points_history'))),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(summaryProvider);
          ref.invalidate(historyProvider);
          await ref.read(historyProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            AsyncView<PointsSummary>(
              value: summary,
              builder: (s) => AppCard(
                child: Row(
                  children: [
                    _Metric(
                      label: context.tr('your_balance'),
                      value: formatNumber(s.balance),
                      color: AppColors.brand,
                    ),
                    _Metric(
                      label: context.tr('total_earned'),
                      value: formatNumber(s.totalEarned),
                      color: AppColors.success,
                    ),
                    _Metric(
                      label: context.tr('total_spent'),
                      value: formatNumber(s.totalSpent),
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            AsyncView<List<PointTx>>(
              value: history,
              onRetry: () => ref.invalidate(historyProvider),
              builder: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.stars_rounded,
                    title: context.tr('history_empty'),
                  );
                }
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < list.length; i++) ...[
                        _TxTile(tx: list[i]),
                        if (i < list.length - 1) const Divider(indent: 68),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx});

  final PointTx tx;

  @override
  Widget build(BuildContext context) {
    final (String key, IconData icon) = switch (tx.type) {
      PointTxType.earn => ('tx_earn', Icons.construction_rounded),
      PointTxType.redeem => ('tx_redeem', Icons.card_giftcard_rounded),
      PointTxType.refund => ('tx_refund', Icons.undo_rounded),
      PointTxType.imported => ('tx_import', Icons.move_down_rounded),
      PointTxType.adjust => ('tx_adjust', Icons.tune_rounded),
    };
    final positive = tx.amount >= 0;
    final color = positive ? AppColors.success : AppColors.textPrimary;

    String? ref = tx.refId;
    if (ref != null &&
        (tx.type == PointTxType.redeem || tx.type == PointTxType.refund)) {
      ref = context.tr('order_no', {'id': ref});
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (positive ? AppColors.success : AppColors.brand).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                size: 22, color: positive ? AppColors.success : AppColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(key), style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  [if (ref != null) ref, formatDateTime(tx.createdAt)].join(' · '),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : ''}${formatNumber(tx.amount)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
