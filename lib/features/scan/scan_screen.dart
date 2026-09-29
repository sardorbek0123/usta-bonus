import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/nav.dart';
import '../../core/qr_parser.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import 'submission_form_screen.dart';

/// QR skaner. Kod topilgach server tekshiradi:
/// yaroqli bo'lsa ariza formasiga o'tadi, aks holda sababini ko'rsatadi.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pauseCamera() async {
    try {
      await _controller.stop();
    } catch (_) {}
  }

  Future<void> _resumeCamera() async {
    try {
      await _controller.start();
    } catch (_) {}
  }

  void _onDetect(BarcodeCapture capture) {
    if (_busy || capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    HapticFeedback.selectionClick();
    // QR ichida havola bo'lsa, kod ajratib olinadi. Format mos kelmasa,
    // server "noto'g'ri format" deb javob beradi.
    _check(QrParser.extractCode(raw) ?? raw);
  }

  Future<void> _check(String input) async {
    if (_busy) return;
    setState(() => _busy = true);
    await _pauseCamera();
    try {
      final result = await ref.read(repoProvider).checkCode(input);
      if (!mounted) return;
      if (result.isValid) {
        replace<void>(context, SubmissionFormScreen(check: result));
        return;
      }
      await _showResult(result);
    } catch (e) {
      if (mounted) showError(context, e);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await _resumeCamera();
  }

  Future<void> _showResult(CodeCheckResult r) {
    final (String titleKey, String subKey, IconData icon, Color color) = switch (r.status) {
      CodeCheckStatus.used => ('code_used', 'code_used_sub', Icons.block_rounded, AppColors.warning),
      CodeCheckStatus.blocked => ('code_blocked', 'code_blocked_sub', Icons.report_rounded, AppColors.danger),
      CodeCheckStatus.rateLimited => ('too_many_attempts', 'too_many_attempts_sub', Icons.lock_clock_rounded, AppColors.danger),
      CodeCheckStatus.invalidFormat => ('code_invalid_format', 'code_not_found_sub', Icons.error_outline_rounded, AppColors.danger),
      _ => ('code_not_found', 'code_not_found_sub', Icons.search_off_rounded, AppColors.danger),
    };

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 34),
              ),
              const SizedBox(height: 14),
              Text(context.tr(titleKey),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              if (r.code.isNotEmpty && r.code.length <= 32)
                Text(r.code,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(context.tr(subKey),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              if (r.usedByYouAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  context.tr('code_used_by_you', {'date': formatDate(r.usedByYouAt!)}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.tr('scan_again')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enterManually() async {
    await _pauseCamera();
    if (!mounted) return;
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _ManualCodeSheet(),
    );
    if (!mounted) return;
    if (code != null && code.isNotEmpty) {
      await _check(code);
    } else {
      await _resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _CameraError(onManual: _enterManually),
          ),
          const IgnorePointer(child: CustomPaint(painter: _ScanOverlayPainter())),

          // Yuqori panel
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  ),
                  Expanded(
                    child: Text(
                      context.tr('scan_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _controller,
                    builder: (context, state, _) {
                      final on = state.torchState == TorchState.on;
                      final available = state.torchState != TorchState.unavailable;
                      return IconButton(
                        onPressed: available ? () => _controller.toggleTorch() : null,
                        icon: Icon(
                          on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: available ? Colors.white : Colors.white38,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Pastki panel
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('scan_hint'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      onPressed: _busy ? null : _enterManually,
                      icon: const Icon(Icons.keyboard_rounded),
                      label: Text(context.tr('enter_manually')),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_busy)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(context.tr('checking'),
                      style: const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ManualCodeSheet extends StatefulWidget {
  const _ManualCodeSheet();

  @override
  State<_ManualCodeSheet> createState() => _ManualCodeSheetState();
}

class _ManualCodeSheetState extends State<_ManualCodeSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = QrParser.normalize(_controller.text);
    if (code.isEmpty) return;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr('enter_manually'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 8,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            ],
            style: const TextStyle(
                fontFamily: 'monospace', fontSize: 22, letterSpacing: 3),
            decoration: InputDecoration(
              labelText: context.tr('code_label'),
              hintText: context.tr('code_hint'),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _submit, child: Text(context.tr('check'))),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.onManual});

  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_rounded, color: Colors.white54, size: 56),
              const SizedBox(height: 12),
              Text(context.tr('camera_error'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(200, 50)),
                onPressed: onManual,
                child: Text(context.tr('enter_manually')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Qorong'i fon, markazda kvadrat "oyna" va burchak chiziqlari.
class _ScanOverlayPainter extends CustomPainter {
  const _ScanOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width * 0.7;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.45),
      width: side,
      height: side,
    );
    final hole = RRect.fromRectAndRadius(rect, const Radius.circular(24));

    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(hole);
    canvas.drawPath(mask, Paint()..color = Colors.black.withValues(alpha: 0.55));

    final corner = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 34.0;
    final l = rect.left, t = rect.top, r = rect.right, b = rect.bottom;
    canvas
      ..drawLine(Offset(l, t + len), Offset(l, t + 12), corner)
      ..drawLine(Offset(l + 12, t), Offset(l + len, t), corner)
      ..drawLine(Offset(r - len, t), Offset(r - 12, t), corner)
      ..drawLine(Offset(r, t + 12), Offset(r, t + len), corner)
      ..drawLine(Offset(l, b - len), Offset(l, b - 12), corner)
      ..drawLine(Offset(l + 12, b), Offset(l + len, b), corner)
      ..drawLine(Offset(r - len, b), Offset(r - 12, b), corner)
      ..drawLine(Offset(r, b - 12), Offset(r, b - len), corner);
    canvas
      ..drawArc(Rect.fromLTWH(l, t, 24, 24), 3.1416, 1.5708, false, corner)
      ..drawArc(Rect.fromLTWH(r - 24, t, 24, 24), -1.5708, 1.5708, false, corner)
      ..drawArc(Rect.fromLTWH(l, b - 24, 24, 24), 1.5708, 1.5708, false, corner)
      ..drawArc(Rect.fromLTWH(r - 24, b - 24, 24, 24), 0, 1.5708, false, corner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
