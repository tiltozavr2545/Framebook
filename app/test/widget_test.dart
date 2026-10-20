import 'package:flutter_test/flutter_test.dart';

import 'package:framebook/main.dart';

void main() {
  testWidgets('app starts', (tester) async {
    await tester.pumpWidget(const FramebookApp());

    expect(find.text('Framebook'), findsOneWidget);
  });
}
