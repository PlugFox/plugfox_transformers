// ignore_for_file: avoid_print

import 'package:plugfox_transformers/plugfox_transformers.dart';

void main() {
  // Simultaneous Transformer
  Stream<String> myGenerator(int event) async* {
    String state;

    state = await Future<String>.delayed(
        const Duration(milliseconds: 250), () => '$event + 2 = ${event + 2}');
    yield state;

    state = await Future<String>.delayed(
        const Duration(milliseconds: 500), () => '$event * 2 = ${event * 2}');
    yield state;

    state = await Future<String>.delayed(const Duration(milliseconds: 750),
        () => '$event ^ 2 = ${event * event}');
    yield state;
  }

  Stream<int>.fromIterable(const <int>[1, 2, 3, 4, 5, 6, 7])
      .transform<String>(
          Simultaneous<int, String>(myGenerator, maxNumberOfProcesses: 2))
      .forEach(print);
}
