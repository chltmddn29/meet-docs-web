import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/sidebar.dart';
import '../../../shared/widgets/async_views.dart';
import '../../../core/network/error_message.dart';
import '../../meeting/provider/meeting_provider.dart';

// 회의 삭제: 확인 → 삭제 → 목록 갱신
Future<void> _confirmDeleteMeeting(
  BuildContext context,
  WidgetRef ref,
  int meetingId,
  String title,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('회의 삭제'),
      content: Text('"$title" 회의를 삭제할까요?\n안건·음성·문서가 모두 삭제되며 되돌릴 수 없어요.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFA32D2D)),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
  if (ok != true) return;

  try {
    await ref.read(deleteMeetingProvider)(meetingId);
    ref.invalidate(meetingsProvider);
    ref.invalidate(audioFilesProvider);
    ref.invalidate(todosProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('회의를 삭제했어요')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제 실패: ${friendlyError(e)}')));
    }
  }
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(meetingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          const Sidebar(),
          const VerticalDivider(width: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '회의록 히스토리',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '지금까지의 모든 회의',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  meetingsAsync.when(
                    data: (meetings) => meetings.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                '회의록이 없습니다',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: [
                                // 헤더
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          '회의명',
                                          style: _headerStyle(),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '날짜',
                                          style: _headerStyle(),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          '상태',
                                          style: _headerStyle(),
                                        ),
                                      ),
                                      const SizedBox(width: 40),
                                    ],
                                  ),
                                ),
                                // 행들
                                ...meetings.map(
                                  (m) => InkWell(
                                    onTap: () =>
                                        context.go('/detail/${m.meetingId}'),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: Colors.grey[200]!,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              m.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              m.formattedDate,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFE1F5EE,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  '완료',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF0F6E56),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // 삭제 버튼
                                          SizedBox(
                                            width: 40,
                                            child: IconButton(
                                              onPressed: () =>
                                                  _confirmDeleteMeeting(
                                                    context,
                                                    ref,
                                                    m.meetingId,
                                                    m.title,
                                                  ),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                              ),
                                              color: const Color(0xFFA32D2D),
                                              tooltip: '삭제',
                                              splashRadius: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(40),
                      child: LoadingView(),
                    ),
                    error: (e, _) => ErrorRetryView(
                      error: e,
                      onRetry: () => ref.invalidate(meetingsProvider),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Colors.grey[600],
  );
}
