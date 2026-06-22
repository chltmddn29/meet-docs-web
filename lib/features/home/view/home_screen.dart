import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http_parser/http_parser.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/web_file_picker.dart';
import '../../../shared/widgets/sidebar.dart';
import '../../meeting/provider/meeting_provider.dart';
import '../../meeting/model/meeting_model.dart';
import '../../audio/audio_actions.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(meetingsProvider);
    final audioFilesAsync = ref.watch(audioFilesProvider);

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
                  // 헤더
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '홈',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '최근 회의 및 음성 기록',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 음성 파일 업로드 (기존 녹음 파일을 직접 올려 변환)
                  const _AudioUploadCard(),

                  const SizedBox(height: 32),

                  // 2열 그리드
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 최근 회의록
                      Expanded(
                        child: _SectionCard(
                          title: '최근 회의록',
                          icon: Icons.list_alt_outlined,
                          onMoreTap: () => context.go('/history'),
                          child: meetingsAsync.when(
                            data: (meetings) => meetings.isEmpty
                                ? const _EmptyState(message: '아직 회의록이 없어요')
                                : Column(
                                    children: meetings
                                        .take(3)
                                        .map((m) => _MeetingItem(meeting: m))
                                        .toList(),
                                  ),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) =>
                                _EmptyState(message: '불러오기 실패: $e'),
                          ),
                        ),
                      ),

                      const SizedBox(width: 32),

                      // 최근 음성 기록
                      Expanded(
                        child: _SectionCard(
                          title: '최근 음성 기록',
                          icon: Icons.mic_outlined,
                          iconColor: const Color(0xFFD85A30),
                          onMoreTap: () => context.go('/audio'),
                          child: audioFilesAsync.when(
                            data: (files) => files.isEmpty
                                ? const _EmptyState(message: '아직 음성 기록이 없어요')
                                : Column(
                                    children: files
                                        .take(3)
                                        .map((f) => _AudioItem(audio: f))
                                        .toList(),
                                  ),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) =>
                                _EmptyState(message: '불러오기 실패: $e'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 기존 음성 파일을 골라 업로드 → 회의 생성 → 변환 화면으로 이동.
// 녹음이 어려운 경우나, 업로드 실패 시 PC에 자동 저장된 녹음을 다시 올릴 때 사용.
class _AudioUploadCard extends ConsumerStatefulWidget {
  const _AudioUploadCard();

  @override
  ConsumerState<_AudioUploadCard> createState() => _AudioUploadCardState();
}

class _AudioUploadCardState extends ConsumerState<_AudioUploadCard> {
  bool _busy = false;
  String _status = '';

  Future<void> _pickAndUpload() async {
    if (_busy) return;
    final picked = await pickFile(
      ['webm', 'm4a', 'mp3', 'wav', 'ogg', 'opus', 'aac', 'mp4'],
    );
    if (picked == null || picked.bytes.isEmpty) return; // 취소/빈 파일
    setState(() {
      _busy = true;
      _status = '회의 생성 중...';
    });
    try {
      final dio = ref.read(dioProvider);
      // 1) 회의 생성 (제목 = 파일명에서 확장자 제거)
      final create = ref.read(createMeetingProvider);
      final base = picked.name.replaceAll(RegExp(r'\.[^.]+$'), '').trim();
      final meeting = await create(
        base.isEmpty ? '업로드된 음성' : base,
        <String>[],
        <String>[],
      );

      // 2) 업로드
      final mb = (picked.bytes.length / 1024 / 1024).toStringAsFixed(1);
      setState(() => _status = '업로드 중... (${mb}MB)');
      final ext = picked.name.contains('.')
          ? picked.name.split('.').last.toLowerCase()
          : 'webm';
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          picked.bytes,
          filename: picked.name,
          contentType: MediaType('audio', ext),
        ),
      });
      await dio.post(
        ApiConstants.uploadAudio(meeting.meetingId),
        data: formData,
        options: Options(
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );

      // 3) 목록 갱신 + 변환 화면으로 이동 (STT→분석→저장 자동 진행)
      ref.invalidate(audioFilesProvider);
      ref.invalidate(meetingsProvider);
      if (mounted) context.go('/result/${meeting.meetingId}');
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = '';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('업로드 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFE6F1FB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.upload_file_outlined,
              color: Color(0xFF378ADD),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '음성 파일 업로드',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  _busy
                      ? _status
                      : '녹음 파일(webm·m4a·mp3·wav 등)을 올려 회의록으로 변환합니다',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _busy ? null : _pickAndUpload,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.folder_open, size: 18),
            label: Text(_busy ? '처리 중' : '파일 선택'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF378ADD),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onMoreTap;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    this.iconColor,
    required this.onMoreTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: iconColor ?? Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            TextButton(onPressed: onMoreTap, child: const Text('더보기 →')),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _MeetingItem extends StatelessWidget {
  final Meeting meeting;

  const _MeetingItem({required this.meeting});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => context.push('/detail/${meeting.meetingId}'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meeting.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${meeting.createdAt.month}월 ${meeting.createdAt.day}일',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5EE),
                borderRadius: BorderRadius.circular(4),
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
          ],
        ),
      ),
    );
  }
}

class _AudioItem extends ConsumerWidget {
  final AudioFile audio;

  const _AudioItem({required this.audio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            audio.filename,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => playAudio(context, audio.transcriptId),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('재생'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF378ADD),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => downloadAudio(context, audio.transcriptId),
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: const Text('다운로드'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF378ADD),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => regenerateMinutes(context, audio.meetingId),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('회의록 다시 생성'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F6E56),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => deleteAudio(context, ref, audio.transcriptId),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('삭제'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFA32D2D),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(color: Colors.grey[500], fontSize: 14),
      ),
    );
  }
}
