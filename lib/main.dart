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
    return Stack(
      children: [
        Positioned(
          top: 14,
          left: 12,
          right: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              badge('STAGE 1-1', Icons.flag),
              badge('⚔ ${state.army}', Icons.groups),
              badge('☠ ${state.enemy}', Icons.warning_amber),
            ],
          ),
        ),
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
            bottom: 112,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                gateButton('+10', '민병대', () => game.chooseGate(0)),
                gateButton('×2', '군단 증원', () => game.chooseGate(1)),
              ],
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
  Widget gateButton(String title, String subtitle, VoidCallback onPressed) =>
      SizedBox(
        width: 150,
        child: FilledButton.tonal(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xDD1976B8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(subtitle),
            ],
          ),
        ),
      );
}
