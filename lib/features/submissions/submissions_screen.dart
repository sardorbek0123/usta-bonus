import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/nav.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import 'submission_detail_screen.dart';

class SubmissionsScreen extends ConsumerStatefulWidget {
  const SubmissionsScreen({super.key});

  @override
  ConsumerState<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends ConsumerState<SubmissionsScreen> {
  /// null = hammasi
  SubmissionStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final submissions = ref.watch(submissionsProvider);
    final types = ref.read(repoProvider).productTypes;

    Widget chip(SubmissionStatus? value, String labelKey) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(context.tr(labelKey)),
            selected: _filter == value,
            onSelected: (_) => setState(() => _filter = value),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('submissions_title'))),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                chip(null, 'filter_all'),
                chip(SubmissionStatus.approved, 'status_approved'),
                chip(SubmissionStatus.rejected, 'status_rejected'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(submissionsProvider);
                await ref.read(submissionsProvider.future);
              },
              child: AsyncView<List<Submission>>(
                value: submissions,
                onRetry: () => ref.invalidate(submissionsProvider),
                builder: (all) {
                  final list = _filter == null
                      ? all
                      : all.where((s) => s.status == _filter).toList();
                  if (list.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: context.tr(all.isEmpty ? 'no_submissions' : 'submissions_empty'),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final s = list[i];
                      return SubmissionTile(
                        submission: s,
                        productName: productNameOf(context, types, s.productTypeId),
                        onTap: () => push<void>(context, SubmissionDetailScreen(submission: s)),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
