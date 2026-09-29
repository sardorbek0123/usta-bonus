import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../auth/phone_screen.dart' show PhoneInputFormatter;
import 'submission_success_screen.dart';

/// Kod tasdiqlangandan keyin: foto, manzil va izoh.
class SubmissionFormScreen extends ConsumerStatefulWidget {
  const SubmissionFormScreen({super.key, required this.check});

  final CodeCheckResult check;

  @override
  ConsumerState<SubmissionFormScreen> createState() => _SubmissionFormScreenState();
}

class _SubmissionFormScreenState extends ConsumerState<SubmissionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _clientPhone = TextEditingController();
  final _comment = TextEditingController();
  final _picker = ImagePicker();
  final List<String> _photos = [];
  double? _lat;
  double? _lng;
  bool _locating = false;
  bool _sending = false;
  bool _photosError = false;

  @override
  void dispose() {
    _address.dispose();
    _clientPhone.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: Text(context.tr('take_photo')),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(context.tr('from_gallery')),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      // Rasm telefonda siqiladi: sekin internetda ham tez yuklanadi.
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 75,
      );
      if (file == null || !mounted) return;
      setState(() {
        _photos.add(file.path);
        _photosError = false;
      });
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) showMessage(context, context.tr('location_off'));
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) showMessage(context, context.tr('location_denied'));
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    final photosOk = _photos.length >= AppConfig.minPhotos;
    setState(() => _photosError = !photosOk);
    if (!formOk || !photosOk) return;

    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      final result = await ref.read(repoProvider).createSubmission(SubmissionInput(
            code: widget.check.code,
            photoPaths: List.of(_photos),
            address: _address.text,
            lat: _lat,
            lng: _lng,
            clientPhone: _clientPhone.text.replaceAll(RegExp(r'\D'), ''),
            comment: _comment.text,
          ));
      refreshAfterPointsChange(ref);
      if (!mounted) return;
      replace<void>(
        context,
        SubmissionSuccessScreen(result: result, product: widget.check.product!),
      );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.check.product!;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('form_title'))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              // Kod va mahsulot
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppColors.success),
                        const SizedBox(width: 8),
                        Text(context.tr('code_valid'),
                            style: const TextStyle(
                                color: AppColors.success, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text(widget.check.code,
                            style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(context.tr('product'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(context.loc(product.name),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${context.tr('you_will_get')}: +${formatPoints(context.lang, product.points)}',
                        style: const TextStyle(
                            color: AppColors.success, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Fotolar
              Text(context.tr('photos'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                context.tr('photos_hint',
                    {'min': AppConfig.minPhotos, 'max': AppConfig.maxPhotos}),
                style: TextStyle(
                  color: _photosError ? AppColors.danger : AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 104,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < _photos.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(File(_photos[i]),
                                  width: 104, height: 104, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _photos.removeAt(i)),
                                child: const CircleAvatar(
                                  radius: 13,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close_rounded,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_photos.length < AppConfig.maxPhotos)
                      InkWell(
                        onTap: _addPhoto,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _photosError ? AppColors.danger : AppColors.border,
                              width: _photosError ? 1.6 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_rounded, color: AppColors.brand),
                              const SizedBox(height: 6),
                              Text(context.tr('add_photo'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_photosError) ...[
                const SizedBox(height: 6),
                Text(context.tr('photos_required'),
                    style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
              const SizedBox(height: 20),

              // Manzil
              TextFormField(
                controller: _address,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: context.tr('address'),
                  hintText: context.tr('address_hint'),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? context.tr('required') : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _locating ? null : _detectLocation,
                    icon: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(_lat == null
                            ? Icons.my_location_rounded
                            : Icons.location_on_rounded),
                    label: Text(context.tr(
                        _lat == null ? 'detect_location' : 'location_detected')),
                  ),
                  if (_lat != null)
                    Expanded(
                      child: Text(
                        '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientPhone,
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneInputFormatter()],
                decoration: InputDecoration(
                  labelText: context.tr('client_phone'),
                  prefixText: '+998 ',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _comment,
                maxLines: 3,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: context.tr('comment')),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: context.tr('submit'),
                icon: Icons.send_rounded,
                loading: _sending,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
