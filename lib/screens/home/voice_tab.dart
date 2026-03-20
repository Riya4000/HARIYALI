// ============================================================
// FILE: lib/screens/home/voice_tab.dart
// UPDATED: Auto mode awareness added.
//   • In MANUAL mode → pump & window voice commands work exactly as before
//   • In AUTO mode   → pump & window commands are blocked;
//                      the assistant speaks and shows a message explaining
//                      that auto mode is active
//   • Status, crop recommendation commands work in BOTH modes
// All original fixes (no-delay bubble, exact state set, 5 chips,
// mounted checks) are preserved.
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
    // Stop mic if user navigates away — prevents setState after dispose
    try {
      final voiceService = Provider.of<VoiceService>(context, listen: false);
      if (voiceService.isListening) voiceService.stopListening();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<VoiceService, SensorService>(
      builder: (context, voiceService, sensorService, child) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // ── Page Header ──────────────────────────────────────────
                  _buildPageHeader(),
                  const SizedBox(height: 16),

                  // ── AUTO MODE WARNING BANNER ─────────────────────────────
                  // Shown only when auto mode is active so user knows
                  // device commands will be rejected
                  if (sensorService.isAutoMode) ...[
                    _buildAutoModeBanner(),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 24),

                  // ── Mic Button ───────────────────────────────────────────
                  _buildMicButton(voiceService, sensorService),
                  const SizedBox(height: 24),

                  // ── State Label ──────────────────────────────────────────
                  _buildStateLabel(voiceService.isListening),
                  const SizedBox(height: 28),

                  // ── Chat Bubbles ─────────────────────────────────────────
                  // User bubble reads voiceService.recognizedText directly
                  // — updates LIVE as user speaks via notifyListeners()
                  if (voiceService.recognizedText.isNotEmpty)
                    _buildChatBubble(
                      voiceService.recognizedText,
                      isUser: true,
                      isPartial: voiceService.isListening,
                    ),
                  if (_lastResponse != null) ...[
                    const SizedBox(height: 10),
                    _buildChatBubble(_lastResponse!, isUser: false),
                  ],
                  const SizedBox(height: 32),

                  // ── Commands ─────────────────────────────────────────────
                  _buildCommandsSection(voiceService, sensorService),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── AUTO MODE BANNER ───────────────────────────────────────────────────────
  Widget _buildAutoModeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.smart_toy_rounded, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Auto mode is ON. Device commands (pump, window) are controlled '
                  'by the ESP32. Switch to Manual in the Controls tab to use voice control.',
              style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
            ),
          ),
        ],
      ),
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
  Widget _buildMicButton(
      VoiceService voiceService, SensorService sensorService) {
    return GestureDetector(
      onTap: () async {
        if (voiceService.isListening) {
          await voiceService.stopListening();
        } else {
          // Clear previous response when starting fresh
          if (mounted) setState(() => _lastResponse = null);

          await voiceService.startListening(
            onResult: (text) async {
              final result = voiceService.processCommand(text);
              final action = result['action'] as String;

              // ── PUMP command ───────────────────────────────────────────
              if (action == 'pump') {
                if (sensorService.isAutoMode) {
                  // AUTO MODE: block and inform the user
                  const msg =
                      'Cannot control the pump. Auto mode is active. '
                      'Please switch to Manual mode first.';
                  if (mounted) setState(() => _lastResponse = msg);
                  await voiceService.speak(msg);
                  return;
                }
                // MANUAL MODE: execute normally
                await sensorService.setPump(result['state'] as bool);
              }

              // ── WINDOW command ─────────────────────────────────────────
              else if (action == 'window') {
                if (sensorService.isAutoMode) {
                  // AUTO MODE: block and inform the user
                  const msg =
                      'Cannot control the window. Auto mode is active. '
                      'Please switch to Manual mode first.';
                  if (mounted) setState(() => _lastResponse = msg);
                  await voiceService.speak(msg);
                  return;
                }
                // MANUAL MODE: execute normally
                await sensorService.setWindow(result['state'] as bool);
              }

              // ── STATUS command — works in both modes ───────────────────
              else if (action == 'status') {
                final data = sensorService.currentData;
                if (data != null) {
                  final modeLabel =
                  sensorService.isAutoMode ? 'Auto' : 'Manual';
                  final msg =
                      'Temperature is ${data.temperature.toStringAsFixed(1)} degrees Celsius. '
                      'Humidity is ${data.humidity.toStringAsFixed(1)} percent. '
                      'Soil moisture is ${data.soilMoisture.toStringAsFixed(1)} percent. '
                      'System is in $modeLabel mode.';
                  if (mounted) setState(() => _lastResponse = msg);
                  await voiceService.speak(msg);
                  return;
                }
              }

              // ── All other commands (recommend, unknown) — works in both modes
              if (mounted) {
                setState(() => _lastResponse = result['message'] as String);
              }
              await voiceService.speak(result['message'] as String);
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
            color:
            isListening ? const Color(0xFF4CAF50) : Colors.grey.shade500,
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
  Widget _buildChatBubble(String text,
      {required bool isUser, bool isPartial = false}) {
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
                  fontStyle: isPartial ? FontStyle.italic : FontStyle.normal,
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
  Widget _buildCommandsSection(
      VoiceService voiceService, SensorService sensorService) {
    final isAuto = sensorService.isAutoMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try saying:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Device commands — greyed out in auto mode
            _buildCommandChip(
              'Turn on water pump',
              Icons.water,
              isDisabled: isAuto,
            ),
            _buildCommandChip(
              'Open window',
              Icons.window,
              isDisabled: isAuto,
            ),
            _buildCommandChip(
              'Turn off water pump',
              Icons.water_drop_outlined,
              isDisabled: isAuto,
            ),
            _buildCommandChip(
              'Close window',
              Icons.window_outlined,
              isDisabled: isAuto,
            ),
            // These always work
            _buildCommandChip('Check status', Icons.info_outline),
          ],
        ),
        if (isAuto) ...[
          const SizedBox(height: 10),
          Text(
            '⚠ Device commands are disabled in Auto mode.',
            style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
          ),
        ],
      ],
    );
  }

  // ── Command Chip ───────────────────────────────────────────────────────────
  Widget _buildCommandChip(String label, IconData icon,
      {bool isDisabled = false}) {
    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDisabled
                ? Colors.grey.shade300
                : const Color(0xFF4CAF50).withOpacity(0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isDisabled ? Colors.grey : const Color(0xFF4CAF50),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDisabled ? Colors.grey : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}