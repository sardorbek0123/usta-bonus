import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// Ilova ichidagi bildirishnomalar. Push (FCM) backend bilan birga ulanadi.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  /// Ekrandan chiqqanda hammasi o'qilgan deb belgilanadi.
  void _onPop() {
    final container = ProviderScope.containerOf(context, listen: false);
    container
        .read(repoProvider)
        .markNotificationsRead()
        .then((_) => container.invalidate(notificationsProvider));
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _onPop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(context.tr('notifications'))),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(notificationsProvider);
            await ref.read(notificationsProvider.future);
          },
          child: AsyncView<List<AppNotification>>(
            value: notifications,
            onRetry: () => ref.invalidate(notificationsProvider),
            builder: (list) {
              if (list.isEmpty) {
                return ListView(
                  children: [
                    const SizedBox(height: 80),
                    EmptyState(
                      icon: Icons.notifications_off_outlined,
                      title: context.tr('notifications_empty'),
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _NotificationTile(n: list[i]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.n});

  final AppNotification n;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (n.kind) {
      NotificationKind.points => (Icons.stars_rounded, AppColors.success),
      NotificationKind.order => (Icons.local_shipping_rounded, const Color(0xFF1565C0)),
      NotificationKind.promo => (Icons.campaign_rounded, AppColors.brand),
      NotificationKind.system => (Icons.info_rounded, AppColors.textSecondary),
    };

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr(n.titleKey, n.args),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (!n.read)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.brand,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(context.tr(n.bodyKey, n.args)),
                const SizedBox(height: 4),
                Text(formatDateTime(n.createdAt),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
