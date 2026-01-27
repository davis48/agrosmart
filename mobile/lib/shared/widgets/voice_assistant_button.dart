import 'package:flutter/material.dart';
import '../../../../core/services/voice_service.dart';
import '../../../../injection_container.dart';

class VoiceAssistantButton extends StatefulWidget {
  final String textToRead;
  final Function(String)? onCommand;

  const VoiceAssistantButton({
    super.key,
    this.textToRead = "",
    this.onCommand,
  });

  @override
  State<VoiceAssistantButton> createState() => _VoiceAssistantButtonState();
}

class _VoiceAssistantButtonState extends State<VoiceAssistantButton> {
  final VoiceService _voiceService = sl<VoiceService>();
  bool _isListening = false;
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton Lecture (TTS)
        if (widget.textToRead.isNotEmpty)
          IconButton(
            icon: Icon(_isPlaying ? Icons.volume_off : Icons.volume_up),
            color: Colors.blue,
            onPressed: () async {
              if (_isPlaying) {
                await _voiceService.stop();
                setState(() => _isPlaying = false);
              } else {
                setState(() => _isPlaying = true);
                await _voiceService.speak(widget.textToRead);
                // Note: La détection de fin de lecture n'est pas parfaite ici sans listener
                // On pourrait ajouter un setCompletionHandler dans VoiceService
                await Future.delayed(const Duration(seconds: 5)); 
                if (mounted) setState(() => _isPlaying = false);
              }
            },
          ),
        
        // Bouton Commande Vocale (STT) - Optionnel si onCommand fourni
        if (widget.onCommand != null)
          FloatingActionButton.small(
            backgroundColor: _isListening ? Colors.red : Colors.green,
            child: Icon(_isListening ? Icons.mic_off : Icons.mic),
            onPressed: () {
               _voiceService.listen(
                 onListening: () => setState(() => _isListening = true),
                 onNotListening: () => setState(() => _isListening = false),
                 onResult: (text) => widget.onCommand!(text),
               );
            },
          ),
      ],
    );
  }
}
