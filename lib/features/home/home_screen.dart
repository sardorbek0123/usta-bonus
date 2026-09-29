import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../points/points_history_screen.dart';
import '../profile/notifications_screen.dart';
import '../scan/scan_screen.dart';
import '../submissions/submission_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider.select((s) => s.user));
    final summary = ref.watch(summaryProvider);
    final submissions = ref.watch(submissionsProvider);
    final notifications = ref.watch(notificationsProvider);
    final repo = ref.read(repoProvider);

    final int unread = notifications.when<int>(
      data: (list) => list.where((n) => !n.read).length,
      loading: () => 0,
      error: (_, _) => 0,
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            refreshAfterPointsChange(ref);
            await ref.read(summaryProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // Sarlavha
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('hello', {'name': user?.firstName ?? ''}),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => push<void>(context, const NotificationsScreen()),
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: const Icon(Icons.notifications_none_rounded, size: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Balans
              _BalanceCard(
                balance: summary.when(
                  data: (s) => s.balance,
                  loading: () => null,
                  error: (_, _) => null,
                ),
                onHistory: () => push<void>(context, const PointsHistoryScreen()),
              ),
              const SizedBox(height: 12),

              // Skanerlash
              AppCard(
                onTap: () => push<void>(context, const ScanScreen()),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded,
                          color: AppColors.brand, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('scan_cta_title'),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(context.tr('scan_cta_sub'),
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bannerlar
              _Banners(banners: repo.banners),
              const SizedBox(height: 16),

              // Bu oy
              SectionHeader(title: context.tr('this_month')),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.construction_rounded,
                      label: context.tr('installs'),
                      value: summary.when(
                        data: (s) => formatNumber(s.monthInstalls),
                        loading: () => '—',
                        error: (_, _) => '—',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.stars_rounded,
                      label: context.tr('earned'),
                      value: summary.when(
                        data: (s) => formatNumber(s.monthEarned),
                        loading: () => '—',
                        error: (_, _) => '—',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Oxirgi arizalar
              SectionHeader(
                title: context.tr('recent_submissions'),
                action: context.tr('see_all'),
                onAction: () => ref.read(tabProvider.notifier).go(1),
              ),
              AsyncView<List<Submission>>(
                value: submissions,
                onRetry: () => ref.invalidate(submissionsProvider),
                builder: (list) {
                  if (list.isEmpty) {
                    return AppCard(
                      child: Text(context.tr('no_submissions'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary)),
                    );
                  }
                  return Column(
                    children: [
                      for (final s in list.take(3)) ...[
                        SubmissionTile(
                          submission: s,
                          productName:
                              productNameOf(context, repo.productTypes, s.productTypeId),
                          onTap: () =>
                              push<void>(context, SubmissionDetailScreen(submission: s)),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.onHistory});

  final int? balance;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand, AppColors.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('your_balance'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                balance == null ? '—' : formatNumber(balance!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                pointsWord(context.lang, balance ?? 0),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onHistory,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.tr('points_history'),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brand),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _Banners extends StatefulWidget {
  const _Banners({required this.banners});

  final List<PromoBanner> banners;

  @override
  State<_Banners> createState() => _BannersState();
}

class _BannersState extends State<_Banners> {
  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 118,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: widget.banners.length,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (context, i) {
              final b = widget.banners[i];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: b.colors),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.loc(b.title),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.loc(b.subtitle),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(b.icon, color: Colors.white.withValues(alpha: 0.9), size: 48),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.banners.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.brand : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
