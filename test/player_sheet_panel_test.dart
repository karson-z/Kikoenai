import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/widgets/slider/player_sheet_panel.dart';

void main() {
  testWidgets('hidden player panel is not built or included in layout', (
    tester,
  ) async {
    var panelBuildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerSheetPanel(
            showPanel: false,
            minHeight: 75,
            maxHeight: 600,
            bottomNavBarHeight: 80,
            body: const SizedBox.expand(key: Key('body')),
            bottomNavBar: const SizedBox(
              key: Key('bottom-navigation'),
              height: 80,
            ),
            panelBuilder: (_, _) {
              panelBuildCount++;
              return const SizedBox(key: Key('player-panel'));
            },
          ),
        ),
      ),
    );

    expect(panelBuildCount, 0);
    expect(find.byKey(const Key('player-panel')), findsNothing);
    expect(
      tester.getBottomRight(find.byKey(const Key('body'))).dy,
      tester.getTopLeft(find.byKey(const Key('bottom-navigation'))).dy,
    );
  });

  testWidgets('hiding an expanded panel resets it before it reappears', (
    tester,
  ) async {
    final controller = PanelController();
    late StateSetter setState;
    var showPanel = true;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, updateState) {
            setState = updateState;
            return PlayerSheetPanel(
              controller: controller,
              showPanel: showPanel,
              minHeight: 75,
              maxHeight: 600,
              panelBuilder: (_, _) => const SizedBox(key: Key('player-panel')),
            );
          },
        ),
      ),
    );

    controller.panelPosition = 1.0;
    expect(controller.isPanelOpen, isTrue);

    setState(() => showPanel = false);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('player-panel')), findsNothing);
    expect(controller.isPanelClosed, isTrue);

    setState(() => showPanel = true);
    await tester.pump();

    expect(find.byKey(const Key('player-panel')), findsOneWidget);
    expect(controller.isPanelClosed, isTrue);
  });

  testWidgets('bottom navigation ignores the iOS top safe area', (
    tester,
  ) async {
    const topInset = 47.0;
    const bottomInset = 34.0;
    const navigationContentHeight = 68.0;
    const navigationHeight = navigationContentHeight + bottomInset;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
            viewPadding: EdgeInsets.only(
              top: topInset,
              bottom: bottomInset,
            ),
          ),
          child: Scaffold(
            body: PlayerSheetPanel(
              showPanel: false,
              minHeight: 75,
              maxHeight: 600,
              bottomNavBarHeight: navigationHeight,
              body: const SizedBox.expand(key: Key('body')),
              bottomNavBar: RepaintBoundary(
                key: const Key('bottom-navigation'),
                child: NavigationBar(
                  height: navigationContentHeight,
                  maintainBottomViewPadding: true,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
              panelBuilder: (_, _) => const SizedBox(
                key: Key('player-panel'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('bottom-navigation'))).height,
      navigationHeight,
    );
    expect(
      tester.getBottomRight(find.byKey(const Key('body'))).dy,
      tester.getTopLeft(find.byKey(const Key('bottom-navigation'))).dy,
    );
  });
}
