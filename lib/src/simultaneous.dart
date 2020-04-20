import 'dart:async';
//import 'package:pedantic/pedantic.dart' show unawaited;

/// Serves for simultaneous parallel tasks
///
/// Executes simultaneously [maxNumberOfProcesses] generators [convert]
/// transforming each [Event] into a Stream of [State].
/// The resulting stream is returned from the [Stream.transform] method.
/// 
/// If [maxNumberOfProcesses] is set to 0 or less, then all
/// incoming events processed instantly.
///
/// If [maxNumberOfProcesses] is set to 1, then the
/// behavior is almost identical .asyncExpand method.
/// 
/// If [maxNumberOfProcesses] is set to 2 or more, then this sets the number
/// simultaneously performed tasks and each subsequent event begins to be processed
/// as soon as one of the previous ones is finished.
///  
/// The transformer breaks the sequence of events in the stream.
/// 
/// 
/// **Usage example:**
/// ```
///   events.transform<State>(Simultaneous<Event, State>(myGenerator, maxNumberOfProcesses: 2))
/// ```
///      // source:              abcd------------------
///      // source.delayed(2):   --A1B1A2B2--C1D1C2D2--
/// 
/// 
/// **Example usage to override the behavior of the [bloc] library:**
/// ```
///   @override  
///   Stream<MyState> transformEvents(
///     Stream<MyEvent> events,
///     Stream<MyState> Function(MyEvent) next) => 
///       events.transform<MyState>(Simultaneous<MyEvent, MyState>(next, maxNumberOfProcesses: 0));
/// ```
///
class Simultaneous<Event, State> implements StreamTransformer<Event, State> {
  
  final Stream<State> Function(Event) _convert;
  final int _maxProcesses;
  final bool _cancelOnError;

  /*
  /// Set maximum number of simultaneous parallel tasks
  set maxNumberOfProcesses(int value) =>
    _maxProcesses = value ?? 0;
  */

  /// Transformer with custom maximum number of concurent processes
  const Simultaneous(
      Stream<State> Function(Event) convert
    , {int maxNumberOfProcesses = 0
    , bool cancelOnError = false})
    : assert(convert != null && maxNumberOfProcesses != null)
    , _convert = convert
    , _maxProcesses = maxNumberOfProcesses ?? 0
    , _cancelOnError = cancelOnError ?? false;

  /// Transformer with an infinite number of concurent processes
  const Simultaneous.unlimited(Stream<State> Function(Event) convert, {bool cancelOnError = false})
    : assert(convert != null)
    , _convert = convert
    , _maxProcesses = 0
    , _cancelOnError = cancelOnError ?? false;

  /// Transformer with one concurent process
  const Simultaneous.single(Stream<State> Function(Event) convert, {bool cancelOnError = false})
    : assert(convert != null)
    , _convert = convert
    , _maxProcesses = 1
    , _cancelOnError = cancelOnError ?? false;
  
  /// Transformer with two concurent processes
  const Simultaneous.pair(Stream<State> Function(Event) convert, {bool cancelOnError = false})
    : assert(convert != null)
    , _convert = convert
    , _maxProcesses = 2
    , _cancelOnError = cancelOnError ?? false;

  @override
  Stream<State> bind(Stream<Event> events) {
    final _SimultaneousController controller = _SimultaneousController(maxNumberOfTasks: _maxProcesses);
    final StreamIterator<Event> eventIterator = StreamIterator<Event>(events);
    final StreamController<State> stateController = StreamController<State>(
      onPause: null,
      onResume: null,
      onCancel: eventIterator.cancel,
      sync: false,
    );
    // ITERATOR +
    Future.doWhile(() => 
      eventIterator
        .moveNext()
        .then((bool hasNext) async {
          if (!hasNext) {
            await controller.awaitLastTask();
            return await Future.wait<void>(<Future<void>>[
              controller.close(),
              stateController.close(),
            ]).then<bool>((void _) => false);
          }
          Future<void> callback = _convert(eventIterator.current)
            .handleError((dynamic error, StackTrace stackTrace) {
              stateController.addError(error, stackTrace);
              if (_cancelOnError) {
                eventIterator.cancel();
                controller.close();
                stateController.close();
              }
            }).forEach(stateController.sink.add);
          await controller.awaitTaskIfNeeded(callback);
          return true;
        },
        onError: (dynamic error, StackTrace stackTrace) {
          stateController.addError(error, stackTrace);
          if (_cancelOnError) {
            eventIterator.cancel();
            controller.close();
            stateController.close();
            return false;
          }
          return true;
        }),
    );
    // ITERATOR -
    return events.isBroadcast
      ? stateController.stream.asBroadcastStream() 
      : stateController.stream;
  }

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() =>
      StreamTransformer.castFrom<Event, State, RS, RT>(this);
}

class _SimultaneousController {
  int _currTasks;
  final int _maxTasks;
  final StreamController<int> _currentTasksChangedController = StreamController<int>.broadcast();
  bool get hasTask => _currTasks > 0;
  bool get awaitTask => _currTasks >= _maxTasks && _maxTasks > 0;

  _SimultaneousController({int maxNumberOfTasks = 0})
    : assert(maxNumberOfTasks != null)
    , _maxTasks = maxNumberOfTasks ?? 0
    , _currTasks = 0;

  FutureOr<void> awaitTaskIfNeeded(Future<void> callback) {
    _addTask();
    // ignore: unawaited
    //unawaited(
      callback.whenComplete(_rmTask);
    //);
    if (awaitTask) return callback;
  }

  void _addTask() {
    _currTasks++;
    _currentTasksChangedController.add(_currTasks);
  }

  void _rmTask() {
    _currTasks--;
    _currentTasksChangedController.add(_currTasks);
  }

  FutureOr<void> awaitLastTask() async {
    if (_currTasks != 0) {
      await _currentTasksChangedController.stream.firstWhere((int n) => n == 0);
    }
  }

  Future<void> close() =>
    _currentTasksChangedController.close();
}