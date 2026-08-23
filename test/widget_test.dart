import 'package:flutter_test/flutter_test.dart';
import 'package:legion_runners/main.dart';

void main() {
  testWidgets('shows the first gate and army', (tester) async {
    await tester.pumpWidget(const LegionApp());
    expect(find.text('STAGE 1-1'), findsOneWidget);
    expect(find.text('+10'), findsOneWidget);
    expect(find.text('×2'), findsOneWidget);
  });
}
