import 'package:flutter/material.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';

enum BluetoothStatus { unknown, on, off }

void main() {
  runApp(MaterialApp(home: BluetoothApp()));
}

class BluetoothApp extends StatefulWidget {
  const BluetoothApp({super.key});

  @override
  _BluetoothAppState createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {
  BluetoothStatus _bluetoothState = BluetoothStatus.unknown;
  bool isConnected = false;
  List<Device> devices = [];
  List<Device> connectedDevices = [];
  Color backgroundColor = Colors.white;
  bool isBluetoothOn = true;
  final player = AudioPlayer();
  late final VolumeController _volumeController;
  final BluetoothClassic _bluetooth = BluetoothClassic();

  // Platform channel for native communication
  static const platform = MethodChannel('com.yourcompany.bluetooth');

  @override
  void initState() {
    super.initState();
    _volumeController = VolumeController();
    _volumeController.showSystemUI = false;

    // Set up the platform channel handler
    platform.setMethodCallHandler(_handleNativeMethodCall);

    initBluetooth();
  }

  Future<void> initBluetooth() async {
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.locationWhenInUse.request().isGranted &&
        await Permission.phone.request().isGranted) {
      print('Bluetooth permissions granted ✅');
      setState(() {
        _bluetoothState = BluetoothStatus.on;
      });
      startBluetoothReading();
    } else {
      print('Bluetooth permissions not granted ❌');
      setState(() {
        _bluetoothState = BluetoothStatus.off;
      });
    }

    getBondedDevices();
  }

  // Handle native method calls (data from Bluetooth)
  Future<void> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'onDataReceived') {
      String data = call.arguments as String;
      print('Received from native: $data');
      handleIncomingData(data);
    }
  }

  void getBondedDevices() async {
    try {
      devices = await _bluetooth.getPairedDevices();
      setState(() {});
    } catch (e) {
      print('Error getting paired devices: $e');
    }
  }

  void connectToDevice(Device device) async {
    try {
      await _bluetooth.connect(
        device.address,
        '00001101-0000-1000-8000-00805F9B34FB',
      );
      print('Connected to device ✅');
      setState(() {
        isConnected = true;
        connectedDevices.add(device);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Device Connected Successfully')));
    } catch (e) {
      print('Cannot connect, exception occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to connect to device')));
    }
  }

  // Handle ASCII commands
  void handleIncomingData(String data) async {
    String message = '';

    switch (data) {
      case 'R':
        double currentVolume = await _volumeController.getVolume();
        double newVolume = (currentVolume + 0.1).clamp(0.0, 1.0);
        _volumeController.setVolume(newVolume);
        backgroundColor = Colors.greenAccent;
        message = 'Volume Up';
        break;

      case 'A':
        double currentVolume = await _volumeController.getVolume();
        double newVolume = (currentVolume - 0.1).clamp(0.0, 1.0);
        _volumeController.setVolume(newVolume);
        backgroundColor = Colors.redAccent;
        message = 'Volume Down';
        break;

      case 'K': // Answer Call
        await answerCall();
        backgroundColor = Colors.blueAccent;
        message = 'Answered Call';
        break;

      case 'S': // Hang Up Call
        await hangUpCall();
        backgroundColor = Colors.orangeAccent;
        message = 'Hung Up Call';
        break;

      case 'H':
        await player.seekToNext();
        backgroundColor = Colors.purpleAccent;
        message = 'Next Track';
        break;

      case 'I':
        await player.seekToPrevious();
        backgroundColor = Colors.tealAccent;
        message = 'Previous Track';
        break;

      case 'T':
        if (player.playing) {
          await player.pause();
          message = 'Paused Music';
          backgroundColor = Colors.yellowAccent;
        } else {
          await player.play();
          message = 'Playing Music';
          backgroundColor = Colors.lightGreenAccent;
        }
        break;

      case 'Y':
        isBluetoothOn = !isBluetoothOn;
        backgroundColor = isBluetoothOn ? Colors.lightBlueAccent : Colors.grey;
        message = isBluetoothOn ? 'Bluetooth ON' : 'Bluetooth OFF';
        break;

      default:
        backgroundColor = Colors.white;
        message = 'Unknown Command Received';
    }

    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }

    setState(() {});
  }

  Future<void> answerCall() async {
    try {
      await platform.invokeMethod('answerCall');
    } catch (e) {
      print("Failed to answer call: $e");
    }
  }

  Future<void> hangUpCall() async {
    try {
      await platform.invokeMethod('hangUpCall');
    } catch (e) {
      print("Failed to hang up call: $e");
    }
  }

  void checkConnectedDevices() {
    if (connectedDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No devices are currently connected.')),
      );
    } else {
      for (Device device in connectedDevices) {
        print('Connected Device: ${device.name} (${device.address})');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connected: ${device.name}')));
      }
    }
  }

  void startBluetoothReading() async {
    try {
      final result = await platform.invokeMethod('startReading');
      print(result);
    } on PlatformException catch (e) {
      print("Failed to start reading: '${e.message}'");
    }
  }

  void stopBluetoothReading() async {
    try {
      final result = await platform.invokeMethod('stopReading');
      print(result);
    } on PlatformException catch (e) {
      print("Failed to stop reading: '${e.message}'");
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Steering Module Project')),
      body: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        color: backgroundColor,
        child: Column(
          children: [
            SizedBox(height: 20),
            Text('Bluetooth State: $_bluetoothState'),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: getBondedDevices,
              child: Text('Refresh Devices'),
            ),
            ElevatedButton(
              onPressed: checkConnectedDevices,
              child: Text('Check Connected Devices'),
            ),
            ElevatedButton(
              onPressed: startBluetoothReading,
              child: Text('Start Bluetooth Reading'),
            ),
            ElevatedButton(
              onPressed: stopBluetoothReading,
              child: Text('Stop Bluetooth Reading'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  Device device = devices[index];
                  return ListTile(
                    title: Text(device.name ?? "Unknown"),
                    subtitle: Text(device.address),
                    onTap: () => connectToDevice(device),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
