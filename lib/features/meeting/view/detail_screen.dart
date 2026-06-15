import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/sidebar.dart';
import '../model/meeting_model.dart';
import '../provider/meeting_provider.dart';

class DetailScreen extends ConsumerWidget {
  final int meetingId;
  const DetailScreen({super.key, required this.meetingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingAsync = ref.watch(meetingDetailProvider(meetingId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          const Sidebar(),
          const VerticalDivider(width: 1),
          Expanded(
            child: meetingAsync.when(
              data: (meeting) => SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          meeting.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 56),
                      child: Text(
                        meeting.formattedDate,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...meeting.agendaItems.map((item) => _AgendaCard(item: item)),
                    if (meeting.agendaItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            '정리된 안건이 없습니다',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    _SaveSection(meetingId: meetingId),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaCard extends StatelessWidget {
  final AgendaItem item;
  const _AgendaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 700,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item.order}. ${item.agenda}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (item.decision != null && item.decision!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '결정',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.decision!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF378ADD),
              ),
            ),
          ],
          if (item.actionItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '할 일',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            ...item.actionItems.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_box_outline_blank, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(a, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SaveSection extends ConsumerStatefulWidget {
  final int meetingId;
  const _SaveSection({required this.meetingId});

  @override
  ConsumerState<_SaveSection> createState() => _SaveSectionState();
}

class _SaveSectionState extends ConsumerState<_SaveSection> {
  String? _loadingPlatform;

  Future<dynamic> _ensureSaved(String platform) =>
      ref.read(savePlatformProvider)(widget.meetingId, platform);

  Future<void> _open(String url) async {
    if (!await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('열 수 없습니다')),
        );
      }
    }
  }

  String _resolveUrl(String platform, dynamic result) {
    switch (platform) {
      case 'pdf':
        return ApiConstants.downloadPdf(widget.meetingId);
      case 'markdown':
        return ApiConstants.downloadMarkdown(widget.meetingId);
      case 'docx':
        return ApiConstants.downloadDocx(widget.meetingId);
      case 'notion':
        return (result as Map?)?['notion_url'] ?? '';
      default:
        return '';
    }
  }

  Future<void> _action(String platform, {bool isPreview = false}) async {
    setState(() => _loadingPlatform = platform);
    try {
      final result = await _ensureSaved(platform);
      if (isPreview && platform == 'docx' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Word는 미리보기를 지원하지 않아 다운로드됩니다')),
        );
      }
      final url = _resolveUrl(platform, result);
      if (url.isNotEmpty) await _open(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingPlatform = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 700,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '내보내기',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SaveButton(
                label: '마크다운',
                icon: Icons.description_outlined,
                loading: _loadingPlatform == 'markdown',
                onPreview: () => _action('markdown', isPreview: true),
                onDownload: () => _action('markdown'),
              ),
              _SaveButton(
                label: 'PDF',
                icon: Icons.picture_as_pdf_outlined,
                loading: _loadingPlatform == 'pdf',
                onPreview: () => _action('pdf', isPreview: true),
                onDownload: () => _action('pdf'),
              ),
              _SaveButton(
                label: 'Word',
                icon: Icons.article_outlined,
                loading: _loadingPlatform == 'docx',
                onPreview: () => _action('docx', isPreview: true),
                onDownload: () => _action('docx'),
              ),
              _SaveButton(
                label: '노션',
                icon: Icons.web_outlined,
                loading: _loadingPlatform == 'notion',
                previewLabel: '열기',
                onPreview: () => _action('notion', isPreview: true),
                onDownload: null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onPreview;
  final VoidCallback? onDownload;
  final String previewLabel;

  const _SaveButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onPreview,
    this.onDownload,
    this.previewLabel = '미리보기',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF378ADD)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPreview,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: Text(previewLabel),
                  ),
                ),
                if (onDownload != null) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onDownload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF378ADD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('다운로드'),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
