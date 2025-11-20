import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pathfitcapstone/app/theme/colors.dart';
import 'package:pathfitcapstone/app/theme/text_styles.dart';
import 'package:pathfitcapstone/core/services/quiz_media_service.dart';

class InstructorQuizViewScreen extends StatefulWidget {
  final String quizId;

  const InstructorQuizViewScreen({super.key, required this.quizId});

  @override
  State<InstructorQuizViewScreen> createState() => _InstructorQuizViewScreenState();
}

class _InstructorQuizViewScreenState extends State<InstructorQuizViewScreen> {
  Map<String, dynamic>? _quiz;
  bool _loading = true;
  String? _error;
  bool _editing = false;

  // Editing state
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  int _timeLimitMinutesEdited = 0;
  int _pointsPerQuestionEdited = 1;
  bool _shuffleQuestionsEdited = false;
  bool _shuffleOptionsEdited = false;
  DateTime? _availableFromEdited;
  DateTime? _availableUntilEdited;
  late List<dynamic> _editableQuestions = [];
  String fmtDT(DateTime? dt) {
    if (dt == null) return 'Not set';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  bool get _isMC => ((_quiz?['type'] as String?) ?? '').toLowerCase().contains('multiple');
  bool get _isTF => ((_quiz?['type'] as String?) ?? '').toLowerCase().contains('true');
  bool get _isID => ((_quiz?['type'] as String?) ?? '').toLowerCase().contains('identification');
  bool get _isUI {
    final t = ((_quiz?['type'] as String?) ?? '').toLowerCase();
    return t.contains('understand') || t.contains('image');
  }

  final QuizMediaService _mediaService = QuizMediaService();
  Future<String?> _uploadQuizImage(XFile file, {String? fileName}) async {
    try {
      return await _mediaService.uploadXFile(file: file, folderId: widget.quizId, fileName: fileName);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('courseQuizzes')
          .doc(widget.quizId)
          .get();
      if (!doc.exists) {
        setState(() {
          _error = 'Quiz not found';
          _loading = false;
        });
        return;
      }
      setState(() {
        _quiz = doc.data();
        // Initialize editable fields
        _titleController.text = (_quiz?['title'] as String?) ?? '';
        _instructionsController.text = (_quiz?['instructions'] as String?) ?? '';
        _timeLimitMinutesEdited = (_quiz?['timeLimitMinutes'] as int?) ?? 0;
        _pointsPerQuestionEdited = (_quiz?['pointsPerQuestion'] as int?) ?? 1;
        _shuffleQuestionsEdited = (_quiz?['shuffleQuestions'] as bool?) ?? false;
        _shuffleOptionsEdited = (_quiz?['shuffleOptions'] as bool?) ?? false;
        final fromTs = _quiz?['availableFrom'] as Timestamp?;
        final untilTs = _quiz?['availableUntil'] as Timestamp?;
        _availableFromEdited = fromTs?.toDate();
        _availableUntilEdited = untilTs?.toDate();
        final questionsRaw = List<Map<String, dynamic>>.from((_quiz?['questions'] as List?) ?? const []);
        if (_isMC) {
          _editableQuestions = questionsRaw
              .map((q) => _EditableQuestion(
                    text: (q['text'] as String?) ?? '',
                    options: List<String>.from((q['options'] as List?) ?? const []),
                    correctIndex: (q['correctIndex'] as int?) ?? -1,
                  ))
              .toList();
        } else if (_isTF) {
          _editableQuestions = questionsRaw
              .map((q) => _EditableTFQuestion(
                    text: (q['text'] as String?) ?? '',
                    answer: (q['answer'] as bool?) ?? false,
                  ))
              .toList();
        } else if (_isID) {
          _editableQuestions = questionsRaw
              .map((q) => _EditableIDQuestion(
                    text: (q['text'] as String?) ?? '',
                    answer: (q['answer'] as String?) ?? '',
                  ))
              .toList();
        } else if (_isUI) {
          _editableQuestions = questionsRaw
              .map((q) {
                final text = (q['text'] as String?) ?? '';
                final imageUrl = (q['imageUrl'] as String?) ?? '';
                final hasImage = imageUrl.isNotEmpty;
                final hasAnswer = (q['answer'] as String?) != null;
                final optionsImages = List<String>.from((q['optionsImages'] as List?) ?? const []);
                final optionsText = List<String>.from((q['options'] as List?) ?? const []);
                final correctIndex = (q['correctIndex'] as int?) ?? 0;
                return _EditableUIImageQuestion(
                  questionIsImage: hasImage,
                  questionText: text,
                  questionImageUrl: hasImage ? imageUrl : null,
                  identification: hasAnswer,
                  identificationAnswer: (q['answer'] as String?) ?? '',
                  optionsAreImage: optionsImages.isNotEmpty,
                  optionsText: optionsText,
                  optionsImageUrls: optionsImages,
                  correctIndex: correctIndex,
                );
              })
              .toList();
        } else {
          _editableQuestions = const [];
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load quiz';
        _loading = false;
      });
    }
  }

  void _enterEditMode() {
    setState(() {
      _editing = true;
    });
  }

  Future<void> _saveQuiz() async {
    if (!_editing || _quiz == null) return;
    try {
      // Basic validation
      final title = _titleController.text.trim();
      if (title.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title cannot be empty')),
        );
        return;
      }
      List<Map<String, dynamic>> questionsPayload = [];
      if (_isMC) {
        for (final q in _editableQuestions.cast<_EditableQuestion>()) {
          if (q.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Question text cannot be empty')),
            );
            return;
          }
          if (q.options.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Each question must have options')),
            );
            return;
          }
          if (q.correctIndex < 0 || q.correctIndex >= q.options.length) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a correct answer for each question')),
            );
            return;
          }
          questionsPayload.add({
            'text': q.text.trim(),
            'options': q.options.map((o) => o.trim()).toList(),
            'correctIndex': q.correctIndex,
          });
        }
      } else if (_isTF) {
        for (final q in _editableQuestions.cast<_EditableTFQuestion>()) {
          if (q.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Question text cannot be empty')),
            );
            return;
          }
          questionsPayload.add({
            'text': q.text.trim(),
            'answer': q.answer,
          });
        }
      } else if (_isID) {
        for (final q in _editableQuestions.cast<_EditableIDQuestion>()) {
          if (q.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Question text cannot be empty')),
            );
            return;
          }
          if (q.answer.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Identification requires an answer for each question')),
            );
            return;
          }
          questionsPayload.add({
            'text': q.text.trim(),
            'answer': q.answer.trim(),
          });
        }
      } else if (_isUI) {
        for (final q in _editableQuestions.cast<_EditableUIImageQuestion>()) {
          if (q.questionIsImage) {
            if ((q.questionImageUrl ?? '').trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please upload an image for the image-based question')),
              );
              return;
            }
          } else {
            if (q.questionText.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Question text cannot be empty')),
              );
              return;
            }
          }
          if (q.identification) {
            if (q.identificationAnswer.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please provide the identification answer')),
              );
              return;
            }
            final map = <String, dynamic>{
              if (q.questionIsImage) 'imageUrl': q.questionImageUrl,
              if (!q.questionIsImage) 'text': q.questionText.trim(),
              'answer': q.identificationAnswer.trim(),
            };
            questionsPayload.add(map);
          } else {
            // Multiple-choice with text or image choices
            if (q.optionsAreImage) {
              final imgs = q.optionsImageUrls.where((e) => (e).trim().isNotEmpty).toList();
              if (imgs.length < 2 || q.correctIndex < 0 || q.correctIndex >= imgs.length) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Provide at least two image choices and select the correct one')),
                );
                return;
              }
              final map = <String, dynamic>{
                if (q.questionIsImage) 'imageUrl': q.questionImageUrl,
                if (!q.questionIsImage) 'text': q.questionText.trim(),
                'optionsImages': imgs,
                'correctIndex': q.correctIndex,
              };
              questionsPayload.add(map);
            } else {
              final opts = q.optionsText.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              if (opts.length < 2 || q.correctIndex < 0 || q.correctIndex >= opts.length) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Provide at least two text choices and select the correct one')),
                );
                return;
              }
              final map = <String, dynamic>{
                if (q.questionIsImage) 'imageUrl': q.questionImageUrl,
                if (!q.questionIsImage) 'text': q.questionText.trim(),
                'options': opts,
                'correctIndex': q.correctIndex,
              };
              questionsPayload.add(map);
            }
          }
        }
      }

      final updated = <String, dynamic>{
        'title': title,
        'instructions': _instructionsController.text.trim(),
        'timeLimitMinutes': 0,
        'pointsPerQuestion': _pointsPerQuestionEdited,
        'shuffleQuestions': _shuffleQuestionsEdited,
        'questions': questionsPayload,
      };
      if (_isMC || _isUI) {
        updated['shuffleOptions'] = _shuffleOptionsEdited;
      }
      if (_availableFromEdited != null) {
        updated['availableFrom'] = Timestamp.fromDate(_availableFromEdited!);
      } else {
        updated['availableFrom'] = FieldValue.delete();
      }
      if (_availableUntilEdited != null) {
        updated['availableUntil'] = Timestamp.fromDate(_availableUntilEdited!);
      } else {
        updated['availableUntil'] = FieldValue.delete();
      }

      await FirebaseFirestore.instance
          .collection('courseQuizzes')
          .doc(widget.quizId)
          .update(updated);

      // Update local state and exit edit mode
      setState(() {
        _quiz = {...?_quiz, ...updated};
        _editing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save quiz: $e')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: const Text('Are you sure you want to delete this quiz? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteQuiz();
    }
  }

  Future<void> _deleteQuiz() async {
    try {
      await FirebaseFirestore.instance
          .collection('courseQuizzes')
          .doc(widget.quizId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz deleted')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete quiz: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (_quiz?['title'] as String?) ?? 'Quiz';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_editing ? (_titleController.text.isEmpty ? 'Edit Quiz' : _titleController.text) : title),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: _loading ? null : _confirmDelete,
          ),
          if (!_editing)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit),
              onPressed: _loading ? null : _enterEditMode,
            )
          else
            IconButton(
              tooltip: 'Save',
              icon: const Icon(Icons.save),
              onPressed: _loading ? null : _saveQuiz,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _editing ? _buildEditContent() : _buildContent(),
    );
  }

  Widget _buildContent() {
    final instructions = (_quiz?['instructions'] as String?) ?? '';
    final course = (_quiz?['course'] as String?) ?? '';
    final year = (_quiz?['year'] as String?) ?? '';
    final section = (_quiz?['section'] as String?) ?? '';
    final timeLimit = (_quiz?['timeLimitMinutes'] as int?) ?? 0;
    final pointsPerQuestion = (_quiz?['pointsPerQuestion'] as int?) ?? 1;
    final fromTs = _quiz?['availableFrom'] as Timestamp?;
    final untilTs = _quiz?['availableUntil'] as Timestamp?;
    String two(int n) => n.toString().padLeft(2, '0');
    String fmtDT(DateTime? dt) => dt == null ? 'Not set' : '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
    final questions = List<Map<String, dynamic>>.from((_quiz?['questions'] as List?) ?? const []);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: 'Target Audience',
              child: Text(
                '$course — $year • Section $section',
                style: AppTextStyles.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
            if (instructions.isNotEmpty)
              _SectionCard(
                title: 'Instructions',
                child: Text(
                  instructions,
                  style: AppTextStyles.textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Quiz Settings',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _SettingChip(icon: Icons.score, label: '$pointsPerQuestion pt/question'),
                  _SettingChip(icon: Icons.play_circle_outline, label: 'Start: ${fmtDT(fromTs?.toDate())}'),
                  _SettingChip(icon: Icons.stop_circle_outlined, label: 'End: ${fmtDT(untilTs?.toDate())}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < questions.length; i++)
              _isMC
                  ? _InstructorQuestionCard(index: i, data: questions[i])
                  : _isTF
                      ? _InstructorTFQuestionCard(index: i, data: questions[i])
                      : _isID
                          ? _InstructorIDQuestionCard(index: i, data: questions[i])
                          : _InstructorUIImageQuestionCard(index: i, data: questions[i]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEditContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: 'Quiz Title',
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter quiz title',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Instructions',
              child: TextField(
                controller: _instructionsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter instructions',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Quiz Settings',
              child: Column(
                children: [
                  TextFormField(
                    key: const ValueKey('points-per-question'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Points Per Question',
                    ),
                    initialValue: _pointsPerQuestionEdited.toString(),
                    onChanged: (val) {
                      final v = int.tryParse(val) ?? 1;
                      setState(() => _pointsPerQuestionEdited = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final now = DateTime.now();
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _availableFromEdited ?? now,
                              firstDate: DateTime(now.year - 1),
                              lastDate: DateTime(now.year + 5),
                            );
                            if (date == null) return;
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _availableFromEdited != null
                                  ? TimeOfDay(hour: _availableFromEdited!.hour, minute: _availableFromEdited!.minute)
                                  : TimeOfDay.now(),
                            );
                            if (time == null) return;
                            setState(() {
                              _availableFromEdited = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Start'),
                              Text(fmtDT(_availableFromEdited)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final now = DateTime.now();
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _availableUntilEdited ?? _availableFromEdited ?? now,
                              firstDate: DateTime(now.year - 1),
                              lastDate: DateTime(now.year + 5),
                            );
                            if (date == null) return;
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _availableUntilEdited != null
                                  ? TimeOfDay(hour: _availableUntilEdited!.hour, minute: _availableUntilEdited!.minute)
                                  : TimeOfDay.now(),
                            );
                            if (time == null) return;
                            setState(() {
                              _availableUntilEdited = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('End'),
                              Text(fmtDT(_availableUntilEdited)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _CheckboxLabel(
                        value: _shuffleQuestionsEdited,
                        label: 'Shuffle Questions',
                        onChanged: (v) => setState(() => _shuffleQuestionsEdited = v),
                      ),
                      if (_isMC || _isUI)
                        _CheckboxLabel(
                          value: _shuffleOptionsEdited,
                          label: 'Shuffle Options',
                          onChanged: (v) => setState(() => _shuffleOptionsEdited = v),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < _editableQuestions.length; i++)
              _isMC
                  ? _InstructorQuestionEditorCard(
                      index: i,
                      question: _editableQuestions[i] as _EditableQuestion,
                      onChanged: (q) => setState(() => _editableQuestions[i] = q),
                    )
                  : _isTF
                      ? _InstructorTFQuestionEditorCard(
                          index: i,
                          question: _editableQuestions[i] as _EditableTFQuestion,
                          onChanged: (q) => setState(() => _editableQuestions[i] = q),
                        )
                      : _isID
                          ? _InstructorIDQuestionEditorCard(
                              index: i,
                              question: _editableQuestions[i] as _EditableIDQuestion,
                              onChanged: (q) => setState(() => _editableQuestions[i] = q),
                            )
                          : _InstructorUIImageQuestionEditorCard(
                              index: i,
                              question: _editableQuestions[i] as _EditableUIImageQuestion,
                              onChanged: (q) => setState(() => _editableQuestions[i] = q),
                              uploadImage: (file, {fileName}) => _uploadQuizImage(file, fileName: fileName),
                            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _saveQuiz,
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructorQuestionCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;

  const _InstructorQuestionCard({required this.index, required this.data});

  @override
  Widget build(BuildContext context) {
    final text = (data['text'] as String?) ?? '';
    final options = List<String>.from((data['options'] as List?) ?? const []);
    final correctIndex = (data['correctIndex'] as int?) ?? -1;

    return _SectionCard(
      title: 'Question ${index + 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: AppTextStyles.textTheme.titleSmall),
          const SizedBox(height: 12),
          for (int i = 0; i < options.length; i++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(8),
                color: i == correctIndex ? AppColors.successGreen.withOpacity(0.08) : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    i == correctIndex ? Icons.check_circle : Icons.circle_outlined,
                    color: i == correctIndex ? Colors.green : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      options[i],
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: i == correctIndex ? Colors.green[800] : AppColors.textPrimary,
                        fontWeight: i == correctIndex ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (i == correctIndex)
                    Text(
                      'Correct answer',
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(color: Colors.green[700]),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InstructorTFQuestionCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;

  const _InstructorTFQuestionCard({required this.index, required this.data});

  @override
  Widget build(BuildContext context) {
    final text = (data['text'] as String?) ?? '';
    final answer = (data['answer'] as bool?) ?? false;

    return _SectionCard(
      title: 'Question ${index + 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: AppTextStyles.textTheme.titleSmall),
          const SizedBox(height: 12),
          _tfOption('True', true, answer),
          const SizedBox(height: 8),
          _tfOption('False', false, answer),
        ],
      ),
    );
  }

  Widget _tfOption(String label, bool isTrue, bool answer) {
    final selected = answer == isTrue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
        color: selected ? AppColors.successGreen.withOpacity(0.08) : Colors.white,
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle : Icons.circle_outlined,
            color: selected ? Colors.green : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: selected ? Colors.green[800] : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (selected)
            Text(
              'Correct answer',
              style: AppTextStyles.textTheme.bodySmall?.copyWith(color: Colors.green[700]),
            ),
        ],
      ),
    );
  }
}

class _InstructorIDQuestionCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;

  const _InstructorIDQuestionCard({required this.index, required this.data});

  @override
  Widget build(BuildContext context) {
    final text = (data['text'] as String?) ?? '';
    final answer = (data['answer'] as String?) ?? '';
    return _SectionCard(
      title: 'Question ${index + 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: AppTextStyles.textTheme.titleSmall),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.primaryBlue.withOpacity(0.04),
            ),
            child: Row(
              children: [
                const Icon(Icons.short_text, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Answer: $answer',
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructorUIImageQuestionCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;

  const _InstructorUIImageQuestionCard({required this.index, required this.data});

  bool get _isIdentification => (data['answer'] as String?) != null;
  bool get _hasImageQuestion => ((data['imageUrl'] as String?) ?? '').isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final text = (data['text'] as String?) ?? '';
    final answer = (data['answer'] as String?) ?? '';
    final optionsText = List<String>.from((data['options'] as List?) ?? const []);
    final optionsImages = List<String>.from((data['optionsImages'] as List?) ?? const []);
    final correctIndex = (data['correctIndex'] as int?) ?? -1;

    return _SectionCard(
      title: 'Question ${index + 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasImageQuestion)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network((data['imageUrl'] as String?)!, height: 150, fit: BoxFit.cover),
            )
          else
            Text(text, style: AppTextStyles.textTheme.titleSmall),
          const SizedBox(height: 12),
          if (_isIdentification) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.primaryBlue.withOpacity(0.04),
              ),
              child: Row(
                children: [
                  const Icon(Icons.short_text, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Answer: $answer', style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
                  ),
                ],
              ),
            ),
          ] else if (optionsImages.isNotEmpty) ...[
            for (int i = 0; i < optionsImages.length; i++) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(8),
                  color: i == correctIndex ? AppColors.successGreen.withOpacity(0.08) : Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(
                      i == correctIndex ? Icons.check_circle : Icons.circle_outlined,
                      color: i == correctIndex ? Colors.green : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(optionsImages[i], height: 120, fit: BoxFit.cover),
                      ),
                    ),
                    if (i == correctIndex)
                      Text('Correct answer', style: AppTextStyles.textTheme.bodySmall?.copyWith(color: Colors.green[700])),
                  ],
                ),
              ),
            ],
          ] else ...[
            for (int i = 0; i < optionsText.length; i++) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(8),
                  color: i == correctIndex ? AppColors.successGreen.withOpacity(0.08) : Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(
                      i == correctIndex ? Icons.check_circle : Icons.circle_outlined,
                      color: i == correctIndex ? Colors.green : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        optionsText[i],
                        style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                          color: i == correctIndex ? Colors.green[800] : AppColors.textPrimary,
                          fontWeight: i == correctIndex ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (i == correctIndex)
                      Text('Correct answer', style: AppTextStyles.textTheme.bodySmall?.copyWith(color: Colors.green[700])),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _InstructorQuestionEditorCard extends StatelessWidget {
  final int index;
  final _EditableQuestion question;
  final ValueChanged<_EditableQuestion> onChanged;

  const _InstructorQuestionEditorCard({required this.index, required this.question, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Question ${index + 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: ValueKey('q-$index-text'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Question Text',
            ),
            initialValue: question.text,
            onChanged: (v) => onChanged(question.copyWith(text: v)),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < question.options.length; i++) ...[
            Row(
              children: [
                Radio<int>(
                  value: i,
                  groupValue: question.correctIndex,
                  onChanged: (val) => onChanged(question.copyWith(correctIndex: val ?? i)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('q-$index-opt-$i'),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Option ${i + 1}',
                    ),
                    initialValue: question.options[i],
                    onChanged: (v) {
                      final opts = List<String>.from(question.options);
                      opts[i] = v;
                      onChanged(question.copyWith(options: opts));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _InstructorTFQuestionEditorCard extends StatelessWidget {
  final int index;
  final _EditableTFQuestion question;
  final ValueChanged<_EditableTFQuestion> onChanged;

  const _InstructorTFQuestionEditorCard({required this.index, required this.question, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Question ${index + 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: ValueKey('tf-q-$index-text'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Question Text',
            ),
            initialValue: question.text,
            onChanged: (v) => onChanged(question.copyWith(text: v)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: question.answer,
                onChanged: (val) => onChanged(question.copyWith(answer: val ?? true)),
              ),
              const SizedBox(width: 8),
              const Text('True'),
              const SizedBox(width: 24),
              Radio<bool>(
                value: false,
                groupValue: question.answer,
                onChanged: (val) => onChanged(question.copyWith(answer: val ?? false)),
              ),
              const SizedBox(width: 8),
              const Text('False'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InstructorIDQuestionEditorCard extends StatelessWidget {
  final int index;
  final _EditableIDQuestion question;
  final ValueChanged<_EditableIDQuestion> onChanged;

  const _InstructorIDQuestionEditorCard({required this.index, required this.question, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Question ${index + 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: ValueKey('id-q-$index-text'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Question Text',
            ),
            initialValue: question.text,
            onChanged: (v) => onChanged(question.copyWith(text: v)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('id-q-$index-answer'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Answer',
            ),
            initialValue: question.answer,
            onChanged: (v) => onChanged(question.copyWith(answer: v)),
          ),
        ],
      ),
    );
  }
}

class _InstructorUIImageQuestionEditorCard extends StatelessWidget {
  final int index;
  final _EditableUIImageQuestion question;
  final ValueChanged<_EditableUIImageQuestion> onChanged;
  final Future<String?> Function(XFile file, {String? fileName}) uploadImage;

  const _InstructorUIImageQuestionEditorCard({
    required this.index,
    required this.question,
    required this.onChanged,
    required this.uploadImage,
  });

  Future<void> _pickQuestionImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final url = await uploadImage(file, fileName: 'q_${index}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    if (url != null) {
      onChanged(question.copyWith(questionImageUrl: url));
    }
  }

  Future<void> _pickChoiceImage(int optIndex) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final url = await uploadImage(file, fileName: 'opt_${index}_${optIndex}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    if (url != null) {
      final imgs = List<String>.from(question.optionsImageUrls);
      if (optIndex < imgs.length) {
        imgs[optIndex] = url;
      } else {
        imgs.add(url);
      }
      onChanged(question.copyWith(optionsImageUrls: imgs));
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = question;
    final textOptCount = q.optionsText.isEmpty ? 2 : q.optionsText.length;
    final imageOptCount = q.optionsImageUrls.isEmpty ? 2 : q.optionsImageUrls.length;
    return _SectionCard(
      title: 'Question ${index + 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChoiceChip(
                label: const Text('Text'),
                selected: !q.questionIsImage,
                onSelected: (sel) {
                  if (sel) onChanged(q.copyWith(questionIsImage: false));
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Image'),
                selected: q.questionIsImage,
                onSelected: (sel) {
                  if (sel) onChanged(q.copyWith(questionIsImage: true));
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!q.questionIsImage) ...[
            TextFormField(
              key: ValueKey('ui-q-$index'),
              initialValue: q.questionText,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Question Text'),
              onChanged: (v) => onChanged(q.copyWith(questionText: v)),
            ),
          ] else ...[
            if ((q.questionImageUrl ?? '').isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(q.questionImageUrl!, height: 150, fit: BoxFit.cover),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _pickQuestionImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Upload question image'),
              ),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Identification'),
                selected: q.identification,
                onSelected: (sel) {
                  if (sel) onChanged(q.copyWith(identification: true));
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Multiple Choice'),
                selected: !q.identification,
                onSelected: (sel) {
                  if (sel) onChanged(q.copyWith(identification: false));
                },
              ),
            ],
          ),

          const SizedBox(height: 12),
          if (q.identification) ...[
            TextFormField(
              key: ValueKey('ui-a-$index'),
              initialValue: q.identificationAnswer,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Answer'),
              onChanged: (v) => onChanged(q.copyWith(identificationAnswer: v)),
            ),
          ] else ...[
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Text choices'),
                  selected: !q.optionsAreImage,
                  onSelected: (sel) {
                    if (sel) onChanged(q.copyWith(optionsAreImage: false));
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Image choices'),
                  selected: q.optionsAreImage,
                  onSelected: (sel) {
                    if (sel) onChanged(q.copyWith(optionsAreImage: true));
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!q.optionsAreImage) ...[
              for (int i = 0; i < textOptCount; i++) ...[
                Row(
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: q.correctIndex,
                      onChanged: (val) => onChanged(q.copyWith(correctIndex: val ?? i)),
                      activeColor: AppColors.primaryBlue,
                    ),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('ui-opt-$index-$i'),
                        initialValue: i < q.optionsText.length ? q.optionsText[i] : '',
                        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Option'),
                        onChanged: (v) {
                          final opts = List<String>.from(q.optionsText);
                          if (i < opts.length) {
                            opts[i] = v;
                          } else {
                            opts.add(v);
                          }
                          onChanged(q.copyWith(optionsText: opts));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ] else ...[
              for (int i = 0; i < imageOptCount; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: q.correctIndex,
                      onChanged: (val) => onChanged(q.copyWith(correctIndex: val ?? i)),
                      activeColor: AppColors.primaryBlue,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (i < q.optionsImageUrls.length && q.optionsImageUrls[i].isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(q.optionsImageUrls[i], height: 120, fit: BoxFit.cover),
                            )
                          else
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.textSecondary.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text('No image', style: AppTextStyles.textTheme.bodySmall),
                            ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _pickChoiceImage(i),
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('Upload choice image'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    final imgs = List<String>.from(q.optionsImageUrls)..add('');
                    onChanged(q.copyWith(optionsImageUrls: imgs));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add choice slot'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SettingChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SettingChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.textTheme.labelLarge?.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableQuestion {
  final String text;
  final List<String> options;
  final int correctIndex;

  _EditableQuestion({required this.text, required this.options, required this.correctIndex});

  _EditableQuestion copyWith({String? text, List<String>? options, int? correctIndex}) =>
      _EditableQuestion(
        text: text ?? this.text,
        options: options ?? this.options,
        correctIndex: correctIndex ?? this.correctIndex,
      );
}

class _EditableTFQuestion {
  final String text;
  final bool answer;

  _EditableTFQuestion({required this.text, required this.answer});

  _EditableTFQuestion copyWith({String? text, bool? answer}) =>
      _EditableTFQuestion(text: text ?? this.text, answer: answer ?? this.answer);
}

class _EditableIDQuestion {
  final String text;
  final String answer;

  _EditableIDQuestion({required this.text, required this.answer});

  _EditableIDQuestion copyWith({String? text, String? answer}) =>
      _EditableIDQuestion(text: text ?? this.text, answer: answer ?? this.answer);
}

class _EditableUIImageQuestion {
  final bool questionIsImage;
  final String questionText;
  final String? questionImageUrl;
  final bool identification;
  final String identificationAnswer;
  final bool optionsAreImage;
  final List<String> optionsText;
  final List<String> optionsImageUrls;
  final int correctIndex;

  _EditableUIImageQuestion({
    required this.questionIsImage,
    required this.questionText,
    required this.questionImageUrl,
    required this.identification,
    required this.identificationAnswer,
    required this.optionsAreImage,
    required this.optionsText,
    required this.optionsImageUrls,
    required this.correctIndex,
  });

  _EditableUIImageQuestion copyWith({
    bool? questionIsImage,
    String? questionText,
    String? questionImageUrl,
    bool? identification,
    String? identificationAnswer,
    bool? optionsAreImage,
    List<String>? optionsText,
    List<String>? optionsImageUrls,
    int? correctIndex,
  }) => _EditableUIImageQuestion(
        questionIsImage: questionIsImage ?? this.questionIsImage,
        questionText: questionText ?? this.questionText,
        questionImageUrl: questionImageUrl ?? this.questionImageUrl,
        identification: identification ?? this.identification,
        identificationAnswer: identificationAnswer ?? this.identificationAnswer,
        optionsAreImage: optionsAreImage ?? this.optionsAreImage,
        optionsText: optionsText ?? this.optionsText,
        optionsImageUrls: optionsImageUrls ?? this.optionsImageUrls,
        correctIndex: correctIndex ?? this.correctIndex,
      );
}

class _CheckboxLabel extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  const _CheckboxLabel({required this.value, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: (val) => onChanged(val ?? false),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

