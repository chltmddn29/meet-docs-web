import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:async';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/web_download.dart';
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

  // 업로드 실패 시 녹음 바이트를 보관 → 네트워크 복구 후 재업로드 가능
  List<int>? _pendingBytes;
  bool _uploadFailed = false;
  // 업로드 실패 시 자동 로컬 저장을 1회만 수행하기 위한 플래그
  bool _savedLocally = false;

  // 네트워크 상태 — 녹음 중 서버 연결이 끊기면 즉시 배너로 알림
  Timer? _netTimer;
  bool _isOnline = true; // 기본은 연결됨 가정
  final _netDio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startRecording();
    _startNetworkWatch();
  }

  // 5초마다 백엔드 health 체크 → 끊기면 _isOnline=false로 배너 표시.
  // 사용자가 아무 동작을 하지 않아도 연결 상태가 화면에 바로 반영됨.
  void _startNetworkWatch() {
    _checkConnection(); // 즉시 1회
    _netTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkConnection(),
    );
  }

  Future<void> _checkConnection() async {
    bool ok;
    try {
      final res = await _netDio.get(
        '/api/health',
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      ok = res.statusCode != null && res.statusCode! < 500;
    } catch (_) {
      ok = false; // 타임아웃·네트워크 오류 = 끊김
    }
    if (mounted && ok != _isOnline) {
      setState(() {
        _isOnline = ok;
        if (_uploadFailed) {
          _statusText = ok
              ? '연결이 복구됐어요 — 자동으로 다시 업로드합니다...'
              : '서버 연결이 끊겼어요 — 복구되면 자동으로 다시 업로드해요';
        }
      });
      // 연결이 막 복구됐고 보관된 녹음이 있으면 자동 재업로드
      if (ok && _uploadFailed && !_isUploading && _pendingBytes != null) {
        _retryUpload();
      }
    }
  }

  // 탭/앱을 다시 열었을 때(브라우저가 백그라운드에서 렌더링·타이머를 멈춤)
  // 경과 시간을 벽시계 기준으로 즉시 재동기화 → 돌아오자마자 정확한 시간 표시
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _isRecording &&
        _startTime != null) {
      setState(() => _elapsed = DateTime.now().difference(_startTime!));
      _checkConnection(); // 돌아오자마자 연결 상태 즉시 갱신
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
    _netTimer?.cancel();
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
      _uploadFailed = false;
      _statusText = '녹음 마무리 중...';
    });

    try {
      // 녹음 바이트가 아직 없으면 한 번만 캡처(_recorder.stop()은 1회만 호출 가능)
      if (_pendingBytes == null) {
        final path = await _recorder.stop();
        if (path == null || path.isEmpty) {
          throw Exception('녹음 경로 없음 (마이크/권한 확인 필요)');
        }

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
        _pendingBytes = bytes; // 보관 → 실패해도 재업로드 가능
      }

      // 오프라인이면 업로드를 시도하지 않고 바로 대기 상태로(90초 멈춤 방지).
      // 네트워크가 돌아오면 health 체크가 자동으로 재업로드함.
      if (!_isOnline) {
        setState(() {
          _isUploading = false;
          _uploadFailed = true;
          _statusText = '서버 연결이 끊겼어요 — 복구되면 자동으로 다시 업로드해요';
        });
        return;
      }

      await _uploadPending();
    } catch (e) {
      _onUploadError(e);
    }
  }

  // 보관된 바이트를 서버에 업로드 (최초 업로드 + 재시도 공용)
  Future<void> _uploadPending() async {
    final bytes = _pendingBytes!;
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
      // 업로드 중 연결이 끊겨도 60초 안에 실패로 끝나도록 제한(무한 대기 방지)
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    // 성공 → 보관본 비우고 result로 이동
    _pendingBytes = null;
    if (mounted) context.go('/result/${widget.meetingId}');
  }

  // 업로드 실패 처리 → 재시도 가능 상태로 전환(녹음 바이트는 보관됨)
  void _onUploadError(Object e) {
    if (!mounted) return;
    // 업로드가 처음 실패하는 순간, 녹음 원본을 즉시 PC에 저장한다.
    // 새로고침·탭 종료로 메모리가 날아가도 파일은 손에 남는다(데이터 유실 방지).
    _saveRecordingLocally(auto: true);
    setState(() {
      _isUploading = false;
      _uploadFailed = true;
      _statusText = _isOnline
          ? '업로드 실패 — 녹음은 PC에 저장됐어요. "다시 업로드"로 재시도하세요'
          : '서버 연결이 끊겼어요 — 녹음은 PC에 저장됐어요. 복구되면 다시 업로드할 수 있어요';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('업로드 실패: $e\n녹음 파일을 PC에 저장했어요 (다시 업로드도 가능).'),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  // 보관된 녹음 바이트를 사용자 PC로 내려받는다.
  // auto=true: 업로드 실패 시 자동 호출(1회만). auto=false: 사용자가 버튼으로 직접 저장.
  void _saveRecordingLocally({bool auto = false}) {
    final bytes = _pendingBytes;
    if (bytes == null || bytes.isEmpty) return;
    if (auto && _savedLocally) return; // 자동 저장은 중복 방지
    _savedLocally = true;
    final ts = DateTime.now();
    final stamp =
        '${ts.year}${ts.month.toString().padLeft(2, '0')}${ts.day.toString().padLeft(2, '0')}'
        '_${ts.hour.toString().padLeft(2, '0')}${ts.minute.toString().padLeft(2, '0')}';
    downloadBytes(
      bytes,
      'meeting_${widget.meetingId}_$stamp.webm',
      mimeType: 'audio/webm',
    );
    if (!auto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('녹음 파일을 PC에 저장했어요')),
      );
    }
  }

  // 재업로드: 네트워크 복구 후 보관된 녹음을 다시 올림
  Future<void> _retryUpload() async {
    if (_pendingBytes == null) return;
    setState(() {
      _isUploading = true;
      _uploadFailed = false;
      _statusText = '다시 업로드 중...';
    });
    try {
      await _uploadPending();
    } catch (e) {
      _onUploadError(e);
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
            child: Column(
              children: [
                // 네트워크 끊김 배너 — 연결이 끊기면 아무 동작 없이 바로 표시됨
                if (!_isOnline)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFA32D2D),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.wifi_off, color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            '서버 연결이 끊겼어요. 녹음은 계속되니 연결이 돌아오면 중지·업로드하세요.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      // 업로드 중: 비활성 / 실패(보관됨): 온라인일 때만 재업로드 /
                      // 녹음 중: 중지. 네트워크가 끊긴 동안엔 실수로 눌러도 재업로드만 막힘.
                      onPressed: _isUploading
                          ? null
                          : _uploadFailed
                          ? (_isOnline ? _retryUpload : null)
                          : (_isRecording ? _stop : null),
                      icon: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _uploadFailed ? Icons.refresh : Icons.stop,
                              size: 20,
                            ),
                      label: Text(
                        _isUploading
                            ? '처리 중'
                            : _uploadFailed
                            ? (_isOnline ? '다시 업로드' : '네트워크 대기 중...')
                            : '중지',
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
                    // 업로드 실패 시: 녹음 원본을 언제든 PC에 다시 저장할 수 있는 버튼
                    if (_uploadFailed && _pendingBytes != null) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => _saveRecordingLocally(),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('녹음 파일 내 PC에 저장'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF378ADD),
                        ),
                      ),
                    ],
                  ],
                ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('오류: $e'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
