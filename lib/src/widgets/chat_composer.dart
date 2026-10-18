import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../theme_data.dart';

class ChatComposer extends StatefulWidget {
  final TextEditingController textCtrl;
  final bool hasText;
  final VoidCallback onSend;

  const ChatComposer({
    super.key,
    required this.textCtrl,
    required this.hasText,
    required this.onSend,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
      if (mounted) setState(() {});
    } catch (_) {
      _speechEnabled = false;
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    if (!_speechEnabled) {
      _speechEnabled = await _speechToText.initialize(
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
    }

    if (!_speechEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition is not available or permission denied.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (mounted) setState(() => _isListening = true);
    final initialText = widget.textCtrl.text;

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        final newWords = result.recognizedWords;
        if (newWords.isNotEmpty) {
          final prefix = initialText.isNotEmpty ? '$initialText ' : '';
          widget.textCtrl.text = '$prefix$newWords';
          widget.textCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.textCtrl.text.length),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52, maxHeight: 156),
          decoration: BoxDecoration(
            color: context.bgElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isListening ? context.accent : context.borderSubtle,
              width: _isListening ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: widget.textCtrl,
                  maxLines: null,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: _isListening ? 'Listening...' : 'Type a message…',
                    hintStyle: TextStyle(
                      color: _isListening ? context.statusDanger : context.textMuted,
                      fontSize: 15,
                      fontWeight: _isListening ? FontWeight.w600 : FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: _VoiceButton(
                  isListening: _isListening,
                  onTap: _toggleListening,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: _SendButton(
                  onTap: widget.onSend,
                  color: widget.hasText
                      ? context.accent
                      : context.accent.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onTap;

  const _VoiceButton({required this.isListening, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isListening ? context.statusDanger : context.bgSurface,
          shape: BoxShape.circle,
          border: isListening ? null : Border.all(color: context.borderSubtle),
        ),
        child: Icon(
          isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
          color: isListening ? Colors.white : context.accent,
          size: 18,
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;

  const _SendButton({required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.arrow_upward_rounded,
            color: Colors.white, size: 18),
      ),
    );
  }
}
