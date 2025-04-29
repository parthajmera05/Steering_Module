package com.example.streeing_module

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.util.Log
import java.io.IOException
import java.util.*

class MainActivity : FlutterActivity() {
    private lateinit var bluetoothService: BluetoothService
    private lateinit var methodChannel: MethodChannel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize the MethodChannel and BluetoothService
        methodChannel = MethodChannel(flutterEngine!!.dartExecutor, "com.yourcompany.bluetooth")
        bluetoothService = BluetoothService(methodChannel)

        // Start Bluetooth operations (initializes Bluetooth)
        bluetoothService.startBluetooth()

        // Listen for data from Flutter
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startReading" -> {
                    bluetoothService.startReadingData()  // Start reading data
                    result.success("Bluetooth reading started.")
                }
                "stopReading" -> {
                    bluetoothService.stopBluetooth()  // Stop Bluetooth operations
                    result.success("Bluetooth reading stopped.")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Stop Bluetooth operations when the app is closed to clean up resources
        bluetoothService.stopBluetooth()
    }
}
