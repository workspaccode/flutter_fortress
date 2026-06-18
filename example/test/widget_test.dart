import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_fortress_example/main.dart';

void main() {
  testWidgets('Example app renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FortressExampleApp(threatLog: []));

    expect(find.text('Flutter Fortress Demo'), findsOneWidget);
  });
}
