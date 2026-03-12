import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:flutter/material.dart';

import 'package:aiwa_app/services/notes/note_service.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/ui/widgets/aiwa_block_editor.dart';

/// Full-page editor for a single note entry.
///
/// Route args (Map<String, dynamic>):
///   • 'note' (NoteEntry?) – existing note to edit; null → create new
///   • 'noteService' (NoteService) – the service to save to
///
/// Pops with NoteEntry? on save (null means cancelled/no-op).
class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({super.key});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _titleCtrl;
  late List<BlockDTO> _blocks;
  bool _argsLoaded = false;
  NoteEntry? _existing;
  NoteService? _service;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _blocks = const [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    _argsLoaded = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final note = args['note'];
      if (note is NoteEntry) {
        _existing = note;
        _titleCtrl.text = note.title;
        _blocks = note.blocks;
      }
      final svc = args['noteService'];
      if (svc is NoteService) {
        _service = svc;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final now = DateTime.now().toUtc();
    final title = _titleCtrl.text.trim();
    final blocksJson = NoteEntry.encodeBlocks(_blocks);

    final entry = _existing != null
        ? NoteEntry(
            id: _existing!.id,
            title: title,
            blocksJson: blocksJson,
            createdAt: _existing!.createdAt,
            updatedAt: now,
          )
        : NoteEntry(
            id: NoteService.generateId(),
            title: title,
            blocksJson: blocksJson,
            createdAt: now,
            updatedAt: now,
          );

    await _service?.save(entry);
    if (mounted) Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // ── title field ──────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                      child: _buildTitleField(),
                    ),
                  ),
                  // ── note label ───────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                      child: Text(
                        '内容',
                        style: AppTypography.bodyBold
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  // ── AiwaBlockEditor fills remaining screen ───────────────
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: ColoredBox(
                          color: AppColors.surfaceSecondary,
                          child: AiwaBlockEditor(
                            initialTitle: '',
                            initialBlocks: _blocks,
                            showTitleField: false,
                            onChanged: (draft) {
                              _blocks = draft.blocks;
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceSecondary, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          Expanded(
            child: Text(
              _existing == null ? '新建笔记' : '编辑笔记',
              textAlign: TextAlign.center,
              style: AppTypography.bodyBold.copyWith(color: AppColors.textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded,
                size: 22, color: AppColors.textPrimary),
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleCtrl,
      style: AppTypography.heading.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: '标题（可选）',
        hintStyle: AppTypography.heading
            .copyWith(color: AppColors.textPrimary.withOpacity(.4)),
        border: InputBorder.none,
      ),
    );
  }
}
