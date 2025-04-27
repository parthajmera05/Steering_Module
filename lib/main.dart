import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:typed_data';

void main() {
  runApp(MaterialApp(home: BluetoothApp()));
}

class BluetoothApp extends StatefulWidget {
  const BluetoothApp({super.key});

  @override
  _BluetoothAppState createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  BluetoothConnection? connection;
  bool isConnected = false;
  List<BluetoothDevice> devices = [];
  Color backgroundColor = Colors.white;
  bool isBluetoothOn = true;
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    initBluetooth();
    VolumeController().showSystemUI = false;
  }

  Future<void> initBluetooth() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();

    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() => _bluetoothState = state);
    });

    FlutterBluetoothSerial.instance.onStateChanged().listen((state) {
      setState(() => _bluetoothState = state);
    });

    getBondedDevices();
  }

  void getBondedDevices() async {
    devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    setState(() {});
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      connection = await BluetoothConnection.toAddress(device.address);
      print('Connected to device');

      setState(() {
        isConnected = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device Connected Successfully'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      connection!.input!.listen((Uint8List data) {
        String incomingData = String.fromCharCodes(data).trim();
        print('Received Data: $incomingData');

        handleIncomingData(incomingData);

      }).onDone(() {
        print('Disconnected by remote request');
        setState(() {
          isConnected = false;
        });
      });
    } catch (e) {
      print('Cannot connect, exception occurred');
      print(e);
    }
  }

  void handleIncomingData(String data) async {
    String message = '';

    switch (data) {
      case 'A': // Volume Up
        double currentVolume = await VolumeController().getVolume();
        double newVolume = (currentVolume + 0.1).clamp(0.0, 1.0);
        VolumeController().setVolume(newVolume);
        backgroundColor = Colors.greenAccent;
        message = 'Volume Up';
        break;

      case 'B': // Volume Down
        double currentVolume = await VolumeController().getVolume();
        double newVolume = (currentVolume - 0.1).clamp(0.0, 1.0);
        VolumeController().setVolume(newVolume);
        backgroundColor = Colors.redAccent;
        message = 'Volume Down';
        break;

      case 'C': // Pick up call (Future Work)
        backgroundColor = Colors.blueAccent;
        message = 'Pick Up Call (Feature coming)';
        break;

      case 'D': // Hangup call (Future Work)
        backgroundColor = Colors.orangeAccent;
        message = 'Hang Up Call (Feature coming)';
        break;

      case 'E': // Forward Track
        await player.seekToNext();
        backgroundColor = Colors.purpleAccent;
        message = 'Next Track';
        break;

      case 'F': // Previous Track
        await player.seekToPrevious();
        backgroundColor = Colors.tealAccent;
        message = 'Previous Track';
        break;

      case 'G': // Play/Pause Toggle
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

      case 'H': // Bluetooth ON/OFF (Visual Toggle only)
        isBluetoothOn = !isBluetoothOn;
        backgroundColor = isBluetoothOn ? Colors.lightBlueAccent : Colors.grey;
        message = isBluetoothOn ? 'Bluetooth Turned ON' : 'Bluetooth Turned OFF';
        break;

      default:
        backgroundColor = Colors.white;
        message = 'Unknown Command Received';
    }

    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() {}); // To update UI
  }

  @override
  void dispose() {
    connection?.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bluetooth Media Controller')),
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
            Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  BluetoothDevice device = devices[index];
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
