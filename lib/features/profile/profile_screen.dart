import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../auth/language_screen.dart';
import '../points/points_history_screen.dart';
import '../shop/orders_screen.dart';
import 'delete_account_screen.dart';
import 'edit_profile_screen.dart';
import 'help_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final user = session.user;
    final summary = ref.watch(summaryProvider);
    final notifications = ref.watch(notificationsProvider);
    final repo = ref.read(repoProvider);
    if (user == null) return const SizedBox.shrink();

    String regionName = user.regionId;
    for (final r in repo.regions) {
      if (r.id == user.regionId) regionName = context.loc(r.name);
    }
    final int unread = notifications.when<int>(
      data: (l) => l.where((n) => !n.read).length,
      loading: () => 0,
      error: (_, _) => 0,
    );

    Future<void> logout() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(context.tr('logout_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.tr('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.tr('logout')),
            ),
          ],
        ),
      );
      if (ok == true) await ref.read(sessionProvider.notifier).logout();
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('nav_profile'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.brand.withValues(alpha: 0.12),
                  child: Text(user.initials,
                      style: const TextStyle(
                          color: AppColors.brand, fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(formatPhone(user.phone),
                          style: const TextStyle(color: AppColors.textSecondary)),
                      Text('$regionName, ${user.city}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(context.tr('member_since', {'date': formatDate(user.createdAt)}),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: context.tr('stats_installs'),
                  value: summary.when(
                    data: (s) => formatNumber(s.installsCount),
                    loading: () => '—',
                    error: (_, _) => '—',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Stat(
                  label: context.tr('stats_points'),
                  value: summary.when(
                    data: (s) => formatNumber(s.totalEarned),
                    loading: () => '—',
                    error: (_, _) => '—',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.edit_outlined,
                  title: context.tr('edit_profile'),
                  onTap: () => push<void>(context, const EditProfileScreen()),
                ),
                _MenuTile(
                  icon: Icons.stars_outlined,
                  title: context.tr('points_history'),
                  onTap: () => push<void>(context, const PointsHistoryScreen()),
                ),
                _MenuTile(
                  icon: Icons.local_shipping_outlined,
                  title: context.tr('my_orders'),
                  onTap: () => push<void>(context, const OrdersScreen()),
                ),
                _MenuTile(
                  icon: Icons.notifications_none_rounded,
                  title: context.tr('notifications'),
                  trailing: unread > 0 ? Badge(label: Text('$unread')) : null,
                  onTap: () => push<void>(context, const NotificationsScreen()),
                ),
                _MenuTile(
                  icon: Icons.language_rounded,
                  title: context.tr('language'),
                  trailing: Text(session.lang.label,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  onTap: () => push<void>(context, const LanguageScreen(fromSettings: true)),
                ),
                _MenuTile(
                  icon: Icons.help_outline_rounded,
                  title: context.tr('help'),
                  onTap: () => push<void>(context, const HelpScreen()),
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.logout_rounded,
                  title: context.tr('logout'),
                  onTap: logout,
                ),
                _MenuTile(
                  icon: Icons.delete_outline_rounded,
                  title: context.tr('delete_account'),
                  color: AppColors.danger,
                  onTap: () => push<void>(context, const DeleteAccountScreen()),
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(context.tr('version', {'v': '0.1.0'}),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              if (AppConfig.demoMode) ...[
                const SizedBox(width: 8),
                const DemoBadge(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.color,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? color;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: color ?? AppColors.textPrimary),
          title: Text(title,
              style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailing != null) trailing!,
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
          onTap: onTap,
        ),
        if (!last) const Divider(indent: 56),
      ],
    );
  }
}
