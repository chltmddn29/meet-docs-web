import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/sidebar.dart';
import '../provider/meeting_provider.dart';
import '../../template/model/template_model.dart';
import '../../template/provider/template_provider.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  final int? templateId;

  const AgendaScreen({super.key, this.templateId});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  final _titleController = TextEditingController();
  final _participantController = TextEditingController();
  final List<TextEditingController> _agendaControllers = [
    TextEditingController(),
  ];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 템플릿으로 시작한 경우 자동으로 불러오기
    if (widget.templateId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadTemplate(widget.templateId!),
      );
    }
  }

  Future<void> _loadTemplate(int id) async {
    try {
      final t = await ref.read(templateDetailProvider(id).future);
      if (mounted) _applyTemplate(t);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('템플릿 불러오기 실패: $e')));
      }
    }
  }

  Future<void> _pickTemplate() async {
    final selected = await showDialog<Template>(
      context: context,
      builder: (_) => const _TemplatePickerDialog(),
    );
    if (selected != null) _applyTemplate(selected);
  }

  // 템플릿 내용을 입력 폼에 채워넣기
  void _applyTemplate(Template t) {
    if (!mounted) return;
    setState(() {
      _titleController.text = t.name;
      _participantController.text = t.participantList.join(', ');
      for (final c in _agendaControllers) {
        c.dispose();
      }
      _agendaControllers
        ..clear()
        ..addAll(
          t.agendaItems.isEmpty
              ? [TextEditingController()]
              : t.agendaItems.map((a) => TextEditingController(text: a)),
        );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("'${t.name}' 템플릿을 불러왔어요")),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _participantController.dispose();
    for (final c in _agendaControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addAgenda() {
    setState(() {
      _agendaControllers.add(TextEditingController());
    });
  }

  void _removeAgenda(int index) {
    setState(() {
      _agendaControllers[index].dispose();
      _agendaControllers.removeAt(index);
    });
  }

  Future<void> _next() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('회의 제목을 입력해주세요')));
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

    // 참석자: 쉼표로 구분된 문자열 → 리스트
    final participants = _participantController.text
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    setState(() => _isLoading = true);

    try {
      final createMeeting = ref.read(createMeetingProvider);
      final meeting = await createMeeting(
        _titleController.text,
        agendas,
        participants,
      );
      if (mounted) {
        context.go('/recording/${meeting.meetingId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          const Sidebar(),
          const VerticalDivider(width: 1),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '새 회의 시작',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '회의 정보를 입력하고 음성 녹음을 시작하세요',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: 600,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 템플릿 불러오기
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _pickTemplate,
                              icon: const Icon(
                                Icons.dashboard_customize_outlined,
                                size: 16,
                              ),
                              label: const Text('템플릿 불러오기'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF378ADD),
                                side: BorderSide(color: Colors.grey[300]!),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 20),

                          // 회의 제목
                          const Text(
                            '회의 제목',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: '예) 기술 스택 결정',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 참석자 (선택)
                          Row(
                            children: [
                              const Text(
                                '참석자',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(선택)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _participantController,
                            decoration: InputDecoration(
                              hintText: '쉼표로 구분하여 입력 (예: 홍길동, 김철수)',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 안건
                          const Text(
                            '안건',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
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
                              foregroundColor: const Color(0xFF378ADD),
                              side: const BorderSide(color: Color(0xFF378ADD)),
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // 버튼
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => context.go('/'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
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
                                  onPressed: _isLoading ? null : _next,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF378ADD),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('다음'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 새 회의 시작 시 저장된 템플릿을 골라 불러오는 다이얼로그
class _TemplatePickerDialog extends ConsumerWidget {
  const _TemplatePickerDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '템플릿 불러오기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: templatesAsync.when(
                  data: (templates) => templates.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              '저장된 템플릿이 없어요',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: templates.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final t = templates[i];
                            return InkWell(
                              onTap: () => Navigator.pop(context, t),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey[200]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '안건 ${t.agendaItems.length}개',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('불러오기 실패: $e')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
