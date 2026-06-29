import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/sidebar.dart';
import '../provider/meeting_provider.dart';
import '../provider/processing_provider.dart';
import '../model/meeting_model.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final int meetingId;
  const ResultScreen({super.key, required this.meetingId});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  @override
  void initState() {
    super.initState();
    // 파이프라인은 화면 밖 provider에서 실행되므로, 다른 페이지로 이동해도
    // STT→AI정리→저장까지 끝까지 진행된다. 중복 호출은 provider가 방어한다.
    Future.microtask(
      () => ref.read(meetingProcessProvider(widget.meetingId).notifier).start(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final process = ref.watch(meetingProcessProvider(widget.meetingId));
    final step = process.step;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          const Sidebar(),
          const VerticalDivider(width: 1),
          Expanded(
            child: step == 4
                ? _buildResult()
                : step == -1
                ? _buildError(process.error ?? '')
                : _buildProcessing(step),
          ),
        ],
      ),
    );
  }

  // 처리 중 화면
  Widget _buildProcessing(int step) {
    final steps = [
      ('음성 파일 업로드', 0),
      ('음성 텍스트 변환', 1),
      ('AI 정리', 2),
      ('저장소에 저장', 3),
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(color: Color(0xFF378ADD)),
          ),
          const SizedBox(height: 32),
          const Text(
            '처리 중...',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 32),
          Container(
            width: 360,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: steps.map((s) {
                final label = s.$1;
                final stepNum = s.$2;
                final isDone = step > stepNum;
                final isCurrent =
                    step == stepNum + 1 || (step == 1 && stepNum == 0);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      isDone
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF0F6E56),
                              size: 20,
                            )
                          : isCurrent
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.circle_outlined,
                              color: Colors.grey[300],
                              size: 20,
                            ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDone || isCurrent
                              ? Colors.black87
                              : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 에러 화면
  Widget _buildError(String errorMessage) {
    final isShortRecording =
        errorMessage.contains('400') || errorMessage.contains('부족');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isShortRecording ? Icons.mic_off_outlined : Icons.error_outline,
            size: 56,
            color: isShortRecording ? Colors.grey[400] : Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            isShortRecording ? '정리할 내용이 부족해요' : '처리 중 오류가 발생했어요',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isShortRecording
                  ? '녹음이 너무 짧거나 음성이 충분하지 않았어요.\n조금 더 길게 녹음하면 자동으로 정리해드릴게요.'
                  : errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => context.go('/'),
                child: const Text('홈으로'),
              ),
              const SizedBox(width: 12),
              if (!isShortRecording) ...[
                OutlinedButton(
                  onPressed: () => ref
                      .read(meetingProcessProvider(widget.meetingId).notifier)
                      .start(),
                  child: const Text('다시 시도'),
                ),
                const SizedBox(width: 12),
              ],
              ElevatedButton(
                onPressed: () => context.go('/agenda'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF378ADD),
                  foregroundColor: Colors.white,
                ),
                child: const Text('다시 녹음'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 완료 결과 화면
  Widget _buildResult() {
    final meetingAsync = ref.watch(meetingDetailProvider(widget.meetingId));

    return meetingAsync.when(
      data: (meeting) => SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF0F6E56),
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Text(
                  '회의록 생성 완료',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${meeting.title} · ${meeting.formattedDate}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            const Text(
              '안건별 정리',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ...meeting.agendaItems.map((item) => _AgendaCard(item: item)),
            const SizedBox(height: 32),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => context.go('/'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('홈으로'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => context.go('/detail/${widget.meetingId}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF378ADD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('상세 보기'),
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

class _AgendaCard extends StatelessWidget {
  final AgendaItem item;
  const _AgendaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      padding: const EdgeInsets.all(20),
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
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          if (item.content != null && item.content!.isNotEmpty)
            _section('내용', text: item.content),
          if (item.discussions.isNotEmpty)
            _section('주요 의견', list: item.discussions),
          if (item.speakerPoints.isNotEmpty)
            _section('발언자별 정리', list: item.speakerPoints),
          if (item.decision != null && item.decision!.isNotEmpty)
            _section('결정', text: item.decision),
          if (item.completedItems.isNotEmpty)
            _section('한 일', list: item.completedItems),
          if (item.actionItems.isNotEmpty)
            _section('할 일', list: item.actionItems),
        ],
      ),
    );
  }

  // 라벨 + 단락 또는 불릿 리스트
  Widget _section(String label, {String? text, List<String>? list}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 4),
          if (text != null)
            Text(text, style: const TextStyle(fontSize: 14, height: 1.5))
          else
            ...list!.map(
              (a) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('• $a', style: const TextStyle(fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }
}
