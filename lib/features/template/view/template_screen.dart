import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/web_file_picker.dart';
import '../../../shared/widgets/sidebar.dart';
import '../model/template_model.dart';
import '../provider/template_provider.dart';
import '../model/format_template_model.dart';
import '../provider/format_template_provider.dart';

const _primary = Color(0xFF378ADD);

class TemplateScreen extends ConsumerWidget {
  const TemplateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);
    final formatTemplatesAsync = ref.watch(formatTemplatesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          const Sidebar(),
          const VerticalDivider(width: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 페이지 헤더
                  const Text(
                    '회의 템플릿',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '안건 템플릿으로 회의를 빠르게 시작하고, 서식 템플릿으로 회의록 형식을 지정하세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),

                  // 섹션 1 — 안건 템플릿
                  _SectionHeader(
                    title: '안건 템플릿',
                    subtitle: '회의 시작 시 안건·참석자를 미리 채워줍니다',
                    buttonIcon: Icons.add,
                    buttonLabel: '새 안건 템플릿',
                    onPressed: () => _openForm(context, ref),
                  ),
                  const SizedBox(height: 16),
                  templatesAsync.when(
                    data: (templates) => templates.isEmpty
                        ? _EmptyState(onCreate: () => _openForm(context, ref))
                        : Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            children: templates
                                .map((t) => _TemplateCard(template: t))
                                .toList(),
                          ),
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        '불러오기 실패: $e',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // 섹션 2 — 서식 템플릿
                  _SectionHeader(
                    title: '서식 템플릿',
                    subtitle: '회의록 샘플(docx·hwp·hwpx·md·txt)을 올리면 AI가 그 형식대로 생성합니다',
                    buttonIcon: Icons.upload_file,
                    buttonLabel: '파일 업로드',
                    onPressed: () => _uploadFormat(context, ref),
                  ),
                  const SizedBox(height: 16),
                  formatTemplatesAsync.when(
                    data: (items) => items.isEmpty
                        ? _FormatEmptyState(
                            onUpload: () => _uploadFormat(context, ref),
                          )
                        : Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            children: items
                                .map((t) => _FormatTemplateCard(template: t))
                                .toList(),
                          ),
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        '불러오기 실패: $e',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => const TemplateFormDialog(),
    );
  }

  // 파일 선택 → 업로드 → 서식 템플릿 생성
  Future<void> _uploadFormat(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await pickFile(['docx', 'hwp', 'hwpx', 'md', 'txt']);
    if (picked == null) return; // 취소 또는 읽기 실패

    messenger.showSnackBar(
      const SnackBar(content: Text('업로드 중...')),
    );
    try {
      await ref.read(uploadFormatTemplateProvider)(picked.bytes, picked.name);
      ref.invalidate(formatTemplatesProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('서식 템플릿을 추가했어요')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('업로드 실패: $e')));
    }
  }
}

// ---------------------------------------------------------------------------
// 섹션 헤더 (제목 + 설명 + 액션 버튼)
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData buttonIcon;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.buttonIcon,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(buttonIcon, size: 18),
          label: Text(buttonLabel),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 안건 템플릿 카드
// ---------------------------------------------------------------------------
class _TemplateCard extends ConsumerWidget {
  final Template template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 + 삭제
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  template.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _confirmDelete(context, ref),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),

          if (template.description != null &&
              template.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              template.description!,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],

          const SizedBox(height: 16),

          // 안건 개수 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F1FB),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '안건 ${template.agendaItems.length}개',
              style: const TextStyle(
                fontSize: 11,
                color: _primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 안건 목록 (최대 4개 미리보기)
          ...template.agendaItems.take(4).map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 8),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          a,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (template.agendaItems.length > 4)
            Text(
              '외 ${template.agendaItems.length - 4}개',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),

          // 참석자
          if (template.participantList.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.people_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    template.participantList.join(', '),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // 이 템플릿으로 시작
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.go('/agenda?template=${template.templateId}'),
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('이 템플릿으로 시작'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('템플릿 삭제'),
        content: Text("'${template.name}' 템플릿을 삭제할까요?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFA32D2D),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await ref.read(deleteTemplateProvider)(template.templateId);
      ref.invalidate(templatesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('템플릿을 삭제했어요')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
      }
    }
  }
}

// ---------------------------------------------------------------------------
// 서식 템플릿 카드
// ---------------------------------------------------------------------------
class _FormatTemplateCard extends ConsumerWidget {
  final FormatTemplate template;

  const _FormatTemplateCard({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1, right: 8),
                child: Icon(
                  Icons.description_outlined,
                  size: 18,
                  color: _primary,
                ),
              ),
              Expanded(
                child: Text(
                  template.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => _confirmDelete(context, ref),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
          if (template.sourceFilename != null &&
              template.sourceFilename!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              template.sourceFilename!,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              template.content.isEmpty ? '(미리보기 없음)' : template.content,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 13, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '회의 상세에서 "서식 적용 생성"으로 사용',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('서식 템플릿 삭제'),
        content: Text("'${template.name}' 서식을 삭제할까요?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFA32D2D),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await ref.read(deleteFormatTemplateProvider)(template.formatTemplateId);
      ref.invalidate(formatTemplatesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서식 템플릿을 삭제했어요')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
      }
    }
  }
}

// ---------------------------------------------------------------------------
// 빈 상태 — 안건 템플릿
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.dashboard_customize_outlined,
              size: 44, color: Colors.grey[300]),
          const SizedBox(height: 14),
          Text(
            '아직 저장된 안건 템플릿이 없어요',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            '자주 쓰는 안건 구성을 템플릿으로 만들어보세요',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('새 안건 템플릿'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _primary),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 빈 상태 — 서식 템플릿
// ---------------------------------------------------------------------------
class _FormatEmptyState extends StatelessWidget {
  final VoidCallback onUpload;

  const _FormatEmptyState({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.upload_file, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            '서식 샘플을 올려보세요',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'docx · hwp · hwpx · md · txt 회의록 예시를 올리면 AI가 그 형식대로 만들어줍니다',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '💡 양식에 {{제목}} {{날짜}} {{참석자}} {{안건}} {{결정}} {{할일}} {{한일}} 같은 '
              '칸을 넣으면, 그 자리에 회의 값이 정확히 채워집니다.',
              style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.upload_file, size: 16),
            label: const Text('파일 업로드'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _primary),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 안건 템플릿 생성 다이얼로그
// ---------------------------------------------------------------------------
class TemplateFormDialog extends ConsumerStatefulWidget {
  const TemplateFormDialog({super.key});

  @override
  ConsumerState<TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends ConsumerState<TemplateFormDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _participantController = TextEditingController();
  final List<TextEditingController> _agendaControllers = [
    TextEditingController(),
  ];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _participantController.dispose();
    for (final c in _agendaControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addAgenda() {
    setState(() => _agendaControllers.add(TextEditingController()));
  }

  void _removeAgenda(int index) {
    setState(() {
      _agendaControllers[index].dispose();
      _agendaControllers.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('템플릿 이름을 입력해주세요')));
      return;
    }

    final agendas = _agendaControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (agendas.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('안건을 최소 1개 입력해주세요')));
      return;
    }

    final participants = _participantController.text
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    setState(() => _isSaving = true);

    try {
      await ref.read(createTemplateProvider)(
        _nameController.text.trim(),
        _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        agendas,
        participants,
      );
      ref.invalidate(templatesProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('템플릿을 저장했어요')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  OutlineInputBorder get _border => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '새 안건 템플릿',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('템플릿 이름'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: '예) 주간 스프린트 회의',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: _border,
                          enabledBorder: _border,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _label('설명', optional: true),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          hintText: '템플릿 용도를 간단히 적어주세요',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                          border: _border,
                          enabledBorder: _border,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _label('참석자', optional: true),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _participantController,
                        decoration: InputDecoration(
                          hintText: '쉼표로 구분 (예: 홍길동, 김철수)',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                          border: _border,
                          enabledBorder: _border,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _label('안건'),
                      const SizedBox(height: 12),
                      ..._agendaControllers.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final controller = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    hintText: '안건 입력',
                                    hintStyle:
                                        TextStyle(color: Colors.grey[400]),
                                    border: _border,
                                    enabledBorder: _border,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_agendaControllers.length > 1)
                                IconButton(
                                  onPressed: () => _removeAgenda(idx),
                                  icon: const Icon(Icons.close),
                                  color: Colors.red[300],
                                ),
                            ],
                          ),
                        );
                      }),
                      OutlinedButton.icon(
                        onPressed: _addAgenda,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('안건 추가'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: const BorderSide(color: _primary),
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('저장'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, {bool optional = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          Text(
            '(선택)',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ],
    );
  }
}
