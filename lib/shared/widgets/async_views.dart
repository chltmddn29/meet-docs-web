import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/network/error_message.dart';

/// 로딩 표시 — 일정 시간 지나면 "서버 깨우는 중" 안내를 띄운다.
/// Render 무료 서버는 첫 요청(콜드스타트)이 최대 1분 걸려, 그냥 스피너만
/// 보이면 멈춘 줄 오해하기 쉬움.
class LoadingView extends StatefulWidget {
  final String? message;
  const LoadingView({super.key, this.message});

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView> {
  bool _slow = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 4초 넘게 걸리면 콜드스타트 안내 노출
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(color: Color(0xFF378ADD)),
          ),
          const SizedBox(height: 20),
          Text(
            widget.message ?? '불러오는 중...',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          if (_slow) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: 300,
              child: Text(
                '서버를 깨우는 중이에요. 처음엔 최대 1분까지 걸릴 수 있어요 🙏',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[400], height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 에러 표시 + 다시 시도 버튼.
class ErrorRetryView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorRetryView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              friendlyError(error),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.6),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF378ADD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
