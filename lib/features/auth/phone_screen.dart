import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/common.dart';
import 'otp_screen.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();
  bool _agreed = false;
  bool _loading = false;

  String get _digits => _controller.text.replaceAll(RegExp(r'\D'), '');
  bool get _valid => _digits.length == 9 && _agreed;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await ref.read(repoProvider).sendOtp(_digits);
      if (!mounted) return;
      await push<void>(context, OtpScreen(phone: _digits));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showTerms() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('terms_title'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(context.tr('terms_text'), style: const TextStyle(height: 1.5)),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.tr('close')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            const AppLogo(size: 64, showName: false),
            const SizedBox(height: 28),
            Text(
              context.tr('phone_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('phone_subtitle'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.phone,
              inputFormatters: [PhoneInputFormatter()],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1),
              decoration: InputDecoration(
                labelText: context.tr('phone_label'),
                hintText: '90 123 45 67',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Text('+998',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
              onSubmitted: (_) {
                if (_valid) _submit();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _agreed,
                  onChanged: (v) => setState(() => _agreed = v ?? false),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _agreed = !_agreed),
                    child: Text(context.tr('agree_terms')),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: _showTerms, child: Text(context.tr('read_terms'))),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: context.tr('get_code'),
              loading: _loading,
              onPressed: _valid ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// "901234567" -> "90 123 45 67"
class PhoneInputFormatter extends TextInputFormatter {
  static String format(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('998') && digits.length > 9) digits = digits.substring(3);
    if (digits.length > 9) digits = digits.substring(0, 9);
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5 || i == 7) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = format(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
