import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:folio/main.dart';

void main() {
  testWidgets('folio app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FolioApp()));
    expect(find.text('folio'), findsNothing);
  });
}
