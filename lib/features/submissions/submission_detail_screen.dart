import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

class SubmissionDetailScreen extends ConsumerWidget {
  const SubmissionDetailScreen({super.key, required this.submission});

  final Submission submission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = submission;
    final info = submissionStatusInfo(s.status);
    final types = ref.read(repoProvider).productTypes;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('submission'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // Holat
          AppCard(
            child: Row(
              children: [
                Icon(info.icon, color: info.color, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr(info.labelKey),
                          style: TextStyle(
                              color: info.color,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      if (s.status == SubmissionStatus.approved)
                        Text('+${formatPoints(context.lang, s.points)}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (s.rejectReason != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('reject_reason'),
                      style: const TextStyle(
                          color: AppColors.danger, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(context.loc(s.rejectReason!)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Fotolar
          if (s.photoPaths.isNotEmpty)
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: s.photoPaths.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(s.photoPaths[i]),
                    width: 180,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _noPhoto(context),
                  ),
                ),
              ),
            )
          else
            SizedBox(height: 90, child: _noPhoto(context)),
          const SizedBox(height: 16),

          // Ma'lumotlar
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _Row(label: context.tr('code'), value: s.code, mono: true),
                _Row(
                    label: context.tr('product'),
                    value: productNameOf(context, types, s.productTypeId)),
                _Row(label: context.tr('date'), value: formatDateTime(s.createdAt)),
                if (s.address.isNotEmpty)
                  _Row(label: context.tr('address'), value: s.address),
                if (s.lat != null && s.lng != null)
                  _Row(
                    label: context.tr('coordinates'),
                    value: '${s.lat!.toStringAsFixed(5)}, ${s.lng!.toStringAsFixed(5)}',
                  ),
                if (s.clientPhone.isNotEmpty)
                  _Row(label: context.tr('client_phone'), value: formatPhone(s.clientPhone)),
                if (s.comment.isNotEmpty)
                  _Row(label: context.tr('comment'), value: s.comment),
              ],
            ),
          ),
          if (s.source == 'telegram') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(context.tr('source_telegram'),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Holat tarixi
          SectionHeader(title: context.tr('status_history')),
          AppCard(
            child: Column(
              children: [
                _TimelineItem(
                  color: AppColors.textSecondary,
                  title: context.tr('submitted'),
                  date: formatDateTime(s.createdAt),
                  last: s.reviewedAt == null,
                ),
                if (s.reviewedAt != null)
                  _TimelineItem(
                    color: info.color,
                    title: context.tr(info.labelKey),
                    date: formatDateTime(s.reviewedAt!),
                    last: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noPhoto(BuildContext context) => Container(
        width: 180,
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_not_supported_rounded, color: AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(context.tr('no_photos'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.color,
    required this.title,
    required this.date,
    required this.last,
  });

  final Color color;
  final String title;
  final String date;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              if (!last)
                Expanded(child: Container(width: 2, color: AppColors.border)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(date,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
