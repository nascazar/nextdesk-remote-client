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
      {Size size = const Size(460, 640), double scale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await (FontLoader('Manrope')..addFont(rootBundle.load('assets/Manrope-Variable.ttf'))).load();
    await tester.pumpWidget(MaterialApp(home: MediaQuery(
      data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: RepaintBoundary(key: const ValueKey('capture'),
        child: NextDeskHomePanel(code: code,
          status: const Text('Listo para recibir conexiones'),
          controls: TextButton(onPressed: () {}, child: const Text('Instalar'))))))));
    await tester.pumpAndSettle();
  }

  testWidgets('Copies the current code, updates it, and disables copy while unavailable', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboard = call.arguments['text'];
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await show(tester, controller);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
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
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
  });

  testWidgets('Clipboard failure permits manual selection without reporting success', (tester) async {
    final controller = TextEditingController(text: '123 456 789');
    addTearDown(controller.dispose);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (_) async => throw PlatformException(code: 'clipboard'));
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
        await tester.ensureVisible(find.text('Instalar'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (viewport.width == 460 && scale == 1) {
          await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 2000));
          await tester.pumpAndSettle();
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
}
