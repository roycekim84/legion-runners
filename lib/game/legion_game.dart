import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'stage_data.dart';

enum RunPhase { gate, encounter, event, finalBattle, result }

enum UnitType { militia, swordsman, archer, knight }

enum EnemyType { zombie, skeleton, ghoul, undeadKnight, necromancer }

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
      enemyType: EnemyType.zombie,
      heroCooldown: 0,
      event: stageOneEvent,
    ),
  );
  final _random = math.Random(7);
  final List<CombatFx> _combatFx = [];
  final List<Projectile> _projectiles = [];
  ui.Image? _background;
  ui.Image? _humanSheet;
  ui.Image? _undeadSheet;
  ui.Image? _humanWalkSheet;
  ui.Image? _undeadWalkSheet;
  double _lane = 0, _targetLane = 0, _distance = 0, _timer = 0;
  double _summonTimer = 0,
      _knockback = 0,
      _enemyHitFlash = 0,
      _playerHitFlash = 0,
      _heroCooldown = 0,
      _approach = 0,
      _walkClock = 0;
  int _army = 10, _enemy = 20, _maxArmy = 10, _defeated = 0;
  int _gateCount = 0, _militia = 10, _swordsmen = 0, _archers = 0, _knights = 0;
  EnemyType _enemyType = EnemyType.zombie;
  EventDefinition _event = stageOneEvent;
  double _powerMultiplier = 1;
  RunPhase _phase = RunPhase.gate;
  String _message = '첫 번째 선택: 병력을 불리세요';

  @override
  Color backgroundColor() => const Color(0xFF071321);
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    images.prefix = 'assets/art/';
    _background = await images.load('battlefield.png');
    _humanSheet = await images.load('human_units_sheet.png');
    _undeadSheet = await images.load('undead_units_sheet.png');
    _humanWalkSheet = await images.load('human_walk_sheet.png');
    _undeadWalkSheet = await images.load('undead_walk_sheet.png');
    camera.viewport = FixedResolutionViewport(resolution: Vector2(390, 844));
  }

  void moveBy(double d) =>
      _targetLane = (_targetLane + d / 180).clamp(-1.0, 1.0);

  void useHeroSkill() {
    if (_phase == RunPhase.gate ||
        _phase == RunPhase.result ||
        _heroCooldown > 0) {
      return;
    }
    _heroCooldown = 8;
    final damage = math.min(_enemy, math.max(12, (_armyPower * .28).round()));
    _enemy = math.max(0, _enemy - damage);
    _defeated += damage;
    _knockback = 1;
    _message = '기사단장 돌격! 적 $damage마리 격퇴';
    _combatFx.add(CombatFx.heroCharge(x: .5, y: .65));
    if (_enemy == 0 && _gateCount >= 2) _finish(true);
    _publish();
  }

  void chooseEvent(int option) {
    if (_phase != RunPhase.event) return;
    if (option == 0) {
      _army += 25;
      _militia += 25;
      _message = '난민을 구출했습니다. 민병대 +25';
    } else if (option == 1) {
      _army += 15;
      _swordsmen += 15;
      _message = '무기고를 확보했습니다. 검사 +15';
    } else {
      _army = math.max(1, (_army * .9).round());
      _powerMultiplier += .4;
      _message = '저주받은 성배의 힘이 깃듭니다. 공격력 +40%';
    }
    _maxArmy = math.max(_maxArmy, _army);
    _phase = RunPhase.finalBattle;
    _approach = 0;
    _enemy = 150;
    _enemyType = EnemyType.undeadKnight;
    _publish();
  }

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
    _approach = 0;
    _enemy = _gateCount == 1 ? 20 : 80;
    _enemyType = _gateCount == 1 ? EnemyType.zombie : EnemyType.skeleton;
    _publish();
  }

  void restart() {
    _lane = 0;
    _targetLane = 0;
    _distance = 0;
    _timer = 0;
    _summonTimer = 0;
    _knockback = 0;
    _enemyHitFlash = 0;
    _playerHitFlash = 0;
    _heroCooldown = 0;
    _approach = 0;
    _walkClock = 0;
    _powerMultiplier = 1;
    _army = 10;
    _enemy = 20;
    _maxArmy = 10;
    _defeated = 0;
    _gateCount = 0;
    _militia = 10;
    _swordsmen = 0;
    _archers = 0;
    _knights = 0;
    _enemyType = EnemyType.zombie;
    _event = stageOneEvent;
    _combatFx.clear();
    _projectiles.clear();
    _phase = RunPhase.gate;
    _message = '첫 번째 선택: 병력을 불리세요';
    _publish();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lane += (_targetLane - _lane) * math.min(1, dt * 7);
    _knockback = math.max(0, _knockback - dt * 2.4);
    _enemyHitFlash = math.max(0, _enemyHitFlash - dt * 4);
    _playerHitFlash = math.max(0, _playerHitFlash - dt * 4);
    _heroCooldown = math.max(0, _heroCooldown - dt);
    _walkClock += dt;
    for (final projectile in _projectiles) {
      projectile.y -= projectile.speed * dt;
      projectile.life -= dt;
    }
    final hits = _projectiles
        .where((p) => p.y <= p.targetY && p.life > 0)
        .toList();
    _projectiles.removeWhere((p) => p.life <= 0 || p.y <= p.targetY);
    for (final projectile in hits) {
      final damage = math.min(_enemy, projectile.damage);
      _enemy = math.max(0, _enemy - damage);
      _defeated += damage;
      _knockback = math.min(1, _knockback + .25);
      _enemyHitFlash = .3;
      _combatFx.add(CombatFx.hit(x: projectile.x, y: projectile.targetY));
      if (_enemy == 0) _handleEnemyCleared();
    }
    for (final fx in _combatFx) {
      fx.life -= dt;
    }
    _combatFx.removeWhere((fx) => fx.life <= 0);
    if (_phase == RunPhase.result) return;
    if (_phase != RunPhase.encounter && _phase != RunPhase.finalBattle) {
      _publish();
      return;
    }
    _distance += dt * .12;
    if (_phase == RunPhase.encounter || _phase == RunPhase.finalBattle) {
      _approach = math.min(1, _approach + dt * .045);
      if (_phase == RunPhase.finalBattle) {
        _summonTimer += dt;
        if (_summonTimer > 5.0) {
          _summonTimer = 0;
          _enemy += 15;
          _message = '네크로맨서가 좀비 15마리를 소환했습니다!';
          _combatFx.add(CombatFx.summon(x: .5, y: .28));
        }
      }
      _timer += dt;
      final cadence = _phase == RunPhase.finalBattle ? 1.7 : 2.2;
      if (_timer > cadence) {
        _timer = 0;
        final contact = _inContact;
        final loss = contact
            ? math.max(1, (_enemy * _enemyPressure).round())
            : 0;
        final chargeBonus = contact && _knights > 0 ? 1.35 : 1.0;
        final damage = math.max(
          0,
          (_meleePower *
                  _powerMultiplier *
                  chargeBonus *
                  (contact ? 1 : 0) *
                  (_phase == RunPhase.finalBattle ? .1 : .12))
              .round(),
        );
        _army = math.max(0, _army - loss);
        _enemy = math.max(0, _enemy - damage);
        _defeated += damage;
        if (loss > 0) _playerHitFlash = .3;
        _spawnCombatFx(contact: contact);
        _spawnProjectiles();
        if (_army == 0) {
          _finish(false);
        } else if (_enemy == 0) {
          _handleEnemyCleared();
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
    enemyType: _enemyType,
    heroCooldown: _heroCooldown,
    event: _event,
  );

  double get _armyPower =>
      _militia + _swordsmen * 1.2 + _archers * 1.35 + _knights * 2.1;

  double get _meleePower => _militia + _swordsmen * 1.2 + _knights * 2.1;

  bool get _inContact => _approach > .62;

  void _handleEnemyCleared() {
    _projectiles.clear();
    if (_gateCount == 1) {
      _phase = RunPhase.gate;
      _message = '두 번째 선택: 검사·궁수·기사 편성';
      _enemy = 80;
    } else if (_gateCount >= 2) {
      _phase = RunPhase.event;
      _event = stageOneEvent;
      _message = _event.title;
    }
  }

  double get _enemyPressure => switch (_enemyType) {
    EnemyType.zombie => _phase == RunPhase.finalBattle ? .045 : .07,
    EnemyType.skeleton => .085,
    EnemyType.ghoul => .12,
    EnemyType.undeadKnight => .065,
    EnemyType.necromancer => .04,
  };

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
    _drawHero(canvas, w, h);
    if (_phase == RunPhase.encounter || _phase == RunPhase.finalBattle) {
      _armyDraw(canvas, w, h, _enemy, true);
      _hitFlash(canvas, w, h);
      _renderCombatFx(canvas, w, h);
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
        base = enemy
            ? h * (.28 + _approach * .28 - _knockback * .035)
            : h * (.8 - _approach * .12);
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
      final enemyType = enemy ? _enemyForIndex(i) : null;
      final body = enemy ? _enemyBodyColor(enemyType!) : _bodyColor(type);
      final spriteIndex = enemy
          ? _enemySpriteIndex(enemyType!)
          : _unitSpriteIndex(type);
      final sheet = enemy
          ? (_undeadWalkSheet ?? _undeadSheet)
          : (_humanWalkSheet ?? _humanSheet);
      if (sheet != null) {
        final columns = 4;
        final rows = enemy ? 5 : 4;
        final frame = (_walkClock * 7).floor() % columns;
        final sourceWidth = sheet.width / columns;
        final sourceHeight = sheet.height / rows;
        final source = Rect.fromLTWH(
          frame * sourceWidth,
          spriteIndex * sourceHeight,
          sourceWidth,
          sourceHeight,
        );
        final destination = Rect.fromCenter(
          center: Offset(x, y - 17 * s),
          width: 34 * s,
          height: 58 * s,
        );
        c.drawImageRect(
          sheet,
          source,
          destination,
          p..filterQuality = FilterQuality.low,
        );
        continue;
      }
      p.color = body;
      c.drawCircle(Offset(x, y), 6 * s, p);
      p.color = enemy ? _enemyHeadColor(enemyType!) : _headColor(type);
      c.drawCircle(Offset(x, y - 5 * s), 3.2 * s, p);
      c.drawRect(
        Rect.fromCenter(center: Offset(x, y + 3), width: 5 * s, height: 8 * s),
        p,
      );
    }
  }

  void _drawHero(Canvas c, double w, double h) {
    final x = w * .5 + _lane * w * .25;
    final y = h * .88;
    final p = Paint()..color = const Color(0xFF163B63);
    c.drawCircle(Offset(x, y), 14, p);
    p.color = const Color(0xFFFFD166);
    c.drawCircle(Offset(x, y - 12), 5, p);
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFFFE9A6);
    c.drawCircle(Offset(x, y - 12), 8, p);
  }

  EnemyType _enemyForIndex(int index) {
    if (_phase == RunPhase.finalBattle) {
      if (index % 7 == 0) return EnemyType.undeadKnight;
      if (index % 11 == 0) return EnemyType.necromancer;
      if (index % 4 == 0) return EnemyType.ghoul;
      if (index % 3 == 0) return EnemyType.skeleton;
    }
    return _enemyType;
  }

  Color _enemyBodyColor(EnemyType type) => switch (type) {
    EnemyType.zombie => const Color(0xFF556A61),
    EnemyType.skeleton => const Color(0xFF8F9DA0),
    EnemyType.ghoul => const Color(0xFF7D4F88),
    EnemyType.undeadKnight => const Color(0xFF393F69),
    EnemyType.necromancer => const Color(0xFF542A78),
  };

  Color _enemyHeadColor(EnemyType type) => switch (type) {
    EnemyType.zombie => const Color(0xFFB8C3A9),
    EnemyType.skeleton => const Color(0xFFE3E4D0),
    EnemyType.ghoul => const Color(0xFFDB8EBA),
    EnemyType.undeadKnight => const Color(0xFFFF647C),
    EnemyType.necromancer => const Color(0xFFDC66FF),
  };

  int _unitSpriteIndex(UnitType type) => switch (type) {
    UnitType.militia => 0,
    UnitType.swordsman => 1,
    UnitType.archer => 2,
    UnitType.knight => 3,
  };

  int _enemySpriteIndex(EnemyType type) => switch (type) {
    EnemyType.zombie => 0,
    EnemyType.skeleton => 1,
    EnemyType.ghoul => 2,
    EnemyType.undeadKnight => 3,
    EnemyType.necromancer => 4,
  };

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

  void _spawnCombatFx({required bool contact}) {
    if (!contact) return;
    _knockback = math.min(1, _knockback + .75);
    if (_swordsmen > 0) {
      _combatFx.add(CombatFx.slash(x: .42, y: .42));
      _combatFx.add(CombatFx.slash(x: .58, y: .45));
    }
    if (_knights > 0) _combatFx.add(CombatFx.charge(x: .5, y: .66));
    _combatFx.add(CombatFx.hit(x: .5, y: .38));
    _combatFx.add(CombatFx.knockback(x: .5, y: .38));
  }

  void _hitFlash(Canvas c, double w, double h) {
    final p = Paint()..style = PaintingStyle.fill;
    if (_enemyHitFlash > 0) {
      p.color = const Color(0xFFFFB347).withValues(alpha: _enemyHitFlash);
      c.drawCircle(Offset(w * .5, h * (.38 - _knockback * .035)), 20, p);
    }
    if (_playerHitFlash > 0) {
      p.color = const Color(0xFFFF647C).withValues(alpha: _playerHitFlash);
      c.drawCircle(Offset(w * .5, h * (.8 - _approach * .12)), 24, p);
    }
  }

  void _spawnProjectiles() {
    if (_archers == 0) return;
    final count = math.min(4, (_archers / 4).ceil());
    for (var i = 0; i < count; i++) {
      _projectiles.add(
        Projectile(
          x: .38 + i * .08,
          y: .72,
          damage: math.max(1, (_archers * .04).round()),
        ),
      );
    }
  }

  void _renderCombatFx(Canvas c, double w, double h) {
    for (final fx in _combatFx) {
      final progress = 1 - fx.life / fx.maxLife;
      final x = (fx.x + fx.dx * progress) * w;
      final y = (fx.y + fx.dy * progress) * h;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = fx.kind == FxKind.arrow ? 2.5 : 3.5
        ..color = fx.color.withValues(
          alpha: (fx.life / fx.maxLife).clamp(0, 1),
        );
      if (fx.kind == FxKind.arrow) {
        c.drawLine(
          Offset(x - fx.dx * w * .06, y - fx.dy * h * .06),
          Offset(x, y),
          p,
        );
        p.style = PaintingStyle.fill;
        c.drawCircle(Offset(x, y), 2.5, p);
      } else if (fx.kind == FxKind.slash) {
        c.drawArc(
          Rect.fromCenter(center: Offset(x, y), width: 28, height: 20),
          -1.1,
          2.2,
          false,
          p,
        );
      } else if (fx.kind == FxKind.charge) {
        c.drawLine(Offset(x - 26, y + 20), Offset(x + 22, y - 18), p);
        c.drawCircle(Offset(x, y), 12 + progress * 10, p);
      } else if (fx.kind == FxKind.knockback) {
        c.drawLine(Offset(x - 20, y), Offset(x + 20, y - 8), p);
        c.drawLine(Offset(x - 12, y + 10), Offset(x + 12, y + 2), p);
      } else if (fx.kind == FxKind.summon) {
        p.style = PaintingStyle.fill;
        c.drawCircle(Offset(x, y), 7 + progress * 18, p);
        p.style = PaintingStyle.stroke;
        c.drawCircle(Offset(x, y), 18 + progress * 12, p);
      } else if (fx.kind == FxKind.heroCharge) {
        c.drawLine(Offset(x - 70, y + 28), Offset(x + 60, y - 34), p);
        c.drawCircle(Offset(x, y), 20 + progress * 28, p);
      } else {
        p.style = PaintingStyle.fill;
        c.drawCircle(Offset(x, y), 4 + progress * 16, p);
      }
    }
    for (final projectile in _projectiles) {
      final x = projectile.x * w;
      final y = projectile.y * h;
      final p = Paint()
        ..color = const Color(0xFFE8F5C2)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      c.drawLine(Offset(x - 7, y + 9), Offset(x, y), p);
      c.drawCircle(Offset(x, y), 2.5, p);
    }
  }
}

enum FxKind { arrow, slash, charge, hit, knockback, summon, heroCharge }

class Projectile {
  double x, y;
  final int damage;
  final double speed = .62;
  final double targetY = .38;
  double life = 2;
  Projectile({required this.x, required this.y, required this.damage});
}

class CombatFx {
  final FxKind kind;
  final double x, y, dx, dy, maxLife;
  final Color color;
  double life;
  CombatFx({
    required this.kind,
    required this.x,
    required this.y,
    this.dx = 0,
    this.dy = 0,
    required this.color,
    this.maxLife = .65,
  }) : life = maxLife;
  CombatFx.arrow({
    required double x,
    required double y,
    required double dx,
    required double dy,
  }) : this(
         kind: FxKind.arrow,
         x: x,
         y: y,
         dx: dx,
         dy: dy,
         color: const Color(0xFFE8F5C2),
         maxLife: .55,
       );
  CombatFx.slash({required double x, required double y})
    : this(
        kind: FxKind.slash,
        x: x,
        y: y,
        color: const Color(0xFFFFD166),
        maxLife: .35,
      );
  CombatFx.charge({required double x, required double y})
    : this(
        kind: FxKind.charge,
        x: x,
        y: y,
        dx: 0,
        dy: -.12,
        color: const Color(0xFFFF719D),
        maxLife: .75,
      );
  CombatFx.hit({required double x, required double y})
    : this(
        kind: FxKind.hit,
        x: x,
        y: y,
        color: const Color(0xFFFF8E5B),
        maxLife: .4,
      );
  CombatFx.knockback({required double x, required double y})
    : this(
        kind: FxKind.knockback,
        x: x,
        y: y,
        color: const Color(0xFFFFD166),
        maxLife: .45,
      );
  CombatFx.summon({required double x, required double y})
    : this(
        kind: FxKind.summon,
        x: x,
        y: y,
        color: const Color(0xFFDC66FF),
        maxLife: 1.0,
      );
  CombatFx.heroCharge({required double x, required double y})
    : this(
        kind: FxKind.heroCharge,
        x: x,
        y: y,
        dy: -.18,
        color: const Color(0xFFFFD166),
        maxLife: .9,
      );
}

class LegionSnapshot {
  final RunPhase phase;
  final int army, enemy, maxArmy, defeated;
  final double stageDistance;
  final String message;
  final int gateCount, militia, swordsmen, archers, knights;
  final EnemyType enemyType;
  final double heroCooldown;
  final EventDefinition event;
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
    this.enemyType = EnemyType.zombie,
    this.heroCooldown = 0,
    this.event = stageOneEvent,
    this.maxArmy = 10,
    this.defeated = 0,
  });
}
