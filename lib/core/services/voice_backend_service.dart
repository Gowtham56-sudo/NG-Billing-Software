import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class VoiceBackendService {
  static Process? _process;

  static Future<void> ensureVoiceBackendRunning() async {
    if (!Platform.isWindows) return;

    // Check if port 8765 is already reachable
    try {
      final socket = await Socket.connect('127.0.0.1', 8765, timeout: const Duration(milliseconds: 600));
      socket.destroy();
      debugPrint('[VoiceBackendService] Voice AI engine is already active on port 8765.');
      return;
    } catch (_) {
      // Not running, proceed to launch
    }

    try {
      final exeDir = p.dirname(Platform.resolvedExecutable);
      
      // Possible locations for python_voice_server
      final candidates = [
        p.join(exeDir, 'python_voice_server'),
        p.join(Directory.current.path, 'python_voice_server'),
        p.join(exeDir, '..', '..', '..', 'python_voice_server'),
        r'e:\NG-Billing Software\python_voice_server',
      ];

      String? voiceDir;
      for (final c in candidates) {
        if (File(p.join(c, 'server.py')).existsSync()) {
          voiceDir = c;
          break;
        }
      }

      if (voiceDir == null) {
        debugPrint('[VoiceBackendService] Could not locate python_voice_server folder.');
        return;
      }

      // Check for bundled venv Python or system Python
      final venvPython = p.join(voiceDir, 'venv', 'Scripts', 'python.exe');
      final pythonExe = File(venvPython).existsSync() ? venvPython : 'python';

      debugPrint('[VoiceBackendService] Launching Voice AI Server from: $voiceDir using $pythonExe');

      _process = await Process.start(
        pythonExe,
        ['server.py'],
        workingDirectory: voiceDir,
        mode: ProcessStartMode.detached,
      );

      debugPrint('[VoiceBackendService] Voice server launched with PID: ${_process?.pid}');
    } catch (e) {
      debugPrint('[VoiceBackendService] Auto-start failed: $e');
    }
  }

  static void shutdown() {
    if (_process != null) {
      try {
        _process!.kill();
        _process = null;
      } catch (_) {}
    }
  }
}
