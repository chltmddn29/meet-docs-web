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
        fontFamily: 'Pretendard',
      ),
      routerConfig: appRouter,
    );
  }
}
