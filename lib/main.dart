import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: MeetDocsApp()));
}

class MeetDocsApp extends StatelessWidget {
  const MeetDocsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MeetDocs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF378ADD)),
        useMaterial3: true,
        // 번들된 한글 폰트 사용 (Pretendard는 미번들이라 한글 깨짐 발생했음)
        fontFamily: 'NanumGothic',
      ),
      routerConfig: appRouter,
    );
  }
}
