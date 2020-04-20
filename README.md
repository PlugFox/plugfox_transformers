# plugfox_transformers  
  
[![Pub](https://img.shields.io/pub/v/plugfox_transformers.svg)](https://pub.dartlang.org/packages/plugfox_transformers)  
  
## About  
  
Сontains a set of useful stream transformers
  
### Simultaneous

## How To Use  
  
### For example: Transform myEventsStream

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

final Stream<int> stream = Stream<int>.fromIterable(const <int>[1, 2, 3, 4, 5, 6, 7]);
controller
  .stream
  .transform<String>(Simultaneous<int, String>(myGenerator, maxNumberOfProcesses: 2))
  .forEach(print);
```

### For example: Override `bloc` package behavior  
  
```dart
@override  
Stream<MyState> transformEvents(
  Stream<MyEvent> events,
  Stream<MyState> Function(MyEvent) next) => 
    events.transform<MyState>(Simultaneous<MyEvent, MyState>(next, maxNumberOfProcesses: 0));
```
  
## Stream transformer Classes  
  
  + Simultaneous
  
## Changelog  
  
Refer to the [Changelog](https://github.com/plugfox/plugfox_transformers/blob/master/CHANGELOG.md) to get all release notes.  
  