import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mvvm/mvvm.dart';

void main() {
  runApp(MaterialApp(
      theme: ThemeData(
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                  primary: Colors.black,
                  fixedSize: const Size.square(100),
                  shape: const CircleBorder()))),
      home: Scaffold(
          body: SafeArea(
              child: DefaultTextStyle(
                  style: const TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontFeatures: [FontFeature.tabularFigures()]),
                  child: TimerView())))));
}

class RecordItem {
  final color = Colors.primaries[Random().nextInt(Colors.primaries.length)];
  final int value;
  RecordItem(this.value);
}

class TimerViewModel extends ViewModel {
  Timer? _timer;
  TimerViewModel() {
    registryProperty(#timer, BindableProperty.$value(initial: 0));
    registryProperty(#started, BindableProperty.$value(initial: false));
    registryProperty(#items, BindableProperty.$value(initial: <RecordItem>[]));
  }

  get started => _timer != null;
  start() {
    if (started) return;
    setValue(#started, true);
    _timer = Timer.periodic(const Duration(milliseconds: 10),
        (_) => updateValue<int>(#timer, (timer) => ++timer));
  }

  stop() {
    if (!started) return;
    setValue(#started, false);
    _timer!.cancel();
    _timer = null;
  }

  toggle() {
    (started) ? stop() : start();
  }

  record() {
    updateValue<List<RecordItem>>(#items,
        (items) => items..insert(0, RecordItem(requireValue<int>(#timer))));
  }

  reset() {
    setValues(const [#timer, #items], [0, <RecordItem>[]]);
  }

  recordOrReset() {
    started ? record() : reset();
  }
}

class TimerView extends View<TimerViewModel> {
  TimerView({Key? key}) : super(TimerViewModel(), key: key);

  pad(int value) => "$value".padLeft(2, "0");
  format(int value) =>
      "${pad(value ~/ (60 * 100))}:${pad((value / 100 % 60).floor())}.${pad(value % 100)}";
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(width: double.infinity, height: 40),
        $.watchFor<int>(#timer,
            builder: (context, value, child) =>
                Text(format(value), style: const TextStyle(fontSize: 60))),
        const SizedBox(height: 40),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          ElevatedButton(
              onPressed: model.recordOrReset,
              child: $.watchFor<bool>(#started,
                  builder: (context, value, child) =>
                      Text(value ? "RECORD" : "RESET"))),
          ElevatedButton(
              onPressed: model.toggle,
              child: $.watchFor<bool>(#started,
                  builder: (context, value, child) =>
                      Text(value ? "STOP" : "START")))
        ]),
        const SizedBox(height: 40),
        Expanded(
            child: $.watchFor<List<RecordItem>>(#items,
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
                            ])))))
      ],
    );
  }
}
