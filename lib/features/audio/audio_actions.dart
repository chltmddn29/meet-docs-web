import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';
import '../meeting/provider/meeting_provider.dart';

// 새 탭으로 URL 열기 (재생·다운로드 공용). 실패/예외를 스낵바로 안내.
Future<void> _openUrl(BuildContext context, String url, String failMsg) async {
  try {
    final ok = await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failMsg)));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$failMsg ($e)')));
    }
  }
}

// 음성 재생: 새 탭에서 파일 URL을 열어 브라우저 기본 플레이어로 재생
Future<void> playAudio(BuildContext context, int transcriptId) =>
    _openUrl(context, ApiConstants.downloadAudioFile(transcriptId), '재생할 수 없습니다');

// 음성 다운로드: attachment URL을 열어 파일로 저장
Future<void> downloadAudio(BuildContext context, int transcriptId) => _openUrl(
  context,
  ApiConstants.downloadAudioFileAttachment(transcriptId),
  '다운로드할 수 없습니다',
);

// 저장된 오디오로 회의록 다시 생성: result 화면으로 이동(STT→분석→저장 재실행)
void regenerateMinutes(BuildContext context, int meetingId) {
  context.go('/result/$meetingId');
}

// 음성 삭제: 확인 → 삭제 → 목록 갱신
Future<void> deleteAudio(
  BuildContext context,
  WidgetRef ref,
  int transcriptId,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('음성 파일 삭제'),
      content: const Text('이 음성 파일을 삭제할까요?'),
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
    await ref.read(dioProvider).delete(ApiConstants.deleteAudio(transcriptId));
    ref.invalidate(audioFilesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('음성 파일을 삭제했어요')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }
}
