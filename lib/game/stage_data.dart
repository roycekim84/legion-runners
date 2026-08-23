class GateDefinition {
  final String title;
  final String subtitle;
  const GateDefinition(this.title, this.subtitle);
}

class EventChoice {
  final String title;
  final String detail;
  const EventChoice(this.title, this.detail);
}

class EventDefinition {
  final String title;
  final String prompt;
  final List<EventChoice> choices;
  const EventDefinition(this.title, this.prompt, this.choices);
}

class StageDefinition {
  final int number;
  final String label;
  final String region;
  final int startingArmy;
  final List<GateDefinition> gates;
  final EventDefinition event;
  const StageDefinition({
    required this.number,
    required this.label,
    required this.region,
    required this.startingArmy,
    required this.gates,
    required this.event,
  });
}

const stageOneEvent = EventDefinition('운명의 선택!', '한 가지를 선택하세요', [
  EventChoice('난민 구출', '민병대 +25'),
  EventChoice('버려진 무기고', '검사 +15'),
  EventChoice('저주받은 성배', '공격력 +40%  •  병력 -10%'),
]);

const stageOne = StageDefinition(
  number: 1,
  label: '왕국의 관문',
  region: '폐허가 된 성채로',
  startingArmy: 10,
  gates: [GateDefinition('+10', '민병대'), GateDefinition('×2', '군단 증원')],
  event: stageOneEvent,
);

const stageCatalog = [stageOne];
