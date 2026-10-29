import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/l10n.dart';
import '../../core/widgets.dart';

class VoiceNotesField extends StatefulWidget {
  const VoiceNotesField({super.key, required this.controller});
  final TextEditingController controller;
  @override
  State<VoiceNotesField> createState() => _VoiceNotesFieldState();
}

class _VoiceNotesFieldState extends State<VoiceNotesField> {
  final _speech = SpeechToText();
  bool _listening = false;
  String _before = '';
  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    try {
      if (_listening) {
        await _speech.stop();
        if (mounted) setState(() => _listening = false);
        return;
      }
      final ok = await _speech.initialize(
        onStatus: (status) {
          if (mounted && status != 'listening') {
            setState(() => _listening = false);
          }
        },
      );
      if (!mounted) return;
      if (!ok) {
        showSnack(context, context.l.xVoiceUnavailable);
        return;
      }
      final language = Localizations.localeOf(context).languageCode;
      final locales = await _speech.locales();
      final locale = locales
          .where((l) => l.localeId.startsWith(language))
          .firstOrNull;
      if (!mounted) return;
      if (locale == null) {
        showSnack(context, context.l.xVoiceUnavailable);
        return;
      }
      _before = widget.controller.text.trim();
      setState(() => _listening = true);
      await _speech.listen(
        listenOptions: SpeechListenOptions(localeId: locale.localeId),
        onResult: (r) {
          if (mounted) {
            widget.controller.text = [
              if (_before.isNotEmpty) _before,
              r.recognizedWords,
            ].join(' ');
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() => _listening = false);
        showSnack(context, context.l.xVoiceUnavailable);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: widget.controller,
        maxLines: 3,
        decoration: InputDecoration(labelText: context.l.notes),
      ),
      TextButton.icon(
        onPressed: _toggle,
        icon: Icon(_listening ? Icons.stop_circle_outlined : Icons.mic_none),
        label: Text(_listening ? context.l.xListening : context.l.xVoice),
      ),
    ],
  );
}
