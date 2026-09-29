import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n.dart';
import '../data/models.dart';
import '../state/providers.dart';
import 'common.dart';

/// Ro'yxatdan o'tish va profilni tahrirlashda ishlatiladigan forma.
class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({
    super.key,
    required this.submitLabel,
    required this.onSubmit,
    this.initial,
  });

  final String submitLabel;
  final Future<void> Function(ProfileInput input) onSubmit;
  final AppUser? initial;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _city;
  late final TextEditingController _experience;
  String? _regionId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final u = widget.initial;
    _first = TextEditingController(text: u?.firstName ?? '');
    _last = TextEditingController(text: u?.lastName ?? '');
    _city = TextEditingController(text: u?.city ?? '');
    _experience = TextEditingController(
        text: u == null ? '' : u.experienceYears.toString());
    _regionId = u?.regionId;
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _city.dispose();
    _experience.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? context.tr('required') : null;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await widget.onSubmit(ProfileInput(
        firstName: _first.text,
        lastName: _last.text,
        regionId: _regionId!,
        city: _city.text,
        experienceYears: int.tryParse(_experience.text) ?? 0,
      ));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final regions = ref.read(repoProvider).regions;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _first,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: context.tr('first_name')),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _last,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: context.tr('last_name')),
            validator: _required,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _regionId,
            isExpanded: true,
            decoration: InputDecoration(labelText: context.tr('region')),
            items: [
              for (final r in regions)
                DropdownMenuItem(value: r.id, child: Text(context.loc(r.name))),
            ],
            onChanged: (v) => setState(() => _regionId = v),
            validator: (v) => v == null ? context.tr('required') : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: context.tr('city')),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _experience,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: InputDecoration(labelText: context.tr('experience')),
            validator: _required,
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: widget.submitLabel, loading: _loading, onPressed: _submit),
        ],
      ),
    );
  }
}
