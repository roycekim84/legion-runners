import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

enum RunPhase { gate, encounter, finalBattle, result }

enum UnitType { militia, swordsman, archer, knight }

class LegionGame extends FlameGame {
  final snapshot = ValueNotifier(
    const LegionSnapshot(
      phase: RunPhase.gate,
      army: 10,
      enemy: 20,
      message: '좌우로 드래그해 군단을 움직이세요',
      stageDistance: 0,
      gateCount: 0,
      militia: 10,
    ),
  );
  final _random = math.Random(7);
  ui.Image? _background;
  double _lane = 0, _targetLane = 0, _distance = 0, _timer = 0;
  int _army = 10, _enemy = 20, _maxArmy = 10, _defeated = 0;
  int _gateCount = 0, _militia = 10, _swordsmen = 0, _archers = 0, _knights = 0;
  RunPhase _phase = RunPhase.gate;
  String _message = '첫 번째 선택: 병력을 불리세요';

  @override
  Color backgroundColor() => const Color(0xFF071321);
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    images.prefix = 'assets/art/';
    _background = await images.load('battlefield.png');
    camera.viewport = FixedResolutionViewport(resolution: Vector2(390, 844));
  }

  void moveBy(double d) =>
      _targetLane = (_targetLane + d / 180).clamp(-1.0, 1.0);
  void chooseGate(int option) {
    if (_phase != RunPhase.gate) return;
    if (_gateCount == 0 && option == 0) {
      _army += 10;
      _militia += 10;
      _message = '민병대 +10';
    } else if (_gateCount == 0) {
      _army *= 2;
      _militia *= 2;
      _message = '군단 ×2';
    } else if (option == 0) {
      _army += 30;
      _swordsmen += 30;
      _message = '검사 +30  •  근접 전투력 상승';
    } else if (option == 1) {
      _army += 10;
      _archers += 10;
      _message = '궁수 +10  •  선제 원거리 공격';
    } else {
      _army += 10;
      _knights += 10;
      _message = '기사 +10  •  정예 방어 진형';
    }
    _gateCount++;
    _maxArmy = math.max(_maxArmy, _army);
    _phase = RunPhase.encounter;
    _enemy = _gateCount == 1 ? 20 : 80;
    _publish();
  }

  void restart() {
    _lane = 0;
    _targetLane = 0;
    _distance = 0;
    _timer = 0;
    _army = 10;
    _enemy = 20;
    _maxArmy = 10;
    _defeated = 0;
    _gateCount = 0;
    _militia = 10;
    _swordsmen = 0;
    _archers = 0;
    _knights = 0;
    _phase = RunPhase.gate;
    _message = '첫 번째 선택: 병력을 불리세요';
    _publish();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lane += (_targetLane - _lane) * math.min(1, dt * 7);
    if (_phase == RunPhase.result) return;
    _distance += dt * .12;
    if (_phase == RunPhase.encounter || _phase == RunPhase.finalBattle) {
      _timer += dt;
      final cadence = _phase == RunPhase.finalBattle ? 1.7 : 2.2;
      if (_timer > cadence) {
        _timer = 0;
        final loss = math.max(
          1,
          (_enemy * (_phase == RunPhase.finalBattle ? .045 : .07)).round(),
        );
        final damage = math.max(
          1,
          (_armyPower * (_phase == RunPhase.finalBattle ? .1 : .12)).round(),
        );
        _army = math.max(0, _army - loss);
        _enemy = math.max(0, _enemy - damage);
        _defeated += damage;
        if (_army == 0) {
          _finish(false);
        } else if (_enemy == 0 && _gateCount == 1) {
          _phase = RunPhase.gate;
          _message = '두 번째 선택: 검사 강화 또는 기사 편성';
          _enemy = 80;
        } else if (_enemy == 0 && _gateCount >= 2) {
          _phase = RunPhase.finalBattle;
          _enemy = 150;
          _message = '최종 좀비 군단이 접근합니다!';
        }
        _publish();
      }
    }
    _publish();
  }

  void _finish(bool victory) {
    _phase = RunPhase.result;
    _message = victory ? '마왕군을 돌파했습니다!' : '군단이 무너졌습니다';
    _enemy = 0;
    _publish();
  }

  void _publish() => snapshot.value = LegionSnapshot(
    phase: _phase,
    army: _army,
    enemy: _enemy,
    stageDistance: _distance,
    message: _message,
    maxArmy: _maxArmy,
    defeated: _defeated,
    gateCount: _gateCount,
    militia: _militia,
    swordsmen: _swordsmen,
    archers: _archers,
    knights: _knights,
  );

  double get _armyPower =>
      _militia + _swordsmen * 1.2 + _archers * 1.35 + _knights * 2.1;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = canvasSize.x, h = canvasSize.y;
    final p = Paint();
    if (_background case final background?) {
      canvas.drawImageRect(
        background,
        Rect.fromLTWH(
          0,
          0,
          background.width.toDouble(),
          background.height.toDouble(),
        ),
        Offset.zero & Size(w, h),
        p,
      );
    } else {
      canvas.drawRect(
        Offset.zero & Size(w, h),
        p..color = const Color(0xFF102C43),
      );
    }
    canvas.drawRect(
      Offset.zero & Size(w, h),
      p
        ..shader = const LinearGradient(
          colors: [Color(0x22061A30), Color(0x55030B15)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & Size(w, h)),
    );
    _gate(canvas, w, h);
    _armyDraw(canvas, w, h, _army, false);
    if (_phase == RunPhase.encounter || _phase == RunPhase.finalBattle) {
      _armyDraw(canvas, w, h, _enemy, true);
      _effects(canvas, w, h);
    }
    if (_phase == RunPhase.result) {
      canvas.drawRect(
        Offset.zero & Size(w, h),
        p
          ..style = PaintingStyle.fill
          ..color = const Color(0xAA06101D),
      );
    }
  }

  void _armyDraw(Canvas c, double w, double h, int count, bool enemy) {
    final shown = math.min(count, enemy ? 90 : 110),
        base = enemy ? h * .28 : h * .8;
    final p = Paint();
    for (var i = 0; i < shown; i++) {
      final row = i ~/ 10,
          col = i % 10,
          spread = (row + 1) * (enemy ? 5.0 : 6.0),
          x =
              w * .5 +
              (col - 4.5) * spread +
              (_random.nextDouble() - .5) * 5 +
              _lane * w * .25 * (enemy ? .5 : 1),
          y = base + row * (enemy ? 8 : 9),
          s = enemy ? 1 - row * .018 : 1 - row * .012;
      final type = enemy ? UnitType.militia : _unitForIndex(i);
      final body = enemy ? const Color(0xFF35454B) : _bodyColor(type);
      p.color = body;
      c.drawCircle(Offset(x, y), 6 * s, p);
      p.color = enemy ? const Color(0xFF9DB0B9) : _headColor(type);
      c.drawCircle(Offset(x, y - 5 * s), 3.2 * s, p);
      c.drawRect(
        Rect.fromCenter(center: Offset(x, y + 3), width: 5 * s, height: 8 * s),
        p,
      );
    }
  }

  UnitType _unitForIndex(int index) {
    if (index < _knights) return UnitType.knight;
    if (index < _knights + _swordsmen) return UnitType.swordsman;
    if (index < _knights + _swordsmen + _archers) return UnitType.archer;
    return UnitType.militia;
  }

  Color _bodyColor(UnitType type) => switch (type) {
    UnitType.knight => const Color(0xFFB34C72),
    UnitType.swordsman => const Color(0xFF3D78A8),
    UnitType.archer => const Color(0xFF4D946B),
    UnitType.militia => const Color(0xFF78664B),
  };

  Color _headColor(UnitType type) => switch (type) {
    UnitType.knight => const Color(0xFFFFD166),
    UnitType.swordsman => const Color(0xFFD8E9F1),
    UnitType.archer => const Color(0xFFBEE8B2),
    UnitType.militia => const Color(0xFFE1B35A),
  };

  void _gate(Canvas c, double w, double h) {
    if (_phase != RunPhase.gate) return;
    final p = Paint();
    for (var i = 0; i < 2; i++) {
      final x = i == 0 ? w * .26 : w * .74;
      p.color = const Color(0xCC1976B8);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, h * .56),
            width: w * .35,
            height: 70,
          ),
          const Radius.circular(10),
        ),
        p,
      );
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFBCEBFF);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, h * .56),
            width: w * .31,
            height: 62,
          ),
          const Radius.circular(8),
        ),
        p,
      );
    }
  }

  void _effects(Canvas c, double w, double h) {
    final p = Paint()
      ..strokeWidth = 3
      ..color = const Color(0xFFFFC34F);
    for (var i = 0; i < 5; i++) {
      final x = w * (.2 + i * .15);
      c.drawLine(Offset(x, h * .42), Offset(x + 12, h * .35), p);
    }
  }
}

class LegionSnapshot {
  final RunPhase phase;
  final int army, enemy, maxArmy, defeated;
  final double stageDistance;
  final String message;
  final int gateCount, militia, swordsmen, archers, knights;
  const LegionSnapshot({
    required this.phase,
    required this.army,
    required this.enemy,
    required this.message,
    required this.stageDistance,
    this.gateCount = 0,
    this.militia = 0,
    this.swordsmen = 0,
    this.archers = 0,
    this.knights = 0,
    this.maxArmy = 10,
    this.defeated = 0,
  });
}
