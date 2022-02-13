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
      home: const Scaffold(
          body: SafeArea(
              child: DefaultTextStyle(
                  style: TextStyle(
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
  late final timer$ = BindableProperty.$tick(
      duration: const Duration(milliseconds: 10),
      statusChanged: (_) => setValue<bool>(#started, _.started),
      initial: 0);
  TimerViewModel() {
    registerProperty(#started, BindableProperty.$value(initial: false));
    registerProperty(#items, BindableProperty.$value(initial: <RecordItem>[]));
  }

  record() {
    updateValue<List<RecordItem>>(
        #items, (items) => items..insert(0, RecordItem(timer$.value)));
  }

  reset() {
    timer$.reset();
    setValue(#items, <RecordItem>[]);
  }

  recordOrReset() {
    timer$.started ? record() : reset();
  }
}

class TimerView extends View<TimerViewModel> {
  const TimerView({Key? key}) : super(key: key);

  pad(int value) => "$value".padLeft(2, "0");
  format(int value) =>
      "${pad(value ~/ (60 * 100))}:${pad((value / 100 % 60).floor())}.${pad(value % 100)}";

  @override
  TimerViewModel createViewModel() => TimerViewModel();

  @override
  Widget build(ViewBuildContext context, TimerViewModel model) {
    return Column(
      children: [
        const SizedBox(width: double.infinity, height: 40),
        $watch<int>(model.timer$,
            builder: (context, value, child) =>
                Text(format(value), style: const TextStyle(fontSize: 60))),
        const SizedBox(height: 40),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          ElevatedButton(
              onPressed: model.recordOrReset,
              child: context.$watchFor<bool>(#started,
                  builder: (context, value, child) =>
                      Text(value ? "RECORD" : "RESET"))),
          ElevatedButton(
              onPressed: model.timer$.toggle,
              child: context.$watchFor<bool>(#started,
                  builder: (context, value, child) =>
                      Text(value ? "STOP" : "START")))
        ]),
        const SizedBox(height: 40),
        Expanded(
            child: context.$watchFor<List<RecordItem>>(#items,
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
