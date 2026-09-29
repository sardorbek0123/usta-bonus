import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import 'register_screen.dart';

/// 6 xonali tasdiqlash kodi. Demo rejimda 6 ta bir xil raqam qabul qilinadi.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const _length = 6;

  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  int _secondsLeft = AppConfig.otpResendSeconds;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = AppConfig.otpResendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resend() async {
    try {
      await ref.read(repoProvider).sendOtp(widget.phone);
      if (!mounted) return;
      showMessage(context, context.tr('code_resent'));
      _startTimer();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  void _onChanged(String value) {
    if (_loading) return;
    if (_error != null) setState(() => _error = null);
    setState(() {});
    if (value.length == _length) _verify(value);
  }

  Future<void> _verify(String code) async {
    setState(() => _loading = true);
    try {
      final user = await ref.read(repoProvider).verifyOtp(widget.phone, code);
      if (!mounted) return;
      if (user != null) {
        ref.read(sessionProvider.notifier).signedIn(user);
        popToRoot(context);
      } else {
        replace<void>(context, RegisterScreen(phone: widget.phone));
      }
    } catch (e) {
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _error = e is ApiException ? context.tr(e.messageKey) : context.tr('error_generic');
      });
      HapticFeedback.mediumImpact();
      _focus.requestFocus();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(
              context.tr('otp_title'),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('otp_subtitle', {'phone': formatPhone(widget.phone)}),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 28),

            // Ko'rinmas maydon + 6 ta katak
            Stack(
              children: [
                Opacity(
                  opacity: 0,
                  child: SizedBox(
                    height: 1,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(_length),
                      ],
                      onChanged: _onChanged,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _focus.requestFocus(),
                  child: Row(
                    children: [
                      for (var i = 0; i < _length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _Cell(
                              char: i < code.length ? code[i] : '',
                              active: i == code.length && !_loading,
                              error: _error != null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(_error!,
                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
            if (AppConfig.demoMode) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(context.tr('otp_demo_hint'))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_secondsLeft > 0)
              Text(
                context.tr('otp_resend_in', {'s': _secondsLeft}),
                style: const TextStyle(color: AppColors.textSecondary),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: _resend, child: Text(context.tr('otp_resend'))),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.tr('change_number')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.char, required this.active, required this.error});

  final String char;
  final bool active;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final borderColor = error
        ? AppColors.danger
        : active
            ? AppColors.brand
            : AppColors.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: active || error ? 1.8 : 1),
      ),
      child: Text(char, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
    );
  }
}
