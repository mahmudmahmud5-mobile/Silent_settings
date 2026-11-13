import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:sound_mode/permission_handler.dart'; // <-- Required for permission handling
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Parent Volume & Sound App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SoundControlHome(),
    );
  }
}

class SoundControlHome extends StatefulWidget {
  const SoundControlHome({super.key});

  @override
  State<SoundControlHome> createState() => _SoundControlHomeState();
}

class _SoundControlHomeState extends State<SoundControlHome> {
  RingerModeStatus _currentRingerStatus = RingerModeStatus.unknown;
  double _currentVolume = 0.5;

  @override
  void initState() {
    super.initState();
    _getInitialSettings();

    FlutterVolumeController.addListener((volume) {
      setState(() {
        _currentVolume = volume;
      });
    });
  }

  Future<void> _getInitialSettings() async {
    try {
      RingerModeStatus ringerStatus = await SoundMode.ringerModeStatus;
      double? volume = await FlutterVolumeController.getVolume();
      setState(() {
        _currentRingerStatus = ringerStatus;
        _currentVolume = volume ?? 0.5;
      });
    } catch (e) {
      debugPrint("Error getting initial settings: $e");
    }
  }

  Future<void> _toggleSoundMode() async {
    try {
      // Check if Do Not Disturb access permission is granted using PermissionHandler
      bool? isGranted = await PermissionHandler.permissionsGranted;

      if (isGranted != true) {
        // Open system settings to let the user enable permission
        await PermissionHandler.openDoNotDisturbSetting();
        return;
      }

      if (_currentRingerStatus == RingerModeStatus.silent) {
        await SoundMode.setSoundMode(RingerModeStatus.normal);
        setState(() {
          _currentRingerStatus = RingerModeStatus.normal;
        });
      } else {
        await SoundMode.setSoundMode(RingerModeStatus.silent);
        setState(() {
          _currentRingerStatus = RingerModeStatus.silent;
        });
      }
    } on PlatformException {
      debugPrint('Failed to change sound mode.');
    }
  }

  @override
  void dispose() {
    FlutterVolumeController.removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isSilent = _currentRingerStatus == RingerModeStatus.silent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound & Volume Control'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isSilent ? "Phone is currently: SILENT 🔕" : "Phone is currently: NORMAL 🔔",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSilent ? Colors.red : Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Large Elevated Button (Red when Silent, Green when Normal)
            SizedBox(
              width: double.infinity,
              height: 70,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSilent ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _toggleSoundMode,
                child: Text(
                  isSilent ? "Switch to Normal Mode" : "Switch to Silent Mode",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 60),
            const Text(
              "Media / Ring Volume Slider",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.volume_down, size: 30),
                Expanded(
                  child: Slider(
                    value: _currentVolume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: '${(_currentVolume * 100).round()}%',
                    onChanged: (double value) {
                      setState(() {
                        _currentVolume = value;
                      });
                      FlutterVolumeController.setVolume(value);
                    },
                  ),
                ),
                const Icon(Icons.volume_up, size: 30),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Volume: ${(_currentVolume * 100).round()}%",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}