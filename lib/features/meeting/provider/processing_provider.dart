import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/error_message.dart';
import 'meeting_provider.dart';

/// 변환 파이프라인 단계.
/// idle=대기, transcribing=음성변환, analyzing=AI정리, saving=저장, done=완료, error=실패
enum ProcessStage { idle, transcribing, analyzing, saving, done, error }

class ProcessState {
  final ProcessStage stage;
  final String? error;
  const ProcessState(this.stage, {this.error});

  // 기존 UI(_step 0~4, -1)와의 호환을 위한 매핑
  int get step {
    switch (stage) {
      case ProcessStage.idle:
        return 0;
      case ProcessStage.transcribing:
        return 1;
      case ProcessStage.analyzing:
        return 2;
      case ProcessStage.saving:
        return 3;
      case ProcessStage.done:
        return 4;
      case ProcessStage.error:
        return -1;
    }
  }
}

/// 회의록 생성 파이프라인을 화면 생명주기와 분리해 실행한다.
/// ResultScreen이 dispose돼도(다른 페이지로 이동) provider가 살아 있어
/// STT→AI정리→저장까지 끝까지 진행된다.
class MeetingProcessNotifier extends FamilyNotifier<ProcessState, int> {
  bool _running = false;

  @override
  ProcessState build(int arg) => const ProcessState(ProcessStage.idle);

  /// 파이프라인 시작. 이미 진행 중이면 무시(중복 호출 방지),
  /// 단 실패 후에는 재시도를 허용한다.
  Future<void> start() async {
    if (_running) return;
    if (state.stage == ProcessStage.done) return;
    _running = true;
    final dio = ref.read(dioProvider);
    final meetingId = arg;
    try {
      // 1. STT — 백그라운드 변환 시작 후 완료까지 폴링
      state = const ProcessState(ProcessStage.transcribing);
      await dio.post(ApiConstants.processAudio(meetingId));
      await _waitForTranscription(dio, meetingId);

      // 2. AI 분석
      state = const ProcessState(ProcessStage.analyzing);
      await dio.post(ApiConstants.analyzeMeeting(meetingId));

      // 3. 마크다운 저장
      state = const ProcessState(ProcessStage.saving);
      await dio.post(ApiConstants.saveMarkdown(meetingId));

      // 4. 완료
      state = const ProcessState(ProcessStage.done);
      ref.invalidate(meetingDetailProvider(meetingId));
    } catch (e) {
      state = ProcessState(ProcessStage.error, error: friendlyError(e));
    } finally {
      _running = false;
    }
  }

  // 백그라운드 변환이 끝날 때까지 /process-status 를 주기적으로 확인(폴링).
  Future<void> _waitForTranscription(Dio dio, int meetingId) async {
    const pollInterval = Duration(seconds: 3);
    final deadline = DateTime.now().add(const Duration(minutes: 30));

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(pollInterval);
      Response res;
      try {
        res = await dio.get(
          ApiConstants.processStatus(meetingId),
          options: Options(validateStatus: (s) => s != null && s < 500),
        );
      } catch (_) {
        // 일시적 네트워크 오류는 무시하고 다음 폴링에서 재시도
        continue;
      }
      final data = res.data;
      final status = (data is Map) ? data['status'] as String? : null;
      if (status == 'completed') return;
      if (status == 'failed') {
        final err = (data is Map ? data['error'] : null) ?? '변환에 실패했습니다';
        throw Exception(err);
      }
      // 'processing'/'idle' → 계속 폴링
    }
    throw Exception('변환이 시간 내에 끝나지 않았습니다. 잠시 후 다시 시도해주세요.');
  }
}

/// meetingId별 변환 진행 상태. autoDispose가 아니므로 화면을 떠나도 유지된다.
final meetingProcessProvider =
    NotifierProvider.family<MeetingProcessNotifier, ProcessState, int>(
      MeetingProcessNotifier.new,
    );
