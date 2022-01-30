import 'dart:async';
import 'dart:ui';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mvvm/mvvm.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
        body: SafeArea(
            child: DefaultTextStyle(
                style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontFeatures: [FontFeature.tabularFigures()]),
                child: TimerView()))),
    theme: ThemeData(
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                primary: Colors.black,
                fixedSize: const Size(100, 100),
                shape: const CircleBorder()))),
  ));
}

class RecordItem {
  final int value;
  final Color color =
      Colors.primaries[Random().nextInt(Colors.primaries.length)];
  RecordItem(this.value);
}

/// ViewModel
///
class TimerViewModel extends ViewModel {
  Timer? _timer;

  /// 定义绑定属性
  final $timer = BindableProperty.$value(initial: 0);
  final $started = BindableProperty.$value(initial: false);
  final $list = BindableProperty.$value<List<RecordItem>>(initial: []);

  ///
  /// 也可将绑定属性值定义为类属性，方便使用
  ///
  /// List<RecordItem> get items => $list.value;
  /// ...
  ///
  bool get started => $started.value;

  void startOrStop() {
    if (_timer == null) {
      // start
      $started.value = true;
      _timer = Timer.periodic(
          const Duration(milliseconds: 10), (_) => ++$timer.value);
    } else {
      // stop
      $started.value = false;
      _timer!.cancel();
      _timer = null;
    }
  }

  void resetOrRecord() {
    if (started) {
      // record
      $list
        ..value.insert(0, RecordItem($timer.value))
        ..notify();
    } else {
      // reset
      $timer.value = 0;
      $list.value = [];
    }
  }
}

// View
class TimerView extends View<TimerViewModel> {
  TimerView({Key? key}) : super(TimerViewModel(), key: key);

  pad(int v) => "$v".padLeft(2, "0");
  format(int v) =>
      "${pad(v ~/ (60 * 100))}:${pad(((v / 100) % 60).floor())}.${pad(v % 100)}";

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 60),
      $.watch<int>(model.$timer,
          builder: (context, ms, child) =>
              Text(format(ms), style: const TextStyle(fontSize: 60))),
      const SizedBox(height: 40),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
              onPressed: model.resetOrRecord,
              child: $.watch<bool>(model.$started,
                  builder: (context, started, child) =>
                      Text(started ? "RECORD" : "RESET"))),
          ElevatedButton(
              onPressed: model.startOrStop,
              child: $.watch<bool>(model.$started,
                  builder: (context, started, child) =>
                      Text(started ? "STOP" : "START"))),
        ],
      ),
      const SizedBox(height: 40),
      Expanded(
          child: $.watch<List<RecordItem>>(model.$list,
              builder: (context, items, child) => ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, index) => Container(
                      color: items[index].color.withOpacity(.1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("#${pad(items.length - index)}"),
                          Text(format(items[index].value),
                              style: TextStyle(color: items[index].color))
                        ],
                      )))))
    ]);
  }
}
