import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Container(
      width: 240,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 로고
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MeetDocs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF378ADD),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '음성 회의록 자동화',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          // 새 회의 시작 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/agenda'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('새 회의 시작'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF378ADD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 네비게이션 메뉴
          _NavItem(
            icon: Icons.home_outlined,
            label: '홈',
            path: '/',
            isActive: currentPath == '/',
          ),
          _NavItem(
            icon: Icons.list_alt_outlined,
            label: '회의록 히스토리',
            path: '/history',
            isActive: currentPath == '/history',
          ),
          _NavItem(
            icon: Icons.mic_outlined,
            label: '음성 기록',
            path: '/audio',
            isActive: currentPath == '/audio',
          ),

          const Spacer(),

          // 저장소 사용량
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  '저장소 사용량',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.35,
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF378ADD),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '3.5GB / 10GB',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color: isActive ? const Color(0xFF378ADD) : Colors.grey[600],
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isActive ? const Color(0xFF378ADD) : Colors.grey[700],
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        tileColor: isActive ? const Color(0xFFE6F1FB) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => context.go(path),
      ),
    );
  }
}
