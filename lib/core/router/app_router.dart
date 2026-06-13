import 'package:go_router/go_router.dart';
import '../../features/home/view/home_screen.dart';
import '../../features/meeting/view/agenda_screen.dart';
import '../../features/meeting/view/recording_screen.dart';
import '../../features/meeting/view/result_screen.dart';
import '../../features/meeting/view/detail_screen.dart';
import '../../features/history/view/history_screen.dart';
import '../../features/audio/view/audio_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/agenda', builder: (context, state) => const AgendaScreen()),
    GoRoute(
      path: '/recording/:meetingId',
      builder: (context, state) => RecordingScreen(
        meetingId: int.parse(state.pathParameters['meetingId']!),
      ),
    ),
    GoRoute(
      path: '/result/:meetingId',
      builder: (context, state) => ResultScreen(
        meetingId: int.parse(state.pathParameters['meetingId']!),
      ),
    ),
    GoRoute(
      path: '/detail/:meetingId',
      builder: (context, state) => DetailScreen(
        meetingId: int.parse(state.pathParameters['meetingId']!),
      ),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(path: '/audio', builder: (context, state) => const AudioScreen()),
  ],
);
