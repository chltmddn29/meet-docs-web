import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/sidebar.dart';
import '../provider/meeting_provider.dart';
import '../model/meeting_model.dart';

class DetailScreen extends ConsumerWidget {
  final int meetingId;
  const DetailScreen({super.key, required this.meetingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingAsync = ref.watch(meetingDetailProvider(meetingId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          const Sidebar(),
          const VerticalDivider(width: 1),
          Expanded(
            child: meetingAsync.when(
              data: (meeting) => SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 뒤로가기 + 제목
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          meeting.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 56),
                      child: Text(
                        meeting.formattedDate,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 안건별 정리 (간결 버전)
                    ...meeting.agendaItems.map(
                      (item) => _AgendaCard(item: item),
                    ),

                    if (meeting.agendaItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            '정리된 안건이 없습니다',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaCard extends StatelessWidget {
  final AgendaItem item;
  const _AgendaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 700,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item.order}. ${item.agenda}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (item.decision != null && item.decision!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '결정',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.decision!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF378ADD),
              ),
            ),
          ],
          if (item.actionItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '할 일',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            ...item.actionItems.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_box_outline_blank, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(a, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
