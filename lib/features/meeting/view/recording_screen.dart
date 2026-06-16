import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:async';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/sidebar.dart';
import '../provider/meeting_provider.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  final int meetingId;
  const RecordingScreen({super.key, required this.meetingId});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen>
    with WidgetsBindingObserver {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isUploading = false;
  DateTime? _startTime;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  String _statusText = '녹음 준비 중...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startRecording();
  }

  // 탭/앱을 다시 열었을 때(브라우저가 백그라운드에서 렌더링·타이머를 멈춤)
  // 경과 시간을 벽시계 기준으로 즉시 재동기화 → 돌아오자마자 정확한 시간 표시
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _isRecording &&
        _startTime != null) {
      setState(() => _elapsed = DateTime.now().difference(_startTime!));
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        await _recorder.start(
          // WAV는 웹에서 Web Audio(AudioContext)로 메인스레드 PCM 캡처 →
          // 백그라운드 탭에서 suspend되어 녹음이 끊김.
          // Opus/WebM은 MediaRecorder 네이티브 파이프라인이라 백그라운드에서도 유지됨.
          const RecordConfig(
            encoder: AudioEncoder.opus,
            sampleRate: 16000, // Whisper 처리 표준(음성인식 최적)
            numChannels: 1, // 모노
            noiseSuppress: true, // 잡음 억제 → 인식률↑
            echoCancel: true, // 에코 제거
            autoGain: true, // 자동 볼륨 보정
          ),
          path: '',
        );
        setState(() {
          _isRecording = true;
          _statusText = '녹음 중...';
        });
        _startTimer();
      } else {
        setState(() => _statusText = '마이크 권한이 거부되었습니다');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('마이크 권한이 필요합니다')));
        }
      }
    } catch (e) {
      setState(() => _statusText = '녹음 시작 실패');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('녹음 시작 실패: $e')));
      }
    }
  }

  void _startTimer() {
    _timer?.cancel(); // 중복 방지
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(_startTime!);
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final total = _elapsed.inSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _stop() async {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _isUploading = true;
      _statusText = '녹음 마무리 중...';
    });

    try {
      // 1. 녹음 중지 → blob URL 반환
      final path = await _recorder.stop();

      if (path == null || path.isEmpty) {
        throw Exception('녹음 경로 없음 (마이크/권한 확인 필요)');
      }

      // 2. blob URL → 바이트 (별도 Dio 인스턴스, 모든 상태 허용)
      setState(() => _statusText = '녹음 파일 읽는 중...');
      final blobDio = Dio();
      final blobResponse = await blobDio.get<List<int>>(
        path,
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (_) => true,
        ),
      );
      final bytes = blobResponse.data ?? [];

      if (bytes.isEmpty) {
        throw Exception('녹음 파일이 비어있음 (0 bytes)');
      }

      // 3. 업로드
      setState(() => _statusText = '업로드 중... (${bytes.length} bytes)');
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: 'meeting_${widget.meetingId}.webm',
          contentType: MediaType('audio', 'webm'),
        ),
      });

      await dio.post(
        ApiConstants.uploadAudio(widget.meetingId),
        data: formData,
      );

      // 4. 성공 → result로 이동
      if (mounted) {
        context.go('/result/${widget.meetingId}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _statusText = '실패: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('실패: $e'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetingAsync = ref.watch(meetingDetailProvider(widget.meetingId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          const Sidebar(),
          const VerticalDivider(width: 1),
          Expanded(
            child: Center(
              child: meetingAsync.when(
                data: (meeting) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      meeting.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusText,
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE6F1FB),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isUploading ? Icons.cloud_upload : Icons.mic,
                        size: 56,
                        color: const Color(0xFF378ADD),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      '⏺ $_formattedTime',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF378ADD),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: 500,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '오늘의 안건',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...meeting.agendaItems.isEmpty
                              ? [
                                  Text(
                                    '안건이 없습니다',
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                ]
                              : meeting.agendaItems
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFE6F1FB),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${entry.key + 1}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF378ADD),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              entry.value.agenda,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: (_isRecording && !_isUploading) ? _stop : null,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.stop, size: 20),
                      label: Text(
                        _isUploading ? '처리 중' : '중지',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA32D2D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('오류: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
