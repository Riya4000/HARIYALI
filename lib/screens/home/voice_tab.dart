// ============================================================
// FILE: lib/screens/home/voice_tab.dart
// Design: chat bubbles + pulse mic (first version)
// FIX: Full-width centering at all times.
//   - Column uses mainAxisAlignment.center equivalent via
//     wrapping in a ConstrainedBox + Center so the mic+header
//     are always vertically & horizontally centred on the screen.
//   - Commands section stays left-aligned but is forced full width.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/voice_service.dart';
import '../../services/sensor_service.dart';

class VoiceTab extends StatefulWidget {
  const VoiceTab({super.key});

  @override
  State<VoiceTab> createState() => _VoiceTabState();
}

class _VoiceTabState extends State<VoiceTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  String? _lastResponse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<VoiceService, SensorService>(
      builder: (context, voiceService, sensorService, child) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            // KEY FIX: use a full-width SizedBox so the inner Column
            // stretches across the entire screen width.
            child: SizedBox(
              width: double.infinity,
              child: Column(
                // Center everything horizontally
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // ── Page Header ────────────────────────────────────
                  _buildPageHeader(),
                  const SizedBox(height: 40),

                  // ── Mic Button ─────────────────────────────────────
                  _buildMicButton(voiceService, sensorService),
                  const SizedBox(height: 24),

                  // ── State Label ────────────────────────────────────
                  _buildStateLabel(voiceService.isListening),
                  const SizedBox(height: 28),

                  // ── Chat Bubbles ───────────────────────────────────
                  if (voiceService.recognizedText.isNotEmpty)
                    _buildChatBubble(
                      voiceService.recognizedText,
                      isUser: true,
                    ),
                  if (_lastResponse != null) ...[
                    const SizedBox(height: 10),
                    _buildChatBubble(_lastResponse!, isUser: false),
                  ],
                  const SizedBox(height: 32),

                  // ── Commands ───────────────────────────────────────
                  _buildCommandsSection(voiceService, sensorService),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Page Header ────────────────────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Column(
      children: [
        const Text(
          'Voice Assistant',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Tap the microphone and speak a command',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Mic Button ─────────────────────────────────────────────────────────────
  Widget _buildMicButton(VoiceService voiceService, SensorService sensorService) {
    return GestureDetector(
      onTap: () async {
        if (voiceService.isListening) {
          await voiceService.stopListening();
        } else {
          await voiceService.startListening(
            onResult: (text) async {
              final result = voiceService.processCommand(text);

              if (result['action'] == 'pump') {
                await sensorService.togglePump();
              } else if (result['action'] == 'window') {
                await sensorService.toggleWindow();
              } else if (result['action'] == 'light') {
                await sensorService.toggleLight();
              } else if (result['action'] == 'status') {
                final data = sensorService.currentData;
                if (data != null) {
                  final msg =
                      'Temperature is ${data.temperature.toStringAsFixed(1)}°C. '
                      'Humidity is ${data.humidity.toStringAsFixed(1)}%. '
                      'Soil moisture is ${data.soilMoisture.toStringAsFixed(1)}%.';
                  setState(() => _lastResponse = msg);
                  await voiceService.speak(msg);
                  return;
                }
              }

              setState(() => _lastResponse = result['message']);
              await voiceService.speak(result['message']);
            },
          );
        }
      },
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          final scale = voiceService.isListening ? _pulseAnim.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: voiceService.isListening
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade200,
                boxShadow: voiceService.isListening
                    ? [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.4),
                    blurRadius: 28,
                    spreadRadius: 8,
                  ),
                ]
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                voiceService.isListening
                    ? Icons.mic_rounded
                    : Icons.mic_none_rounded,
                size: 62,
                color: voiceService.isListening
                    ? Colors.white
                    : Colors.grey.shade500,
              ),
            ),
          );
        },
      ),
    );
  }

  // ── State Label ────────────────────────────────────────────────────────────
  Widget _buildStateLabel(bool isListening) {
    return Column(
      children: [
        Text(
          isListening ? 'Listening...' : 'Tap to speak',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isListening
                ? const Color(0xFF4CAF50)
                : Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          isListening ? 'Speak your command clearly' : 'Ready for your command',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Chat Bubble ────────────────────────────────────────────────────────────
  // Align handles left/right — this works correctly inside a
  // full-width SizedBox parent.
  Widget _buildChatBubble(String text, {required bool isUser}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF4CAF50).withOpacity(0.12)
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser
                ? const Color(0xFF4CAF50).withOpacity(0.3)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              const Icon(Icons.smart_toy_rounded,
                  size: 16, color: Color(0xFF4CAF50)),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF333333),
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              const Icon(Icons.person_rounded,
                  size: 16, color: Color(0xFF4CAF50)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Commands Section ───────────────────────────────────────────────────────
  // crossAxisAlignment.start here is fine because the parent
  // SizedBox(width: double.infinity) already fills the screen width,
  // so "start" = left edge of the full screen, not just the content.
  Widget _buildCommandsSection(
      VoiceService voiceService, SensorService sensorService) {
    final commands = [
      ('Turn on water pump', Icons.water_rounded),
      ('Open window', Icons.window_rounded),
      ('Turn on light', Icons.lightbulb_rounded),
      ('Check status', Icons.info_outline_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Try saying:',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF444444)),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: commands.map((cmd) {
            return GestureDetector(
              onTap: () async {
                final result = voiceService.processCommand(cmd.$1);
                if (result['action'] == 'pump') {
                  await sensorService.togglePump();
                } else if (result['action'] == 'window') {
                  await sensorService.toggleWindow();
                } else if (result['action'] == 'light') {
                  await sensorService.toggleLight();
                } else if (result['action'] == 'status') {
                  final data = sensorService.currentData;
                  if (data != null) {
                    final msg =
                        'Temperature is ${data.temperature.toStringAsFixed(1)}°C. '
                        'Humidity is ${data.humidity.toStringAsFixed(1)}%. '
                        'Soil moisture is ${data.soilMoisture.toStringAsFixed(1)}%.';
                    setState(() => _lastResponse = msg);
                    await voiceService.speak(msg);
                    return;
                  }
                }
                setState(() => _lastResponse = result['message']);
                await voiceService.speak(result['message']);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: const Color(0xFFA5D6A7), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cmd.$2, size: 16, color: const Color(0xFF4CAF50)),
                    const SizedBox(width: 8),
                    Text(
                      cmd.$1,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF333333)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}