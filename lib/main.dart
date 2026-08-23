import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/legion_game.dart';

void main() => runApp(const LegionApp());

class LegionApp extends StatelessWidget {
  const LegionApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Legion Runners',
    theme: ThemeData.dark(useMaterial3: true),
    home: const LegionPage(),
  );
}

class LegionPage extends StatefulWidget {
  const LegionPage({super.key});
  @override
  State<LegionPage> createState() => _LegionPageState();
}

class _LegionPageState extends State<LegionPage> {
  final game = LegionGame();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: GestureDetector(
        onHorizontalDragUpdate: (d) => game.moveBy(d.delta.dx),
        child: Stack(
          children: [
            Positioned.fill(child: GameWidget(game: game)),
            ValueListenableBuilder<LegionSnapshot>(
              valueListenable: game.snapshot,
              builder: (context, state, child) => Hud(game: game, state: state),
            ),
          ],
        ),
      ),
    ),
  );
}

class Hud extends StatelessWidget {
  final LegionGame game;
  final LegionSnapshot state;
  const Hud({super.key, required this.game, required this.state});
  @override
  Widget build(BuildContext context) {
    final gate = state.phase == RunPhase.gate;
    final result = state.phase == RunPhase.result;
    final event = state.phase == RunPhase.event;
    final combat =
        (state.phase == RunPhase.encounter ||
        state.phase == RunPhase.finalBattle);
    return Stack(
      children: [
        Positioned(top: 12, left: 12, right: 12, child: _topBar(state)),
        Positioned(
          top: 67,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              state.message,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (gate)
          Positioned(
            left: 0,
            right: 0,
            bottom: 126,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: state.gateCount == 0
                  ? [
                      gateButton('+10', '민병대', () => game.chooseGate(0)),
                      gateButton('×2', '군단 증원', () => game.chooseGate(1)),
                    ]
                  : [
                      gateButton(
                        '+30',
                        '검사',
                        () => game.chooseGate(0),
                        compact: true,
                      ),
                      gateButton(
                        '+10',
                        '궁수',
                        () => game.chooseGate(1),
                        compact: true,
                      ),
                      gateButton(
                        '+10',
                        '기사',
                        () => game.chooseGate(2),
                        compact: true,
                      ),
                    ],
            ),
          ),
        if (combat)
          Positioned(right: 16, bottom: 28, child: _heroSkillButton(state)),
        if (gate)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 92,
            child: Center(
              child: Text(
                'GATE 선택  •  좌우로 드래그하여 다음 전장을 준비하세요',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  letterSpacing: .2,
                ),
              ),
            ),
          ),
        if (event)
          Positioned.fill(
            child: Center(
              child: Card(
                color: const Color(0xF0112235),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0x99D6A84C)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '운명의 선택!',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFD166),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.event.prompt,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 14),
                      ...List.generate(state.event.choices.length, (index) {
                        final choice = state.event.choices[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: 290,
                            child: OutlinedButton(
                              onPressed: () => game.chooseEvent(index),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0x8896CBEA),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    choice.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    choice.detail,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (result)
          Positioned.fill(
            child: Center(
              child: Card(
                color: const Color(0xEE11263A),
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.army > 0 ? 'VICTORY!' : 'DEFEAT',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFD166),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '최종 생존자  ${state.army}\n최대 병력  ${state.maxArmy}\n처치한 좀비  ${state.defeated}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, height: 1.8),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: game.restart,
                        child: const Text('다음 출정'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _topBar(LegionSnapshot state) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          badge('STAGE 1-1', Icons.flag),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xDD0A1728),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x66E6B65A)),
            ),
            child: const Text(
              '인간 연합  •  RUN 01',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFFD166),
              ),
            ),
          ),
          badge('Ⅱ  일시정지', Icons.pause),
        ],
      ),
      const SizedBox(height: 9),
      Row(
        children: [
          Expanded(
            child: _statCard(
              Icons.groups,
              '인간 군단',
              state.army,
              const Color(0xFFE7B95E),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statCard(
              Icons.warning_amber,
              '${enemyName(state.enemyType)} 군단',
              state.enemy,
              const Color(0xFFB9D3D7),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _unitLine(state),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: LinearProgressIndicator(
          value: (state.stageDistance / 2.4).clamp(0, 1),
          minHeight: 4,
          backgroundColor: const Color(0x553E5368),
          color: const Color(0xFFE6B65A),
        ),
      ),
    ],
  );

  Widget _statCard(IconData icon, String label, int value, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xC9101F31),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      );

  Widget _unitLine(LegionSnapshot state) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _unitChip('민병대', state.militia, const Color(0xFFE1B35A)),
        _unitChip('검사', state.swordsmen, const Color(0xFF72B7EB)),
        _unitChip('궁수', state.archers, const Color(0xFF8BD6A3)),
        _unitChip('기사', state.knights, const Color(0xFFFF739F)),
      ],
    ),
  );

  String enemyName(EnemyType type) => switch (type) {
    EnemyType.zombie => '좀비',
    EnemyType.skeleton => '스켈레톤',
    EnemyType.ghoul => '구울',
    EnemyType.undeadKnight => '언데드 기사',
    EnemyType.necromancer => '네크로맨서',
  };

  Widget _unitChip(String label, int value, Color color) => Container(
    margin: const EdgeInsets.only(right: 5),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xAA071525),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: .45)),
    ),
    child: Text(
      '$label  $value',
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
    ),
  );

  Widget _heroSkillButton(LegionSnapshot state) {
    final ready = state.heroCooldown <= 0;
    return GestureDetector(
      onTap: ready ? game.useHeroSkill : null,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ready ? const Color(0xFFB85B42) : const Color(0xCC26364A),
          border: Border.all(
            color: ready ? const Color(0xFFFFD166) : Colors.white24,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: ready ? const Color(0x99FF9C5C) : Colors.transparent,
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              ready ? Icons.flash_on : Icons.hourglass_top,
              color: const Color(0xFFFFE7A7),
              size: 25,
            ),
            Text(
              ready ? '돌격' : '${state.heroCooldown.ceil()}s',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const Text(
              '기사단장',
              style: TextStyle(fontSize: 9, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget badge(String text, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xCC0D2135),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x557FB5D5)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFFFFD166)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
  Widget gateButton(
    String title,
    String subtitle,
    VoidCallback onPressed, {
    bool compact = false,
  }) => SizedBox(
    width: compact ? 116 : 150,
    child: FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xEE116DAD),
        foregroundColor: Colors.white,
        elevation: 10,
        shadowColor: const Color(0xFF36BFFF),
        side: const BorderSide(color: Color(0xFF8FDEFF), width: 1.5),
        padding: EdgeInsets.symmetric(vertical: compact ? 11 : 13),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          Text(subtitle),
        ],
      ),
    ),
  );
}
