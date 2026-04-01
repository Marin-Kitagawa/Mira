import 'package:flutter_test/flutter_test.dart';
import 'package:mira/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MiraApp());
    expect(find.text('Mira'), findsWidgets);
  });
}
