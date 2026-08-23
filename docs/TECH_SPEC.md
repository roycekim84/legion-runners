# Technical Spec

## 스택
- Flutter 3.44 / Dart 3.12
- Flame 1.31
- Web 우선 테스트, iOS/Android 세로 화면

## 구조
`LegionPage`는 HUD와 `GameWidget`을 조합한다. `LegionGame`은 시간 진행, 입력 대상 lane, 전투 수치와 렌더링을 담당한다. `LegionSnapshot`은 게임 데이터와 Flutter UI 사이의 읽기 전용 상태 경계다.

## 2.5D
실제 좌표는 lane과 진행 거리만 사용한다. 도로는 사다리꼴로 그려 원근감을 만들고, 군단은 행 번호에 따라 간격·스케일을 줄인다. 실제 army 수는 표시 수(플레이어 110, 적 90)와 분리한다.

## 성능 원칙
표시 개체 상한, 단순 원/사각형 스프라이트, 군단 단위 전투 tick, 향후 Object Pool과 SpriteBatch를 적용한다.

## 데이터화 방향
`data/` 아래 JSON 또는 Dart immutable definition으로 unit, enemy, gate, stage, race, hero를 정의하고 시스템은 정의를 읽어 실행한다.
