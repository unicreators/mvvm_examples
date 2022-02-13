import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mvvm/mvvm.dart';

void main() {
  runApp(const MaterialApp(home: Scaffold(body: SafeArea(child: HrdView()))));
}

class Cell {
  final int w, h;
  int x, y;
  Cell({required this.x, required this.y, this.w = 1, this.h = 1});

  bool overlaps(Cell other) {
    if ((x + w) <= other.x || (other.x + other.w) <= x) return false;
    if ((y + h) <= other.y || (other.y + other.h) <= y) return false;
    return true;
  }

  bool include(Cell other) {
    return other.x >= x &&
        (other.x + other.w) <= (x + w) &&
        other.y >= y &&
        (other.y + other.h) <= (y + h);
  }

  Cell clone() => Cell(x: x, y: y, w: w, h: h);
}

class Item extends Cell {
  final String name;
  Item(
      {required this.name,
      required int x,
      required int y,
      int w = 1,
      int h = 1})
      : super(x: x, y: y, w: w, h: h);
}

class HrdViewModel extends ViewModel {
  final max = Cell(x: 0, y: 0, w: 4, h: 5);
  final win = Cell(x: 1, y: 1, w: 2, h: 2);
  late Item master;
  late List<BindableProperty<Item>> items;
  final win$ = BindableProperty.$value(initial: false);
  final _history = History();
  final canUndo$ = BindableProperty.$value(initial: false),
      canRedo$ = BindableProperty.$value(initial: false),
      steps$ = BindableProperty.$value(initial: 0),
      timer$ = BindableProperty.$tick(duration: const Duration(seconds: 1));

  HrdViewModel() {
    reset();
  }

  void reset() {
    win$.value = false;
    items = [
      Item(name: "黄忠", x: 0, y: 0, h: 2),
      Item(name: "曹操", x: 1, y: 0, w: 2, h: 2),
      Item(name: "张飞", x: 3, y: 0, h: 2),
      Item(name: "马超", x: 0, y: 2, h: 2),
      Item(name: "关羽", x: 1, y: 2, w: 2, h: 1),
      Item(name: "赵云", x: 3, y: 2, h: 2),
      Item(name: "兵", x: 1, y: 3),
      Item(name: "兵", x: 2, y: 3),
      Item(name: "兵", x: 0, y: 4),
      Item(name: "兵", x: 3, y: 4)
    ].$multi();
    master = items.elementAt(1).value;
    _history.reset();
    _status(canRedo: false, canUndo: false, steps: 0, timer: 2);
  }

  bool isMaster(Item item) => item == master;
  bool get isWin => master.x == win.x && master.y == win.y;

  void move(BindableProperty<Item> item, Direction direction) {
    var target = item.value.clone();
    if (direction == Direction.down) {
      target.y++;
    } else if (direction == Direction.up) {
      target.y--;
    } else if (direction == Direction.left) {
      target.x--;
    } else {
      target.x++;
    }
    if (max.include(target) == false ||
        items.any(
            (element) => element != item && element.value.overlaps(target))) {
      return;
    }
    _history.push(Step(
        item: item,
        x: item.value.x,
        y: item.value.y,
        toX: target.x,
        toY: target.y));
    _move(item, target.x, target.y);
  }

  void _move(BindableProperty<Item> item, int x, int y) {
    item.update((value) => value
      ..x = x
      ..y = y);
    _status(
        canRedo: _history.canRedo,
        canUndo: _history.canUndo,
        steps: _history.current + 1,
        timer: 1);
  }

  void _status({bool? canUndo, bool? canRedo, int? steps, int? timer}) {
    canRedo$.set(canRedo);
    canUndo$.set(canUndo);
    steps$.set(steps);
    if (timer == null) return;
    timer == 0
        ? timer$.stop()
        : timer == 1
            ? timer$.start()
            : timer$.reset();
  }

  void checkWin() {
    var _isWin = isWin;
    win$.value = _isWin;
    _status(
        canRedo: _isWin ? false : null,
        canUndo: _isWin ? false : null,
        timer: _isWin ? 0 : null);
  }

  void undo() {
    var step = _history.undo();
    if (step != null) _move(step.item, step.x, step.y);
  }

  void redo() {
    var step = _history.redo();
    if (step != null) _move(step.item, step.toX, step.toY);
  }
}

class History {
  final _steps = <Step>[];
  int _current = -1;

  int get count => _steps.length;
  int get current => _current;
  bool get canUndo => _current > -1;
  bool get canRedo => _current < count - 1;

  void push(Step step) {
    _steps
      ..removeRange(_current + 1, _steps.length)
      ..add(step);
    _current = _steps.length - 1;
  }

  void reset() {
    _current = -1;
    _steps.clear();
  }

  Step? undo() {
    if (canUndo == false) return null;
    return _steps.elementAt(_current--);
  }

  Step? redo() {
    if (canRedo == false) return null;
    return _steps.elementAt(++_current);
  }
}

class Step {
  final BindableProperty<Item> item;
  final int x, y, toX, toY;
  Step(
      {required this.item,
      required this.x,
      required this.y,
      required this.toX,
      required this.toY});
}

enum Direction { left, right, up, down }

class HrdView extends View<HrdViewModel> {
  final double spacing;
  const HrdView({Key? key, this.spacing = 2}) : super(key: key);

  @override
  Widget build(ViewBuildContext<HrdViewModel> context, HrdViewModel model) {
    var grid = (MediaQuery.of(context).size.width - spacing) / model.max.w;
    _location(int space) => grid * space + spacing;
    _size(int space) => grid * space - spacing;
    Direction? _direction;
    var iconSize = 64.0;
    return Column(children: [
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(
              children: [
                $watch<int>(model.steps$,
                    builder: (context, value, child) =>
                        Text("$value", style: const TextStyle(fontSize: 28))),
                const Text("STEPS", style: TextStyle(fontSize: 10))
              ],
            ),
            Column(
              children: [
                $watch<int>(model.timer$,
                    builder: (context, value, child) => Text(
                        "${value ~/ 60}:${(value % 60).toString().padLeft(2, "0")}",
                        style: const TextStyle(
                            fontSize: 28,
                            fontFeatures: [FontFeature.tabularFigures()]))),
                const Text("TIMES", style: TextStyle(fontSize: 10))
              ],
            ),
          ])),
      Stack(children: [
        Container(
            height: grid * model.max.h,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.black12, width: spacing))),
        Positioned(
            left: _location(model.win.x),
            top: _location(model.win.y),
            child: Container(
                color: Colors.redAccent.withOpacity(.4),
                width: _size(model.win.w),
                height: _size(model.win.h))),
        ...$multi<Item>(model.items,
            builder: (context, item, child, index, vl) {
          return AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.fastOutSlowIn,
              onEnd: model.checkWin,
              left: _location(item.x),
              top: _location(item.y),
              child: GestureDetector(
                  onPanUpdate: (details) {
                    var dx = details.delta.dx, dy = details.delta.dy;
                    if (dx.abs() > dy.abs()) {
                      _direction = dx > 0 ? Direction.right : Direction.left;
                    } else {
                      _direction = dy > 0 ? Direction.down : Direction.up;
                    }
                  },
                  onPanEnd: (_) => _direction == null
                      ? null
                      : model.move(vl as BindableProperty<Item>, _direction!),
                  child: Container(
                      color: model.isMaster(item)
                          ? Colors.redAccent
                          : Colors.blueAccent,
                      width: _size(item.w),
                      height: _size(item.h),
                      child: Center(child: Text(item.name)))));
        }).toList(),
        $watch<bool>(model.win$,
            builder: (_, value, child) => !value
                ? const SizedBox.shrink()
                : GestureDetector(
                    onTap: () => context.setState(model.reset),
                    child: Container(
                        color: Colors.redAccent,
                        height: grid * model.max.h + spacing,
                        child: const Center(
                          child: Text(
                            "Win!",
                            style: TextStyle(fontSize: 48, color: Colors.white),
                          ),
                        ))))
      ]),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          $watch<bool>(model.canUndo$,
              builder: (context, value, child) => IconButton(
                  onPressed: value ? model.undo : null,
                  iconSize: iconSize,
                  icon: const Icon(Icons.undo_rounded))),
          IconButton(
              onPressed: () => context.setState(model.reset),
              iconSize: iconSize,
              icon: const Icon(Icons.restart_alt_rounded)),
          $watch<bool>(model.canRedo$,
              builder: (context, value, child) => IconButton(
                  onPressed: value ? model.redo : null,
                  iconSize: iconSize,
                  icon: const Icon(Icons.redo_rounded))),
        ],
      )
    ]);
  }

  @override
  HrdViewModel createViewModel() => HrdViewModel();
}
