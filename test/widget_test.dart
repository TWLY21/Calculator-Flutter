import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_calculator_app/main.dart';

void main() {
  testWidgets('Calculator screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const CalculatorApp());

    expect(find.text('Calculator'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
  });
}
