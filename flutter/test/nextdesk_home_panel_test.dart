import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/desktop/widgets/nextdesk_home_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> show(WidgetTester tester, TextEditingController code,
      {Size size = const Size(460, 640), double scale = 1, Widget? controls, bool frame = false}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await (FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/Manrope-Regular.ttf'))
      ..addFont(rootBundle.load('assets/Manrope-Semibold.ttf'))
      ..addFont(rootBundle.load('assets/Manrope-Bold.ttf'))).load();
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final panel = NextDeskHomePanel(code: code,
      status: const Text('Listo'),
      controls: controls ?? TextButton(onPressed: () {}, child: const Text('Instalar')));
    await tester.pumpWidget(MaterialApp(home: MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: RepaintBoundary(key: const ValueKey('capture'),
        child: frame ? Column(children: [
          SizedBox(height: 28, child: Row(children: [
            const SizedBox(width: 8), Image.asset('assets/icon.png', width: 16, height: 16),
            const Spacer(), const Icon(Icons.minimize, size: 16), const SizedBox(width: 16),
            const Icon(Icons.close, size: 16), const SizedBox(width: 8),
          ])),
          Expanded(child: panel),
        ]) : panel)))));
    await tester.pumpAndSettle();
  }

  testWidgets('Copies the current code, updates it, and disables copy while unavailable', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboard = call.arguments['text'];
      if (call.method == 'Clipboard.hasStrings') return {'value': false};
      if (call.method == 'LiveText.isLiveTextInputAvailable') return false;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await show(tester, controller);
    expect(tester.widget<FilledButton>(find.byWidgetPredicate((w) => w is FilledButton)).onPressed, isNull);
    controller.text = '123 456 789';
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copiar código'));
    await tester.pumpAndSettle();
    expect(clipboard, '123 456 789');
    expect(find.text('Código copiado'), findsOneWidget);
    controller.text = '987 654 321';
    await tester.pumpAndSettle();
    expect(find.text('Copiar código'), findsOneWidget);
    await tester.tap(find.text('Copiar código'));
    await tester.pumpAndSettle();
    expect(clipboard, '987 654 321');
    controller.text = '';
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byWidgetPredicate((w) => w is FilledButton)).onPressed, isNull);
  });

  testWidgets('Clipboard failure permits manual selection without reporting success', (tester) async {
    final controller = TextEditingController(text: '123 456 789');
    addTearDown(controller.dispose);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') throw PlatformException(code: 'clipboard');
      if (call.method == 'Clipboard.hasStrings') return {'value': false};
      if (call.method == 'LiveText.isLiveTextInputAvailable') return false;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await show(tester, controller);
    await tester.tap(find.text('Copiar código'));
    await tester.pumpAndSettle();
    expect(find.text('Código copiado'), findsNothing);
    expect(find.textContaining('No se pudo copiar'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
  });

  for (final viewport in [const Size(460, 640), const Size(320, 480)]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('Layout ${viewport.width} at text scale $scale stays scrollable', (tester) async {
        final controller = TextEditingController(text: '123 456 789');
        addTearDown(controller.dispose);
        await show(tester, controller, size: viewport, scale: scale);
        expect(tester.takeException(), isNull);
        expect(find.byWidgetPredicate((w) => w is Text &&
          w.textSpan?.toPlainText() == 'Powered by Nextcom de Costa Rica'), findsOneWidget);
        await tester.ensureVisible(find.text('Instalar'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

      });
    }
  }
  test('Window bounds include the actual frame and fit the available work area', () {
    expect(nextDeskFrameSize(content: const Size(460, 540), chrome: const Size(11, 38)), const Size(471, 590));
    expect(nextDeskFrameSize(content: const Size(900, 540), chrome: const Size(11, 38)), const Size(471, 590));
    expect(nextDeskFrameSize(content: const Size(460, 740), chrome: const Size(11, 38),
      workArea: const Size(1000, 680)), const Size(471, 656));
    expect(nextDeskFrameSize(content: const Size(460, 500), chrome: const Size(11, 38),
      workArea: const Size(420, 600)), const Size(396, 576));
  });

  for (final height in [600.0, 640.0]) {
    testWidgets('Complete frame with password and exit fits without scrolling at $height', (tester) async {
      final controller = TextEditingController(text: '123 456 789');
      final password = TextEditingController(text: 'demo123');
      addTearDown(controller.dispose);addTearDown(password.dispose);
      var refreshed = 0, edited = 0, exited = 0;
      await show(tester, controller, size: Size(460, height), frame: true,
        controls: Column(mainAxisSize: MainAxisSize.min, children: [
          NextDeskPasswordField(password: password, label: 'Contraseña de un solo uso', actions: [
            IconButton(tooltip: 'Renovar contraseña', onPressed: () => refreshed++, icon: const Icon(Icons.refresh, size: 20)),
            IconButton(tooltip: 'Editar contraseña', onPressed: () => edited++, icon: const Icon(Icons.edit_outlined, size: 20)),
          ]),
          NextDeskExitButton(onExit: () => exited++, label: 'Salir'),
        ]));
      expect(tester.takeException(), isNull);
      final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
      expect(scroll.position.maxScrollExtent, 0);
      expect(scroll.position.pixels, 0);
      final footer = find.byWidgetPredicate((w) => w is Text &&
        w.textSpan?.toPlainText() == 'Powered by Nextcom de Costa Rica');
      expect(tester.getTopLeft(footer).dy, greaterThan(tester.getBottomLeft(find.text('Salir')).dy));
      expect(tester.getBottomLeft(footer).dy, lessThanOrEqualTo(height - 12));
      expect(find.text('Soporte Remoto'), findsOneWidget);
      expect(find.text('REMOTE'), findsNothing);
      expect(tester.widget<TextFormField>(find.byType(TextFormField)).enabled, isNot(false));
      await tester.tap(find.byTooltip('Renovar contraseña'));await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Editar contraseña'));await tester.pumpAndSettle();
      await tester.tap(find.text('Salir'));await tester.pumpAndSettle();
      expect([refreshed, edited, exited], [1, 1, 1]);
      expect(tester.takeException(), isNull);
      if (height == 600) {
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('capture')));
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory('test-output').createSync(recursive: true);
          File('test-output/nextdesk-remote-interface.png').writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }

}
