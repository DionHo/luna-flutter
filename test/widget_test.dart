import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luna_flutter/app.dart';

void main() {
  testWidgets('LunaApp renders a MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LunaApp()));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
