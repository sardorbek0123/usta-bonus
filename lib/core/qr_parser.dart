/// Stikerdagi QR ichidan kodni ajratib oladi.
///
/// QR ichida toza kod (`gpyn166n`) yoki havola bo'lishi mumkin
/// (`https://.../gpyn166n`, `https://...?code=gpyn166n`). Stikerdagi QR
/// formati aniqlangach, shu funksiya moslashtiriladi.
class QrParser {
  QrParser._();

  static final RegExp _codePattern = RegExp(r'^[a-z0-9]{8}$');

  /// Kodni normallashtiradi: bo'shliqlar olib tashlanadi, kichik harfga
  /// o'tkaziladi (Excel bazasida kodlar kichik harfda, ba'zilari
  /// katta harf bilan yozilib qolgan).
  static String normalize(String input) =>
      input.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();

  static bool isValidFormat(String code) => _codePattern.hasMatch(code);

  /// QR matnidan kod. Format mos kelmasa `null`.
  static String? extractCode(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    var candidate = text;
    final uri = Uri.tryParse(text);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      const keys = ['code', 'c', 'uuid', 'id'];
      String? fromQuery;
      for (final k in keys) {
        final v = uri.queryParameters[k];
        if (v != null && v.isNotEmpty) {
          fromQuery = v;
          break;
        }
      }
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      candidate = fromQuery ?? (segments.isEmpty ? '' : segments.last);
    }

    final code = normalize(candidate);
    return isValidFormat(code) ? code : null;
  }
}
