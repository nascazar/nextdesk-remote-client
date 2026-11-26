import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The incoming assistance screen. Connection state and security controls remain
/// supplied by the native client, rather than inferred from the displayed code.
class NextDeskHomePanel extends StatefulWidget {
  const NextDeskHomePanel({super.key, required this.code, required this.status,
    required this.controls, this.contentKey, this.scrollController});

  final TextEditingController code;
  final Widget status;
  final Widget controls;
  final Key? contentKey;
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
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(key: widget.contentKey, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
            color: navy,
            child: Column(children: [
              SvgPicture.asset('assets/nextdesk-wordmark-white.svg',
                width: 216, height: 42, semanticsLabel: 'NextDesk'),
              const SizedBox(height: 12),
              const Text('REMOTE', style: TextStyle(color: Color(0xFF86BEDF),
                fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 3)),
            ]),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDCE5ED))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Asistencia remota', style: TextStyle(color: navy,
                fontSize: 23, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Compartí este código con tu técnico.',
                style: TextStyle(color: muted, fontSize: 14, height: 1.4)),
              const SizedBox(height: 24),
              const Text('Código de conexión', style: TextStyle(
                color: muted, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.code,
                builder: (context, value, _) {
                  final code = value.text.trim();
                  final available = code.isNotEmpty && RegExp(r'\d').hasMatch(code);
                  final copied = available && copiedCode == code;
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(color: const Color(0xFFF3F7FA),
                        borderRadius: BorderRadius.circular(12)),
                      child: Semantics(label: 'Código de conexión',
                        child: SelectableText(available ? code : 'Obteniendo código…',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: navy, fontSize: available ? 32 : 17,
                            fontWeight: FontWeight.w700, letterSpacing: available ? 1 : 0))),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: available ? () => copyCode(code) : null,
                      style: FilledButton.styleFrom(backgroundColor: blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFE4EBF1)),
              const SizedBox(height: 16),
              widget.status,
            ]),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 0, 28, 16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.verified_user_outlined, size: 18, color: blue),
              SizedBox(width: 10),
              Expanded(child: Text('Vos autorizás cada conexión.',
                style: TextStyle(color: muted, fontSize: 13, height: 1.4))),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 20), child: widget.controls),
        ]),
        ),
      ),
      ),
    );
  }
}
