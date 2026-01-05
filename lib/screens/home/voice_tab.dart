// ============================================================================
// VOICE TAB - Voice assistant for hands-free control
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/voice_service.dart';
import '../../services/sensor_service.dart';

class VoiceTab extends StatefulWidget {
  const VoiceTab({super.key});

  @override
  State<VoiceTab> createState() => _VoiceTabState();
}

class _VoiceTabState extends State<VoiceTab> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<VoiceService, SensorService>(
      builder: (context, voiceService, sensorService, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Voice Assistant',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap the microphone and speak your command',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Microphone button
              GestureDetector(
                onTap: () async {
                  if (voiceService.isListening) {
                    await voiceService.stopListening();
                  } else {
                    await voiceService.startListening(
                      onResult: (text) async {
                        // Process the command
                        final result = voiceService.processCommand(text);

                        // Execute the action
                        if (result['action'] == 'pump') {
                          await sensorService.togglePump();
                        } else if (result['action'] == 'window') {
                          await sensorService.toggleWindow();
                        } else if (result['action'] == 'light') {
                          await sensorService.toggleLight();
                        } else if (result['action'] == 'status') {
                          final data = sensorService.currentData;
                          if (data != null) {
                            final statusMessage = 'Temperature is ${data.temperature.toStringAsFixed(1)} degrees celsius. '
                                'Humidity is ${data.humidity.toStringAsFixed(1)} percent. '
                                'Soil moisture is ${data.soilMoisture.toStringAsFixed(1)} percent.';
                            await voiceService.speak(statusMessage);
                            return;
                          }
                        }

                        // Speak the response
                        await voiceService.speak(result['message']);
                      },
                    );
                  }
                },
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: voiceService.isListening
                            ? const Color(0xFF4CAF50)
                            : Colors.grey.shade300,
                        boxShadow: voiceService.isListening
                            ? [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(
                              0.3 + (_animationController.value * 0.3),
                            ),
                            blurRadius: 20 + (_animationController.value * 20),
                            spreadRadius: 5 + (_animationController.value * 10),
                          ),
                        ]
                            : [],
                      ),
                      child: Icon(
                        Icons.mic,
                        size: 80,
                        color: voiceService.isListening ? Colors.white : Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Listening indicator
              if (voiceService.isListening)
                const Column(
                  children: [
                    Text(
                      'Listening...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Speak now',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                )
              else
                const Column(
                  children: [
                    Text(
                      'Ready',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap to start',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Recognized text
              if (voiceService.recognizedText.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You said:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        voiceService.recognizedText,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Example commands
              const Text(
                'Example Commands:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildCommandChip('Turn on water pump'),
              _buildCommandChip('Open window'),
              _buildCommandChip('Turn on light'),
              _buildCommandChip('Check status'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommandChip(String command) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            command,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
