import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/sidebar.dart';
import '../model/meeting_model.dart';
import '../provider/meeting_provider.dart';
import '../../template/model/format_template_model.dart';
import '../../template/provider/format_template_provider.dart';

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
                    if (meeting.participants != null &&
                        meeting.participants!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 56, top: 4),
                        child: Text(
                          '참석자: ${meeting.participants}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 56),
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/transcript/$meetingId'),
                        icon: const Icon(Icons.article_outlined, size: 16),
                        label: const Text('음성 원본 보기'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF378ADD),
                          side: const BorderSide(color: Color(0xFF378ADD)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...meeting.agendaItems.map(
                      (item) => _AgendaCard(item: item),
                    ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('열 수 없습니다')));
      }
    }
  }

  // 미리보기: 회의록 내용을 모달에 렌더링
  Future<void> _preview() async {
    setState(() => _loadingPlatform = '_preview');
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        '/api/meetings/${widget.meetingId}/preview',
      );
      final markdown = response.data['markdown'] as String? ?? '';

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => Dialog(
          child: Container(
            width: 600,
            constraints: const BoxConstraints(maxHeight: 700),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '미리보기',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                Flexible(child: Markdown(data: markdown, shrinkWrap: true)),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('미리보기 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingPlatform = null);
    }
  }

  // 서식 적용 생성: 서식 템플릿 선택 → AI가 그 형식대로 회의록 생성 → 미리보기
  Future<void> _generateWithFormat() async {
    final List<FormatTemplate> templates;
    try {
      templates = await ref.read(formatTemplatesProvider.future);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('서식 목록 로드 실패: $e')));
      }
      return;
    }
    if (!mounted) return;

    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('먼저 "회의 템플릿 > 서식 템플릿"에서 파일을 올려주세요'),
        ),
      );
      return;
    }

    final selected = await showDialog<FormatTemplate>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('서식 선택'),
        children: templates
            .map(
              (t) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, t),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 18,
                        color: Color(0xFF378ADD),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t.name)),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null || !mounted) return;

    setState(() => _loadingPlatform = '_format');
    try {
      final markdown = await ref.read(generateFormattedProvider)(
        widget.meetingId,
        selected.formatTemplateId,
      );
      if (!mounted) return;
      if (markdown.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('생성된 내용이 비어있어요')),
        );
        return;
      }
      _showMarkdownDialog('${selected.name} 서식', markdown);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('생성 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingPlatform = null);
    }
  }

  // 마크다운을 모달로 렌더링 (복사 버튼 포함)
  void _showMarkdownDialog(String title, String markdown) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          width: 640,
          constraints: const BoxConstraints(maxHeight: 720),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: markdown));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('복사했어요')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('복사'),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Flexible(child: Markdown(data: markdown, shrinkWrap: true)),
            ],
          ),
        ),
      ),
    );
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

  // 다운로드: 파일 생성 후 받기 (노션은 열기)
  Future<void> _download(String platform) async {
    setState(() => _loadingPlatform = platform);
    try {
      final result = await _ensureSaved(platform);
      final url = _resolveUrl(platform, result);
      if (url.isNotEmpty) await _open(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('실패: $e')));
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
          // 미리보기 버튼 (공통, 하나)
          OutlinedButton.icon(
            onPressed: _loadingPlatform == '_preview' ? null : _preview,
            icon: _loadingPlatform == '_preview'
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('미리보기'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF378ADD),
              side: const BorderSide(color: Color(0xFF378ADD)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          // 서식 적용 생성 — 업로드한 서식 템플릿 형식대로 AI가 회의록 재생성
          OutlinedButton.icon(
            onPressed: _loadingPlatform == '_format' ? null : _generateWithFormat,
            icon: _loadingPlatform == '_format'
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome, size: 18),
            label: const Text('서식 적용 생성'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF378ADD),
              side: const BorderSide(color: Color(0xFF378ADD)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '다운로드',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _DownloadButton(
                label: '마크다운',
                icon: Icons.description_outlined,
                loading: _loadingPlatform == 'markdown',
                onTap: () => _download('markdown'),
              ),
              _DownloadButton(
                label: 'PDF',
                icon: Icons.picture_as_pdf_outlined,
                loading: _loadingPlatform == 'pdf',
                onTap: () => _download('pdf'),
              ),
              _DownloadButton(
                label: 'Word',
                icon: Icons.article_outlined,
                loading: _loadingPlatform == 'docx',
                onTap: () => _download('docx'),
              ),
              _DownloadButton(
                label: '노션',
                icon: Icons.web_outlined,
                loading: _loadingPlatform == 'notion',
                buttonText: '열기',
                onTap: () => _download('notion'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;
  final String buttonText;

  const _DownloadButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onTap,
    this.buttonText = '다운로드',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF378ADD),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '$label $buttonText',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}
