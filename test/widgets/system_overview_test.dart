import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parov/models/steam_simulation.dart';
import 'package:parov/widgets/system_overview.dart';

void main() {
  testWidgets('horizontal diagram rows scroll independently without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(1030, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final simulation = SteamSimulation();
    addTearDown(simulation.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SystemOverview(simulation: simulation),
        ),
      ),
    );

    final horizontalScrollViews = find.byWidgetPredicate(
      (widget) =>
          widget is SingleChildScrollView &&
          widget.scrollDirection == Axis.horizontal,
    );

    expect(horizontalScrollViews, findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
