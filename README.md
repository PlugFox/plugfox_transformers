# plugfox_transformers  
  
[![chatroom icon](https://patrolavia.github.io/telegram-badge/chat.png)](https://t.me/PlugFox)
[![Pub](https://img.shields.io/pub/v/plugfox_transformers.svg)](https://pub.dartlang.org/packages/plugfox_transformers)  
  
## About  
  
Сontains a set of useful stream transformers
+ `Simultaneous` (Serves for simultaneous parallel tasks)
  

## Simultaneous
  
Serves for simultaneous parallel tasks

Executes simultaneously `[maxNumberOfProcesses]` generators `[convert]`
transforming each `[Event]` into a Stream of `[State]`.
The resulting stream is returned from the `[Stream.transform]` method.

If `[maxNumberOfProcesses]` is set to 0 or less, then all
incoming events processed instantly.

If `[maxNumberOfProcesses]` is set to 1, then the
behavior is almost identical .asyncExpand method.

If `[maxNumberOfProcesses]` is set to 2 or more, then this sets the number
simultaneously performed tasks and each subsequent event begins to be processed
as soon as one of the previous ones is finished.
 
The transformer breaks the sequence of events in the stream.
  

### Example usage:

```dart
Stream<String> myGenerator(int event) async* {
  String state;

  state = await Future<String>.delayed(
        const Duration(milliseconds: 250)
      , () => '$event + 2 = ${event + 2}');
  yield state;
  
  state = await Future<String>.delayed(
        const Duration(milliseconds: 500)
      , () => '$event * 2 = ${event * 2}');
  yield state;
  
  state = await Future<String>.delayed(
        const Duration(milliseconds: 750)
      , () => '$event ^ 2 = ${event * event}');
  yield state;
}

Stream<int>.fromIterable(const <int>[1, 2, 3, 4, 5, 6, 7])
  .transform<String>(Simultaneous<int, String>(myGenerator, maxNumberOfProcesses: 2))
  .forEach(print);
```

### Override `bloc` package behavior:  
  
```dart
@override  
Stream<Transition<Event, State>> transformEvents(
  Stream<Event> events,
  Stream<Transition<Event, State>> Function(Event) next) => 
    events.transform<Transition<Event, State>>(
      Simultaneous<Event, Transition<Event, State>>(next, maxNumberOfProcesses: 0)
    );
```
  
  
## Changelog  
  
Refer to the [Changelog](https://github.com/plugfox/plugfox_transformers/blob/master/CHANGELOG.md) to get all release notes.  
  
  
