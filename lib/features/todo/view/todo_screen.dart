import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/sidebar.dart';
import '../../../core/network/error_message.dart';
import '../../meeting/provider/meeting_provider.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todosProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          const Sidebar(),
          const VerticalDivider(width: 1),
          Expanded(
            child: todosAsync.when(
              data: (data) => _buildBody(context, ref, data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(friendlyError(e))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
  ) {
    final totalPending = data['total_pending'] ?? 0;
    final totalDone = data['total_done'] ?? 0;
    final meetings = (data['meetings'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(todosProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '할 일 모아보기',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '모든 회의에서 정리된 할 일과 한 일',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            // 요약 칩
            Row(
              children: [
                _SummaryChip(
                  label: '할 일',
                  count: totalPending,
                  color: const Color(0xFF378ADD),
                  icon: Icons.check_box_outline_blank,
                ),
                const SizedBox(width: 12),
                _SummaryChip(
                  label: '한 일',
                  count: totalDone,
                  color: const Color(0xFF0F6E56),
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (meetings.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    '아직 정리된 할 일이 없어요.\n회의를 녹음하면 여기 모입니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], height: 1.6),
                  ),
                ),
              )
            else
              ...meetings.map((m) => _MeetingTodoCard(meeting: m)),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _MeetingTodoCard extends StatelessWidget {
  final Map<String, dynamic> meeting;
  const _MeetingTodoCard({required this.meeting});

  @override
  Widget build(BuildContext context) {
    final title = meeting['meeting_title'] ?? '제목 없음';
    final meetingId = meeting['meeting_id'];
    final pending = (meeting['pending'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];
    final done = (meeting['done'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];
    final dateStr = _formatDate(meeting['created_at']);

    return Container(
      width: 720,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 회의 제목 (클릭 시 상세)
          InkWell(
            onTap: () => context.go('/detail/$meetingId'),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
              ],
            ),
          ),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...pending.map((p) => _TodoRow(item: p, done: false)),
          ],
          if (done.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...done.map((p) => _TodoRow(item: p, done: true)),
          ],
        ],
      ),
    );
  }

  String _formatDate(dynamic iso) {
    if (iso is! String) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _TodoRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool done;
  const _TodoRow({required this.item, required this.done});

  @override
  Widget build(BuildContext context) {
    final text = item['text'] ?? '';
    final agenda = item['agenda'] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.check_box_outline_blank,
            size: 18,
            color: done ? const Color(0xFF0F6E56) : const Color(0xFF378ADD),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: done ? Colors.grey[500] : Colors.black87,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (agenda.toString().isNotEmpty)
                  Text(
                    agenda,
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
