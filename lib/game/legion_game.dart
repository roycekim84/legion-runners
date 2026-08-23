import 'dart:math' as math;
import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

enum RunPhase { gate, encounter, finalBattle, result }

class LegionGame extends FlameGame {
  final snapshot = ValueNotifier(
    const LegionSnapshot(
      phase: RunPhase.gate,
      army: 10,
      enemy: 20,
      message: '좌우로 드래그해 군단을 움직이세요',
      stageDistance: 0,
    ),
  );
  final _random = math.Random(7);
  double _lane = 0, _targetLane = 0, _distance = 0, _timer = 0;
  int _army = 10, _enemy = 20, _maxArmy = 10, _defeated = 0;
  RunPhase _phase = RunPhase.gate;
  String _message = '첫 번째 선택: 병력을 불리세요';

  @override
  Color backgroundColor() => const Color(0xFF071321);
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewport = FixedResolutionViewport(resolution: Vector2(390, 844));
  }

  void moveBy(double d) =>
      _targetLane = (_targetLane + d / 180).clamp(-1.0, 1.0);
  void chooseGate(int option) {
    if (_phase != RunPhase.gate) return;
    if (option == 0) {
      _army += 10;
      _message = '민병대 +10';
    } else {
      _army *= 2;
      _message = '군단 ×2';
    }
    _maxArmy = math.max(_maxArmy, _army);
    _phase = RunPhase.encounter;
    _enemy = _distance < 1 ? 20 : 80;
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
          (_army * (_phase == RunPhase.finalBattle ? .1 : .12)).round(),
        );
        _army = math.max(0, _army - loss);
        _enemy = math.max(0, _enemy - damage);
        _defeated += damage;
        if (_army == 0) {
          _finish(false);
        } else if (_enemy == 0 && _distance < 1.8) {
          _phase = RunPhase.gate;
          _message = '두 번째 선택: 기사 승급 또는 병력 보충';
          _enemy = 80;
        } else if (_enemy == 0) {
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
  );

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = canvasSize.x, h = canvasSize.y;
    final p = Paint();
    canvas.drawRect(
      Offset.zero & Size(w, h),
      p
        ..shader = const LinearGradient(
          colors: [Color(0xFF18304A), Color(0xFF071321)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & Size(w, h)),
    );
    final road = Path()
      ..moveTo(w * .43, h * .12)
      ..lineTo(w * .57, h * .12)
      ..lineTo(w * .94, h)
      ..lineTo(w * .06, h)
      ..close();
    canvas.drawPath(
      road,
      p
        ..shader = null
        ..color = const Color(0xFF243A4A),
    );
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF426176);
    canvas.drawLine(Offset(w * .43, h * .12), Offset(w * .06, h), p);
    canvas.drawLine(Offset(w * .57, h * .12), Offset(w * .94, h), p);
    for (var i = 0; i < 8; i++) {
      final y = h * (.16 + i * .1), t = (y - h * .12) / (h * .88);
      canvas.drawLine(
        Offset(w * (.43 - .37 * t), y),
        Offset(w * (.57 + .37 * t), y),
        p..color = const Color(0x334E7084),
      );
    }
    _castle(canvas, w * .5, h * .13);
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
      p.color = enemy ? const Color(0xFF35454B) : const Color(0xFF2C4E72);
      c.drawCircle(Offset(x, y), 6 * s, p);
      p.color = enemy ? const Color(0xFF9DB0B9) : const Color(0xFFE1B35A);
      c.drawCircle(Offset(x, y - 5 * s), 3.2 * s, p);
      c.drawRect(
        Rect.fromCenter(center: Offset(x, y + 3), width: 5 * s, height: 8 * s),
        p,
      );
    }
  }

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

  void _castle(Canvas c, double x, double y) {
    final p = Paint()..color = const Color(0xFFB3C0CE);
    c.drawRect(
      Rect.fromCenter(center: Offset(x, y + 16), width: 48, height: 30),
      p,
    );
    c.drawRect(
      Rect.fromCenter(center: Offset(x - 20, y + 5), width: 14, height: 45),
      p,
    );
    c.drawRect(
      Rect.fromCenter(center: Offset(x + 20, y + 5), width: 14, height: 45),
      p,
    );
    p.color = const Color(0xFF8A2840);
    c.drawCircle(Offset(x, y + 24), 6, p);
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
  const LegionSnapshot({
    required this.phase,
    required this.army,
    required this.enemy,
    required this.message,
    required this.stageDistance,
    this.maxArmy = 10,
    this.defeated = 0,
  });
}
