import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n.dart';
import '../data/api_repository.dart';
import '../data/models.dart';

/// Backend. `main.dart` da [LocalBackend] bilan almashtiriladi.
final repoProvider = Provider<ApiRepository>(
  (ref) => throw UnimplementedError('repoProvider main.dart da beriladi'),
);

/// Ilova ishga tushganda o'qilgan boshlang'ich holat.
class Bootstrap {
  const Bootstrap({required this.lang, required this.languageChosen, this.user});
  final AppLang lang;
  final bool languageChosen;
  final AppUser? user;
}

final bootstrapProvider = Provider<Bootstrap>(
  (ref) => throw UnimplementedError('bootstrapProvider main.dart da beriladi'),
);

// ---------------------------------------------------------------------------
// Sessiya: til va joriy foydalanuvchi
// ---------------------------------------------------------------------------

class SessionState {
  const SessionState({
    required this.lang,
    required this.languageChosen,
    this.user,
  });

  final AppLang lang;
  final bool languageChosen;
  final AppUser? user;

  bool get isLoggedIn => user != null;

  SessionState copyWith({
    AppLang? lang,
    bool? languageChosen,
    AppUser? user,
    bool clearUser = false,
  }) =>
      SessionState(
        lang: lang ?? this.lang,
        languageChosen: languageChosen ?? this.languageChosen,
        user: clearUser ? null : (user ?? this.user),
      );
}

class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() {
    final b = ref.read(bootstrapProvider);
    return SessionState(
      lang: b.lang,
      languageChosen: b.languageChosen,
      user: b.user,
    );
  }

  ApiRepository get _repo => ref.read(repoProvider);

  Future<void> setLanguage(AppLang lang) async {
    await _repo.saveLanguage(lang.code);
    state = state.copyWith(lang: lang, languageChosen: true);
  }

  /// Kirish yoki ro'yxatdan o'tishdan keyin.
  void signedIn(AppUser user) {
    _invalidateUserData();
    state = state.copyWith(user: user);
  }

  /// Profil tahrirlangandan keyin.
  void userUpdated(AppUser user) => state = state.copyWith(user: user);

  Future<void> logout() async {
    await _repo.logout();
    state = state.copyWith(clearUser: true);
    _invalidateUserData();
  }

  Future<void> deleteAccount() async {
    await _repo.deleteAccount();
    state = state.copyWith(clearUser: true);
    _invalidateUserData();
  }

  void _invalidateUserData() {
    ref.invalidate(summaryProvider);
    ref.invalidate(submissionsProvider);
    ref.invalidate(historyProvider);
    ref.invalidate(shopItemsProvider);
    ref.invalidate(ordersProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(tabProvider);
  }
}

final sessionProvider =
    NotifierProvider<SessionNotifier, SessionState>(SessionNotifier.new);

// ---------------------------------------------------------------------------
// Ma'lumotlar
// ---------------------------------------------------------------------------

final summaryProvider = FutureProvider<PointsSummary>(
  (ref) => ref.watch(repoProvider).getPointsSummary(),
);

final submissionsProvider = FutureProvider<List<Submission>>(
  (ref) => ref.watch(repoProvider).getSubmissions(),
);

final historyProvider = FutureProvider<List<PointTx>>(
  (ref) => ref.watch(repoProvider).getPointsHistory(),
);

final shopItemsProvider = FutureProvider<List<ShopItemView>>(
  (ref) => ref.watch(repoProvider).getShopItems(),
);

final ordersProvider = FutureProvider<List<Order>>(
  (ref) => ref.watch(repoProvider).getOrders(),
);

final notificationsProvider = FutureProvider<List<AppNotification>>(
  (ref) => ref.watch(repoProvider).getNotifications(),
);

/// Asosiy ekrandagi tanlangan bo'lim (0 bosh sahifa, 1 arizalar,
/// 2 do'kon, 3 profil).
class TabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void go(int index) => state = index;
}

final tabProvider = NotifierProvider<TabNotifier, int>(TabNotifier.new);

/// Ball, arizalar yoki buyurtmalar o'zgargandan keyin chaqiriladi.
void refreshAfterPointsChange(WidgetRef ref) {
  ref.invalidate(summaryProvider);
  ref.invalidate(submissionsProvider);
  ref.invalidate(historyProvider);
  ref.invalidate(shopItemsProvider);
  ref.invalidate(ordersProvider);
  ref.invalidate(notificationsProvider);
}
