import 'dart:async';
import 'package:test/test.dart';
import 'package:plugfox_transformers/plugfox_transformers.dart' show Simultaneous;

const int _delayedOperationInMilliseconds = 100;
const int _toleranceInMilliseconds = 25;
const List<int> _sourceList = <int>[1, 2, 3, 4, 5, 6, 7];
Stream<int> get _sourceStream => Stream<int>.fromIterable(_sourceList);

// ignore: unused_element
const Timeout _smallTimeout = Timeout(Duration(seconds: 1));
// ignore: unused_element
const Timeout _normalTimeout = Timeout(Duration(seconds: 15));
// ignore: unused_element
const Timeout _bigTimeout = Timeout(Duration(seconds: 360));

Stream<T> _pong<T>(T value) => Stream<T>.value(value);
Stream<T> _pongDelayed<T>(T value) => Future<T>.delayed(const Duration(milliseconds: _delayedOperationInMilliseconds), () => value).asStream();

void main() {
  test('shouldRun', () async {
    const StreamTransformer<int, int> simultaneous = Simultaneous<int, int>(_pong);
    await _sourceStream.transform<int>(simultaneous).drain<int>();
    expect(true, true);
  }, timeout: _smallTimeout);

  test('shouldRunAsDelayed', () async {
    const StreamTransformer<int, int> simultaneous = Simultaneous<int, int>(_pongDelayed);
    await _sourceStream.transform<int>(simultaneous).drain<int>();
    expect(true, true);
  }, timeout: _smallTimeout);
  
  test('shouldReturnExpectedData', () async {
    const StreamTransformer<int, int> simultaneous = Simultaneous<int, int>(_pong);
    List<int> result = await _sourceStream.transform<int>(simultaneous).toList();
    expect(result, _sourceList);
  }, timeout: _smallTimeout);

  test('shouldReturnExpectedDataAsDelayed', () async {
    const StreamTransformer<int, int> simultaneous = Simultaneous<int, int>(_pongDelayed);
    List<int> result = await _sourceStream.transform<int>(simultaneous).toList();
    expect(result, _sourceList);
  }, timeout: _smallTimeout);

  test('shouldBeDelayedAsUnlimited', () async {
    final int begin = DateTime.now().millisecondsSinceEpoch;
    const StreamTransformer<int, int> simultaneous = Simultaneous<int, int>.unlimited(_pongDelayed);
    await _sourceStream.transform<int>(simultaneous).drain<int>();
    final int end = DateTime.now().millisecondsSinceEpoch;
    final int dt = end - begin;
    expect(dt >= _delayedOperationInMilliseconds, true);
    expect(dt < _delayedOperationInMilliseconds + _toleranceInMilliseconds, true);
  }, timeout: _smallTimeout);

  test('shouldBeDelayedAsSingle', () async {
    final int begin = DateTime.now().millisecondsSinceEpoch;
    const StreamTransformer<int, int> simultaneous = Simultaneous<int, int>.single(_pongDelayed);
    await _sourceStream.transform<int>(simultaneous).drain<int>();
    final int end = DateTime.now().millisecondsSinceEpoch;
    final int dt = end - begin;
    expect(dt >= _delayedOperationInMilliseconds * _sourceList.length, true);
    expect(dt < _delayedOperationInMilliseconds * _sourceList.length + _toleranceInMilliseconds, true);
  }, timeout: _smallTimeout);

  test('shouldBeDelayedAsPair', () async {
    final int begin = DateTime.now().millisecondsSinceEpoch;
    const StreamTransformer<int, int> simultaneous = Simultaneous<int, int>.pair(_pongDelayed);
    await _sourceStream.transform<int>(simultaneous).drain<int>();
    final int end = DateTime.now().millisecondsSinceEpoch;
    final int dt = end - begin;
    expect(dt >= _delayedOperationInMilliseconds * (_sourceList.length / 2).ceil(), true);
    expect(dt < _delayedOperationInMilliseconds * (_sourceList.length / 2).ceil() + _toleranceInMilliseconds, true);
  }, timeout: _smallTimeout);

  test('shouldBeDelayedAsCustom', () async {
    final int begin = DateTime.now().millisecondsSinceEpoch;
    const int maxNumberOfProcesses = 5; 
    const StreamTransformer<int, int> simultaneous = Simultaneous<int, int>(_pongDelayed, maxNumberOfProcesses: maxNumberOfProcesses);
    await _sourceStream.transform<int>(simultaneous).drain<int>();
    final int end = DateTime.now().millisecondsSinceEpoch;
    final int dt = end - begin;
    expect(dt >= _delayedOperationInMilliseconds * (_sourceList.length / maxNumberOfProcesses).ceil(), true);
    expect(dt < _delayedOperationInMilliseconds * (_sourceList.length / maxNumberOfProcesses).ceil() + _toleranceInMilliseconds, true);
  }, timeout: _smallTimeout);

  test('reusable', () async {
    const StreamTransformer<int, int> simultaneous = Simultaneous<int, int>(_pong);
    List<int> result1 = await _sourceStream.transform<int>(simultaneous).toList();
    List<int> result2 = await _sourceStream.transform<int>(simultaneous).toList();
    expect(result1, result2);
  }, timeout: _smallTimeout);

  test('asSingleSubscriptionStream', () async {
    const StreamTransformer<int, int> simultaneous = Simultaneous<int, int>(_pong);
    expect(_sourceStream.transform<int>(simultaneous).isBroadcast, false);
  }, timeout: _smallTimeout);

  test('asBroadcastStream', () async {
    const StreamTransformer<int, int> simultaneous = Simultaneous<int, int>(_pong);
    expect(_sourceStream.asBroadcastStream().transform<int>(simultaneous).isBroadcast, true);
  }, timeout: _smallTimeout);

  test('cancelOnErrorFalse', () async {
    const StreamTransformer<int, int> simultaneous = Simultaneous<int, int>(_pong);
    bool hasError = false;
    await Stream<int>.error(Exception('test')).transform<int>(simultaneous).handleError((dynamic _) => hasError = true).drain<int>();
    expect(hasError, true);
  }, timeout: _smallTimeout);

  test('cancelOnErrorTrue', () async {
    const StreamTransformer<int, int> simultaneous = Simultaneous<int, int>(_pong, cancelOnError: true);
    bool hasError = false;
    await Stream<int>.error(Exception('test')).transform<int>(simultaneous).handleError((dynamic _) => hasError = true).drain<int>();
    expect(hasError, true);
  }, timeout: _smallTimeout);

  test('emptySourceStream', () async {
    const StreamTransformer<void, void> simultaneous = Simultaneous<void, void>(_pong);
    await const Stream<void>.empty().transform<void>(simultaneous).drain<void>();
    expect(true, true);
  }, timeout: _smallTimeout);


}