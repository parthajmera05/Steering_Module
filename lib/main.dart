import 'package:flutter/material.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:typed_data';

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

  @override
  void initState() {
    super.initState();
    _volumeController = VolumeController();
    _volumeController.showSystemUI = false;
    initBluetooth();
  }

  Future<void> initBluetooth() async {
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.locationWhenInUse.request().isGranted) {
      print('Bluetooth permissions granted ✅');
      setState(() {
        _bluetoothState = BluetoothStatus.on;
      });
    } else {
      print('Bluetooth permissions not granted ❌');
      setState(() {
        _bluetoothState = BluetoothStatus.off;
      });
    }

    getBondedDevices();
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
      await _bluetooth.connect(device.address, 'SPP');
      print('Connected to device ✅');

      setState(() {
        isConnected = true;
        connectedDevices.add(device);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Device Connected Successfully')));
    } catch (e) {
      print('Cannot connect, exception occurred');
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to connect to device')));
    }
  }

  void handleIncomingData(String data) async {
    String message = '';

    switch (data) {
      case 'A': // Volume Up
        double currentVolume = await _volumeController.getVolume();
        double newVolume = (currentVolume + 0.1).clamp(0.0, 1.0);
        _volumeController.setVolume(newVolume);
        backgroundColor = Colors.greenAccent;
        message = 'Volume Up';
        break;

      case 'B': // Volume Down
        double currentVolume = await _volumeController.getVolume();
        double newVolume = (currentVolume - 0.1).clamp(0.0, 1.0);
        _volumeController.setVolume(newVolume);
        backgroundColor = Colors.redAccent;
        message = 'Volume Down';
        break;

      case 'C':
        backgroundColor = Colors.blueAccent;
        message = 'Pick Up Call (Future)';
        break;

      case 'D':
        backgroundColor = Colors.orangeAccent;
        message = 'Hang Up Call (Future)';
        break;

      case 'E': // Next track
        await player.seekToNext();
        backgroundColor = Colors.purpleAccent;
        message = 'Next Track';
        break;

      case 'F': // Previous track
        await player.seekToPrevious();
        backgroundColor = Colors.tealAccent;
        message = 'Previous Track';
        break;

      case 'G': // Play/Pause
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

      case 'H': // Bluetooth ON/OFF (Visual only)
        isBluetoothOn = !isBluetoothOn;
        backgroundColor = isBluetoothOn ? Colors.lightBlueAccent : Colors.grey;
        message = isBluetoothOn ? 'Bluetooth ON' : 'Bluetooth OFF';
        break;

      default:
        backgroundColor = Colors.white;
        message = 'Unknown Command Received';
    }

    if (message.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }

    setState(() {});
  }

  void checkConnectedDevices() {
    if (connectedDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No devices are currently connected.')),
      );
    } else {
      for (Device device in connectedDevices) {
        print('Connected Device: ${device.name} (${device.address})');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connected: ${device.name}')));
      }
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