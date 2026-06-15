import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/sidebar.dart';
import '../provider/meeting_provider.dart';
import '../model/meeting_model.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final int meetingId;
  const ResultScreen({super.key, required this.meetingId});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  // 0=대기, 1=STT, 2=AI분석, 3=마크다운저장, 4=완료, -1=에러
  int _step = 0;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    final dio = ref.read(dioProvider);
    try {
      // 1. STT 처리
      setState(() => _step = 1);
      await dio.post(ApiConstants.processAudio(widget.meetingId));

      // 2. AI 분석
      setState(() => _step = 2);
      await dio.post(ApiConstants.analyzeMeeting(widget.meetingId));

      // 3. 마크다운 저장
      setState(() => _step = 3);
      await dio.post(ApiConstants.saveMarkdown(widget.meetingId));

      // 4. 완료
      setState(() => _step = 4);
      ref.invalidate(meetingDetailProvider(widget.meetingId));
    } catch (e) {
      String msg = e.toString();
      if (e is DioException) {
        final code = e.response?.statusCode;
        if (code == 400) {
          msg = '400 분석할 내용이 부족합니다';
        } else {
          msg = e.response?.data?.toString() ?? e.message ?? msg;
        }
      }
      setState(() {
        _step = -1;
        _errorMessage = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          const Sidebar(),
          const VerticalDivider(width: 1),
          Expanded(
            child: _step == 4
                ? _buildResult()
                : _step == -1
                ? _buildError()
                : _buildProcessing(),
          ),
        ],
      ),
    );
  }

  // 처리 중 화면
  Widget _buildProcessing() {
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
                final isDone = _step > stepNum;
                final isCurrent =
                    _step == stepNum + 1 || (_step == 1 && stepNum == 0);
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
  Widget _buildError() {
    final isShortRecording =
        _errorMessage.contains('400') || _errorMessage.contains('부족');

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
                  : _errorMessage,
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
          if (item.decision != null && item.decision!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('결정', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 4),
            Text(item.decision!, style: const TextStyle(fontSize: 14)),
          ],
          if (item.actionItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '할 일',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 4),
            ...item.actionItems.map(
              (a) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('• $a', style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
