import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/di/injection.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/services/feedback_service.dart';
import 'package:wonderly/core/services/sound_service.dart';
import 'package:wonderly/core/services/speech_service.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/widgets/wonder_button.dart';
import 'package:wonderly/core/widgets/wonder_widgets.dart';
import 'package:wonderly/features/ai/presentation/cubit/generation_cubit.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/learning/presentation/subject_style.dart';
import 'package:wonderly/features/quiz/presentation/bloc/quiz_bloc.dart';
import 'package:wonderly/features/quiz/presentation/bloc/quiz_event.dart';
import 'package:wonderly/features/quiz/presentation/bloc/quiz_state.dart';
import 'package:wonderly/features/quiz/presentation/widgets/break_view.dart';
import 'package:wonderly/features/quiz/presentation/widgets/choice_question_view.dart';
import 'package:wonderly/features/quiz/presentation/widgets/feedback_panel.dart';
import 'package:wonderly/features/quiz/presentation/widgets/pattern_question_view.dart';
import 'package:wonderly/features/quiz/presentation/widgets/quiz_parts.dart';
import 'package:wonderly/features/quiz/presentation/widgets/shape_match_view.dart';
import 'package:wonderly/features/settings/domain/services/play_guard.dart';
import 'package:wonderly/features/settings/presentation/cubit/settings_cubit.dart';

/// Plays one quiz set, one question per screen.
class QuizPage extends StatelessWidget {
  const QuizPage({required this.setId, super.key});

  final String setId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<QuizBloc>()..add(QuizStarted(setId)),
      child: const _QuizView(),
    );
  }
}

class _QuizView extends StatefulWidget {
  const _QuizView();

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> with WidgetsBindingObserver {
  final SpeechService _speech = sl<SpeechService>();
  final FeedbackService _feedback = sl<FeedbackService>();
  final SoundService _sound = sl<SoundService>();

  final GenerationCubit _generation = sl<GenerationCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Keep the phone free for the child while a quiz is open.
    _generation.pause(PauseReason.quizOpen);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<QuizBloc>().add(
      QuizLifecycleChanged(active: state == AppLifecycleState.resumed),
    );
    if (state != AppLifecycleState.resumed) _speech.stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speech.stop();
    unawaited(_generation.resume(PauseReason.quizOpen));
    super.dispose();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  void _onState(BuildContext context, QuizState state) {
    final settings = context.read<SettingsCubit>().state;
    if (state.status == QuizStatus.finished && state.summary != null) {
      context.pushReplacement(Routes.results, extra: state.summary);
      return;
    }
    if (state.revealed && state.lastCorrect != null && settings.soundEffects) {
      final correct = state.lastCorrect!;
      unawaited(correct ? _feedback.correct() : _feedback.incorrect());
      unawaited(_sound.play(correct ? SoundEffect.correct : SoundEffect.wrong));
    }
    if (state.saveFailed) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('We could not save your progress. Ask a grown-up.'),
          ),
        );
    }
  }

  Future<void> _readAloud(Question question) async {
    final result = await _speech.speak(_speechText(question));
    if (!mounted) return;
    if (result.failureOrNull != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Read aloud is not available here.')),
        );
    }
  }

  String _speechText(Question q) => switch (q) {
    ChoiceQuestion(:final prompt, :final options) =>
      '$prompt ${options.map((o) => o.label).join(', ')}',
    PatternQuestion(:final prompt, :final sequence) =>
      '$prompt ${sequence.join(', ')}',
    ShapeMatchQuestion(:final prompt) => prompt,
  };

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuizBloc, QuizState>(
      listenWhen: (a, b) =>
          a.revealed != b.revealed ||
          a.saveFailed != b.saveFailed ||
          a.status != b.status,
      listener: _onState,
      builder: (context, state) {
        final background = state.set?.subject.quizColor ?? AppColors.sun;
        return Scaffold(
          backgroundColor: background,
          body: SafeArea(child: _body(context, state)),
        );
      },
    );
  }

  Widget _body(BuildContext context, QuizState state) {
    switch (state.status) {
      case QuizStatus.loading:
      case QuizStatus.finished:
        return const Center(child: CircularProgressIndicator());
      case QuizStatus.failed:
        return Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: WonderBackButton(onPressed: _leave),
              ),
            ),
            Expanded(
              child: MessageView(
                title: 'Hmm, not available',
                message: 'This quiz cannot be opened right now.',
                actionLabel: 'Go back',
                onAction: _leave,
              ),
            ),
          ],
        );
      case QuizStatus.blocked:
        return BreakView(
          reason: state.blockReason ?? BreakReason.dailyLimit,
          onHome: () => context.go(Routes.home),
        );
      case QuizStatus.playing:
        return _playing(context, state);
    }
  }

  Widget _playing(BuildContext context, QuizState state) {
    final question = state.question;
    final set = state.set;
    if (question == null || set == null) return const SizedBox.shrink();
    final bloc = context.read<QuizBloc>();
    final readAloud = context.select((SettingsCubit c) => c.state.readAloud);
    final isMatch = question is ShapeMatchQuestion;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        children: [
          QuizHeader(
            title: set.title,
            current: state.index + 1,
            total: state.total,
            onBack: _leave,
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _questionView(bloc, state, question),
                  const SizedBox(height: 14),
                  if (state.revealed && state.lastCorrect != null)
                    FeedbackPanel(
                      correct: state.lastCorrect!,
                      questionNumber: state.index,
                      starsGained: state.lastStars,
                      fact: question.fact,
                      coachText: state.aiExplanation,
                      coachLoading: state.aiExplanationLoading,
                    )
                  else ...[
                    QuizToolRow(
                      onHint: () => bloc.add(const QuizHintToggled()),
                      onReadAloud: readAloud
                          ? () => _readAloud(question)
                          : null,
                    ),
                    if (state.hintVisible &&
                        (state.aiHint ?? question.hint) != null) ...[
                      const SizedBox(height: 10),
                      HintBubble(text: (state.aiHint ?? question.hint)!),
                    ] else if (state.hintVisible && state.aiHintLoading) ...[
                      const SizedBox(height: 10),
                      const HintBubble(text: 'Thinking of a hint for you...'),
                    ] else if (state.hintVisible) ...[
                      const SizedBox(height: 10),
                      const HintBubble(
                        text:
                            'Read the question once more and look at every '
                            'choice. You can do it!',
                      ),
                    ],
                    if (isMatch &&
                        state.canAdvance &&
                        question.fact != null) ...[
                      const SizedBox(height: 10),
                      HintBubble(text: question.fact!),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          WonderButton(
            label: state.index + 1 >= state.total && state.revealed
                ? 'Finish'
                : 'Next',
            onPressed: state.canAdvance
                ? () => bloc.add(const QuizNextPressed())
                : null,
          ),
        ],
      ),
    );
  }

  Widget _questionView(QuizBloc bloc, QuizState state, Question question) {
    return switch (question) {
      ChoiceQuestion() => ChoiceQuestionView(
        question: question,
        selected: state.selected,
        revealed: state.revealed,
        onSelect: (i) => bloc.add(QuizOptionSelected(i)),
      ),
      PatternQuestion() => PatternQuestionView(
        question: question,
        selected: state.selected,
        revealed: state.revealed,
        onSelect: (i) => bloc.add(QuizOptionSelected(i)),
      ),
      ShapeMatchQuestion() => ShapeMatchView(
        key: ValueKey(question.id),
        question: question,
        placed: state.placed,
        onPlaced: (shape) => bloc.add(QuizShapePlaced(shape)),
      ),
    };
  }
}
