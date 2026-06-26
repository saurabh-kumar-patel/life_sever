import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'focus_event.dart';
import 'focus_state.dart';

class FocusBloc extends Bloc<FocusEvent, FocusState> {
  Timer? _timer;

  FocusBloc() : super(FocusIdle()) {
    on<StartFocus>(_onStartFocus);
    on<PauseFocus>(_onPauseFocus);
    on<ResumeFocus>(_onResumeFocus);
    on<TickFocus>(_onTickFocus);
    on<CancelFocus>(_onCancelFocus);
    on<CompleteFocus>(_onCompleteFocus);
  }

  void _onStartFocus(StartFocus event, Emitter<FocusState> emit) {
    _timer?.cancel();
    final totalSeconds = event.durationMinutes * 60;
    
    emit(FocusRunning(
      task: event.task,
      durationTotalSeconds: totalSeconds,
      secondsRemaining: totalSeconds,
      isPaused: false,
    ));

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(TickFocus());
    });
  }

  void _onPauseFocus(PauseFocus event, Emitter<FocusState> emit) {
    if (state is FocusRunning) {
      final current = state as FocusRunning;
      emit(FocusRunning(
        task: current.task,
        durationTotalSeconds: current.durationTotalSeconds,
        secondsRemaining: current.secondsRemaining,
        isPaused: true,
      ));
    }
  }

  void _onResumeFocus(ResumeFocus event, Emitter<FocusState> emit) {
    if (state is FocusRunning) {
      final current = state as FocusRunning;
      emit(FocusRunning(
        task: current.task,
        durationTotalSeconds: current.durationTotalSeconds,
        secondsRemaining: current.secondsRemaining,
        isPaused: false,
      ));
    }
  }

  void _onTickFocus(TickFocus event, Emitter<FocusState> emit) {
    if (state is FocusRunning) {
      final current = state as FocusRunning;
      if (!current.isPaused) {
        final remaining = current.secondsRemaining - 1;
        if (remaining <= 0) {
          _timer?.cancel();
          emit(FocusFinished(current.task));
        } else {
          emit(FocusRunning(
            task: current.task,
            durationTotalSeconds: current.durationTotalSeconds,
            secondsRemaining: remaining,
            isPaused: false,
          ));
        }
      }
    }
  }

  void _onCancelFocus(CancelFocus event, Emitter<FocusState> emit) {
    _timer?.cancel();
    emit(FocusIdle());
  }

  void _onCompleteFocus(CompleteFocus event, Emitter<FocusState> emit) {
    if (state is FocusRunning) {
      final current = state as FocusRunning;
      _timer?.cancel();
      emit(FocusFinished(current.task));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
