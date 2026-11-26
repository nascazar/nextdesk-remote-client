import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Sizes the outer window from its complete content and measured frame insets.
Size nextDeskFrameSize({required Size content, required Size chrome, Size? workArea}) {
  final width = 460.0 + chrome.width;
  final height = math.max(540.0, content.height + 12) + chrome.height;
  return Size(workArea == null ? width : math.min(width, math.max(1.0, workArea.width - 24)),
    workArea == null ? height : math.min(height, math.max(1.0, workArea.height - 24)));
}

class NextDeskPasswordField extends StatelessWidget {
  const NextDeskPasswordField({super.key, required this.password, required this.label,
    this.onCopy, this.actions = const []});
  final TextEditingController password;
  final String label;
  final VoidCallback? onCopy;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(label, style: const TextStyle(color: Color(0xFF647587), fontSize: 13,
        fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(child: GestureDetector(onDoubleTap: onCopy, child: TextFormField(
          controller: password, readOnly: true,
          style: const TextStyle(fontSize: 16, color: Color(0xFF0A2038), fontWeight: FontWeight.w600),
          decoration: InputDecoration(isDense: true, filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDCE5ED))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDCE5ED)))),
        ))),
        ...actions,
      ]),
    ]),
  );
}

class NextDeskExitButton extends StatelessWidget {
  const NextDeskExitButton({super.key, required this.onExit, required this.label});
  final VoidCallback onExit;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Align(alignment: Alignment.centerRight, child: OutlinedButton(
      onPressed: onExit,
      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0061AD),
        minimumSize: const Size(0, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      child: Text(label),
    )),
  );
}



/// The incoming assistance screen. Connection state and security controls remain
/// supplied by the native client, rather than inferred from the displayed code.
class NextDeskHomePanel extends StatefulWidget {
  const NextDeskHomePanel({super.key, required this.code, required this.status,
    required this.controls, this.contentKey, this.footerKey, this.scrollController,
    this.onContentSizeChanged});

  final TextEditingController code;
  final Widget status;
  final Widget controls;
  final Key? contentKey;
  final Key? footerKey;
  final VoidCallback? onContentSizeChanged;
  final ScrollController? scrollController;

  @override
  State<NextDeskHomePanel> createState() => _NextDeskHomePanelState();
}

class _NextDeskHomePanelState extends State<NextDeskHomePanel> {
  static const navy = Color(0xFF0A2038);
  static const blue = Color(0xFF0061AD);
  static const muted = Color(0xFF647587);
  String? copiedCode;
  bool copyFailed = false;

  Future<void> copyCode(String code) async {
    try {
      await Clipboard.setData(ClipboardData(text: code));
      if (mounted) setState(() { copiedCode = code; copyFailed = false; });
    } catch (_) {
      if (mounted) setState(() { copiedCode = null; copyFailed = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(textTheme:
        Theme.of(context).textTheme.apply(fontFamily: 'Manrope')),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: 'Manrope'),
        child: ColoredBox(
      color: const Color(0xFFF3F7FA),
      child: LayoutBuilder(builder: (context, viewport) {
        widget.onContentSizeChanged?.call();
        return NotificationListener<SizeChangedLayoutNotification>(
          onNotification: (_) { widget.onContentSizeChanged?.call(); return false; },
          child: SingleChildScrollView(
            controller: widget.scrollController,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight.isFinite ? viewport.maxHeight : 0),
              child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                SizeChangedLayoutNotifier(child: Column(key: widget.contentKey,
                  mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            color: navy,
            child: Column(children: [
              SvgPicture.asset('assets/nextdesk-wordmark-white.svg',
                width: 216, height: 32, semanticsLabel: 'NextDesk'),
              const SizedBox(height: 8),
              const Text('Soporte Remoto', style: TextStyle(color: Color(0xFF86BEDF),
                fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
            ]),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(18, 12, 18, 10),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDCE5ED))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Código de conexión', style: TextStyle(color: navy,
                fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.code,
                builder: (context, value, _) {
                  final code = value.text.trim();
                  final available = code.isNotEmpty && RegExp(r'\d').hasMatch(code);
                  final copied = available && copiedCode == code;
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(color: const Color(0xFFF3F7FA),
                        borderRadius: BorderRadius.circular(12)),
                      child: Semantics(label: 'Código de conexión',
                        child: SelectableText(available ? code : 'Obteniendo código…',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: navy, fontSize: available ? 30 : 17,
                            fontWeight: FontWeight.w700, letterSpacing: available ? 1 : 0))),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: available ? () => copyCode(code) : null,
                      style: FilledButton.styleFrom(backgroundColor: blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: Icon(copied ? Icons.check_rounded : Icons.copy_outlined, size: 19),
                      label: Text(copied ? 'Código copiado' : 'Copiar código',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                    if (copyFailed) const Padding(padding: EdgeInsets.only(top: 8),
                      child: Text('No se pudo copiar. Seleccioná el código para copiarlo.',
                        style: TextStyle(color: Color(0xFFB3261E), fontSize: 13))),
                  ]);
                },
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFE4EBF1)),
              const SizedBox(height: 12),
              widget.status,
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 4), child: widget.controls),
                ])),
          SizeChangedLayoutNotifier(child: Padding(
            key: widget.footerKey,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: const Text.rich(
              TextSpan(children: [
                TextSpan(text: 'Powered by ', style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: 'Nextcom de Costa Rica'),
              ]),
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 13, height: 1.4),
            ),
          )),
              ]),
            ),
          ),
        );
      }),
        ),
      ),
    );
  }
}
