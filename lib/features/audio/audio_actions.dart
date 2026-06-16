import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';
import '../meeting/provider/meeting_provider.dart';

// 음성 재생: 새 탭에서 파일 URL을 열어 브라우저 기본 플레이어로 재생
Future<void> playAudio(BuildContext context, int transcriptId) async {
  final url = ApiConstants.downloadAudioFile(transcriptId);
  final ok = await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('재생할 수 없습니다')));
  }
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
