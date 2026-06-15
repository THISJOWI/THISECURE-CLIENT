import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart' show Delta;
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/data/models/note_entry.dart';
import 'package:thisjowi/i18n/translations.dart';

import '../../data/repository/notes_repository.dart';

class EditNoteScreen extends StatefulWidget {
  final NotesRepository notesRepository;
  final Note? note;

  const EditNoteScreen({
    super.key,
    required this.notesRepository,
    this.note,
  });

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final _titleController = TextEditingController();
  late final QuillController _quillController;
  late final FocusNode _quillFocusNode;
  late final ScrollController _quillScrollController;
  StreamSubscription? _docSub;
  bool _isProcessing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _quillFocusNode = FocusNode();
    _quillScrollController = ScrollController();

    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _quillController = _buildBodyController(widget.note!.content);
    } else {
      _quillController = QuillController.basic();
    }

    _docSub = _quillController.document.changes.listen(_onDocChange);
  }

  QuillController _buildBodyController(String content) {
    if (content.isEmpty) return QuillController.basic();

    try {
      final json = jsonDecode(content);
      if (json is List && json.isNotEmpty) {
        final delta = Delta.fromJson(json);
        final plain = _deltaPlain(delta);
        if (plain.trimRight().isNotEmpty) {
          return QuillController(
            document: Document.fromDelta(delta),
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
      }
    } catch (_) {
      if (content.trim().isNotEmpty) {
        final delta = Delta();
        delta.insert(content);
        if (!content.endsWith('\n')) {
          delta.insert('\n');
        }
        return QuillController(
          document: Document.fromDelta(delta),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    }

    return QuillController.basic();
  }

  String _deltaPlain(Delta delta) {
    final sb = StringBuffer();
    for (final op in delta.toJson()) {
      if (op['insert'] is String) sb.write(op['insert'] as String);
    }
    return sb.toString();
  }

  void _onDocChange(DocChange change) {
    if (_isProcessing) return;

    final ops = change.change.toJson();
    if (ops.length != 1) return;
    final insert = ops[0]['insert'];
    if (insert is! String || insert != ' ') return;

    _isProcessing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShortcut();
      _isProcessing = false;
    });
  }

  void _checkShortcut() {
    final offset = _quillController.selection.baseOffset;
    if (offset < 2) return;

    final text = _quillController.document.toPlainText();
    final before = text.substring(0, offset);

    for (final entry in _shortcuts) {
      if (before.endsWith(entry.$1)) {
        _applyShortcut(entry.$1, entry.$2);
        return;
      }
    }
  }

  void _applyShortcut(String pattern, Attribute attr) {
    final offset = _quillController.selection.baseOffset;
    final start = offset - pattern.length;
    _quillController.replaceText(start, pattern.length, '\n', null);
    _quillController.replaceText(
        0, 0, '', TextSelection.collapsed(offset: start));
    _quillController.formatText(0, 0, attr);
    _quillController.replaceText(start + 1, 1, '', null);
  }

  @override
  void dispose() {
    _docSub?.cancel();
    _titleController.dispose();
    _quillController.dispose();
    _quillFocusNode.dispose();
    _quillScrollController.dispose();
    super.dispose();
  }

  void _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      if (!mounted) return;
      try {
        ErrorSnackBar.showWarning(context, 'Please enter a title'.i18n);
      } catch (e) {
        debugPrint('Error showing snackbar: $e');
      }
      return;
    }

    final contentJson =
        jsonEncode(_quillController.document.toDelta().toJson());

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final note = Note(
        title: _titleController.text.trim(),
        content: contentJson,
        id: widget.note?.id,
        localId: widget.note?.localId,
        serverId: widget.note?.serverId,
      );

      if (widget.note != null) {
        final r = await widget.notesRepository
            .updateNote(widget.note!.localId ?? '', note);
        if (!r['success']) throw Exception(r['message']);
      } else {
        final r = await widget.notesRepository.createNote(note);
        if (!r['success']) throw Exception(r['message']);
      }

      if (!mounted) return;
      try {
        Navigator.pop(context, true);
      } catch (e) {
        debugPrint('Error closing dialog: $e');
      }
    } catch (e) {
      debugPrint('Error saving note: $e');
      if (mounted) {
        try {
          ErrorSnackBar.show(context, 'Error saving note'.i18n);
        } catch (snackBarError) {
          debugPrint('Error showing snackbar: $snackBarError');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveOnBack() async {
    if (_titleController.text.trim().isEmpty) return;

    final contentJson =
        jsonEncode(_quillController.document.toDelta().toJson());

    try {
      final note = Note(
        title: _titleController.text.trim(),
        content: contentJson,
        id: widget.note?.id,
        localId: widget.note?.localId,
        serverId: widget.note?.serverId,
      );
      if (widget.note != null) {
        final r = await widget.notesRepository
            .updateNote(widget.note!.localId ?? '', note);
        if (!r['success']) throw Exception(r['message']);
      } else {
        final r = await widget.notesRepository.createNote(note);
        if (!r['success']) throw Exception(r['message']);
      }
    } catch (e) {
      debugPrint('Error saving note on back: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isPhone = MediaQuery.of(context).size.shortestSide < 600;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _saveOnBack();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (!isPhone)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios,
                            color: onSurface, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _isLoading ? null : _saveNote,
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                          minimumSize: const Size(44, 44),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        child: Text('Done'.i18n),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary))
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                        child: Column(
                          children: [
                            TextField(
                              controller: _titleController,
                              mouseCursor: SystemMouseCursors.text,
                              enableInteractiveSelection: false,
                              style: TextStyle(
                                color: onSurface,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) =>
                                  _quillFocusNode.requestFocus(),
                              decoration: const InputDecoration(
                                hintText: 'Title',
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: QuillEditor.basic(
                                controller: _quillController,
                                focusNode: _quillFocusNode,
                                scrollController: _quillScrollController,
                                config: const QuillEditorConfig(
                                  placeholder: 'Start typing...',
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              _buildToolbar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: onSurface.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: QuillSimpleToolbar(
        controller: _quillController,
        config: QuillSimpleToolbarConfig(
          multiRowsDisplay: false,
          showDividers: false,
          showFontFamily: false,
          showFontSize: false,
          showSubscript: false,
          showSuperscript: false,
          showColorButton: false,
          showBackgroundColorButton: false,
          showCodeBlock: false,
          showLink: false,
          showSearchButton: false,
          showQuote: false,
          showIndent: false,
          showDirection: false,
          showLineHeightButton: false,
          showAlignmentButtons: false,
          showSmallButton: false,
          showStrikeThrough: false,
          showInlineCode: false,
          showUndo: true,
          showRedo: true,
          showBoldButton: true,
          showItalicButton: true,
          showUnderLineButton: true,
          showHeaderStyle: true,
          showListNumbers: true,
          showListBullets: true,
          showListCheck: true,
          toolbarSectionSpacing: 2,
          buttonOptions: QuillSimpleToolbarButtonOptions(
            base: QuillToolbarBaseButtonOptions(
              iconTheme: QuillIconTheme(
                iconButtonUnselectedData: const IconButtonData(
                  iconSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _shortcuts = <(String, Attribute)>[
  ('[] ', Attribute.unchecked),
  ('1. ', Attribute.ol),
  ('- ', Attribute.ul),
  ('# ', Attribute.h1),
  ('## ', Attribute.h2),
  ('### ', Attribute.h3),
];
