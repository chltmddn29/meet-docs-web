import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/view/home_screen.dart';
import '../../features/meeting/view/agenda_screen.dart';
import '../../features/meeting/view/recording_screen.dart';
import '../../features/meeting/view/result_screen.dart';
import '../../features/meeting/view/detail_screen.dart';
import '../../features/history/view/history_screen.dart';
import '../../features/audio/view/audio_screen.dart';
import '../../features/meeting/view/transcript_screen.dart';

// 애니메이션 없는 페이지 헬퍼
CustomTransitionPage _noTransition(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        child,
  );
}

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _noTransition(const HomeScreen()),
    ),
    GoRoute(
      path: '/agenda',
      pageBuilder: (context, state) => _noTransition(const AgendaScreen()),
    ),
    GoRoute(
      path: '/recording/:meetingId',
      pageBuilder: (context, state) => _noTransition(
        RecordingScreen(
          meetingId: int.parse(state.pathParameters['meetingId']!),
        ),
      ),
    ),
    GoRoute(
      path: '/result/:meetingId',
      pageBuilder: (context, state) => _noTransition(
        ResultScreen(meetingId: int.parse(state.pathParameters['meetingId']!)),
      ),
    ),
    GoRoute(
      path: '/detail/:meetingId',
      pageBuilder: (context, state) => _noTransition(
        DetailScreen(meetingId: int.parse(state.pathParameters['meetingId']!)),
      ),
    ),
    GoRoute(
      path: '/history',
      pageBuilder: (context, state) => _noTransition(const HistoryScreen()),
    ),
    GoRoute(
      path: '/audio',
      pageBuilder: (context, state) => _noTransition(const AudioScreen()),
    ),
    GoRoute(
      path: '/transcript/:meetingId',
      pageBuilder: (context, state) => _noTransition(
        TranscriptScreen(
          meetingId: int.parse(state.pathParameters['meetingId']!),
        ),
      ),
    ),
  ],
);
