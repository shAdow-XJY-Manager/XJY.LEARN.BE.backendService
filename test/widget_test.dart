import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:backend_service/main.dart';

void main() {
  testWidgets(
    'native API console selects the real route and rejects invalid POST JSON before sending',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(
        MediaQuery.sizeOf(tester.element(find.byType(Scaffold))),
        const Size(1200, 900),
      );
      Future<void> tapVisible(Finder target) async {
        expect(target, findsOneWidget);
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        expect(target.hitTestable(), findsOneWidget);
        await tester.tap(target.hitTestable());
        await tester.pumpAndSettle();
      }

      expect(find.text('Response will appear here...'), findsOneWidget);
      await tapVisible(find.text('/api/novel'));
      await tapVisible(find.text('GET APIs'));
      await tapVisible(find.text('/getNovels'));
      final fields = find.byType(TextField);
      expect(
        tester.widget<TextField>(fields.at(0)).controller!.text,
        '/api/novel/getNovels',
      );
      await tester.enterText(fields.at(1), '{invalid JSON');
      await tapVisible(find.widgetWithText(ElevatedButton, 'POST'));
      expect(
        find.textContaining('Failed to connect: FormatException'),
        findsOneWidget,
      );
    },
  );
}
