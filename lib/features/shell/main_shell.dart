import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../scan/scan_screen.dart';
import '../shop/shop_screen.dart';
import '../submissions/submissions_screen.dart';

/// Pastki menyu (4 bo'lim) + markazdagi QR skanerlash tugmasi.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _pages = <Widget>[
    HomeScreen(),
    SubmissionsScreen(),
    ShopScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(tabProvider);
    final tabs = ref.read(tabProvider.notifier);

    Widget item(int i, IconData icon, IconData activeIcon, String labelKey) {
      final selected = index == i;
      final color = selected ? AppColors.brand : AppColors.textSecondary;
      return Expanded(
        child: InkResponse(
          onTap: () => tabs.go(i),
          radius: 36,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? activeIcon : icon, color: color),
              const SizedBox(height: 2),
              Text(
                context.tr(labelKey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: index, children: _pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          heroTag: 'scan',
          shape: const CircleBorder(),
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          elevation: 3,
          tooltip: context.tr('scan_cta_title'),
          onPressed: () => push<void>(context, const ScanScreen()),
          child: const Icon(Icons.qr_code_scanner_rounded, size: 30),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        height: 68,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          children: [
            item(0, Icons.home_outlined, Icons.home_rounded, 'nav_home'),
            item(1, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'nav_submissions'),
            const SizedBox(width: 72),
            item(2, Icons.storefront_outlined, Icons.storefront_rounded, 'nav_shop'),
            item(3, Icons.person_outline_rounded, Icons.person_rounded, 'nav_profile'),
          ],
        ),
      ),
    );
  }
}
