import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../auth/phone_screen.dart' show PhoneInputFormatter;
import 'orders_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.view, required this.balance});

  final ShopItemView view;
  final int balance;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _address;
  late final TextEditingController _phone;
  int _qty = 1;
  DeliveryType _delivery = DeliveryType.pickup;
  String? _pickupId;
  bool _sending = false;

  ShopItem get _item => widget.view.item;
  int get _maxQty {
    final byBalance = widget.balance ~/ _item.price;
    final m = math.min(math.min(widget.view.stock, byBalance), 10);
    return m < 1 ? 1 : m;
  }
  int get _total => _item.price * _qty;

  @override
  void initState() {
    super.initState();
    final user = ref.read(sessionProvider).user;
    _address = TextEditingController(text: user?.city ?? '');
    _phone = TextEditingController(
        text: user == null ? '' : PhoneInputFormatter.format(user.phone));
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      final order = await ref.read(repoProvider).createOrder(OrderInput(
            itemId: _item.id,
            quantity: _qty,
            deliveryType: _delivery,
            address: _delivery == DeliveryType.courier ? _address.text : '',
            pickupPointId: _delivery == DeliveryType.pickup ? _pickupId : null,
            contactPhone: _phone.text.replaceAll(RegExp(r'\D'), ''),
          ));
      refreshAfterPointsChange(ref);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
          title: Text(context.tr('order_created')),
          content: Text(
            '${context.tr('order_no', {'id': order.id})}\n${context.tr('order_created_sub')}',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr('ok')),
            ),
          ],
        ),
      );
      if (!mounted) return;
      final nav = Navigator.of(context);
      nav.popUntil((r) => r.isFirst);
      nav.push(MaterialPageRoute<void>(builder: (_) => const OrdersScreen()));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = ref.read(repoProvider).pickupPoints;
    final lang = context.lang;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('checkout_title'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            AppCard(
              child: Row(
                children: [
                  ItemIconTile(item: _item),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.loc(_item.name),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(formatPoints(lang, _item.price),
                            style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Soni
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(context.tr('quantity'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  IconButton.outlined(
                    onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text('$_qty',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  IconButton.outlined(
                    onPressed: _qty < _maxQty ? () => setState(() => _qty++) : null,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Olish usuli
            Text(context.tr('delivery'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: RadioGroup<DeliveryType>(
                groupValue: _delivery,
                onChanged: (v) {
                  if (v != null) setState(() => _delivery = v);
                },
                child: Column(
                  children: [
                    RadioListTile<DeliveryType>(
                      value: DeliveryType.pickup,
                      title: Text(context.tr('delivery_pickup')),
                    ),
                    const Divider(),
                    RadioListTile<DeliveryType>(
                      value: DeliveryType.courier,
                      title: Text(context.tr('delivery_courier')),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_delivery == DeliveryType.pickup)
              DropdownButtonFormField<String>(
                initialValue: _pickupId,
                isExpanded: true,
                decoration: InputDecoration(labelText: context.tr('pickup_point')),
                items: [
                  for (final p in points)
                    DropdownMenuItem(value: p.id, child: Text(context.loc(p.name))),
                ],
                onChanged: (v) => setState(() => _pickupId = v),
                validator: (v) => v == null ? context.tr('required') : null,
              )
            else
              TextFormField(
                controller: _address,
                maxLines: 2,
                minLines: 1,
                decoration: InputDecoration(labelText: context.tr('delivery_address')),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? context.tr('required') : null,
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [PhoneInputFormatter()],
              decoration: InputDecoration(
                labelText: context.tr('contact_phone'),
                prefixText: '+998 ',
              ),
              validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length == 9
                  ? null
                  : context.tr('phone_invalid'),
            ),
            const SizedBox(height: 20),

            // Jami
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(context.tr('total'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text(formatPoints(lang, _total),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(context.tr('balance_after'),
                          style: const TextStyle(color: AppColors.textSecondary)),
                      const Spacer(),
                      Text(formatPoints(lang, widget.balance - _total),
                          style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: context.tr('confirm_order'),
              loading: _sending,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }
}
