package com.example.streeing_module

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.InputStream
import java.util.*

class BluetoothService(private val channel: MethodChannel) {

    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private var bluetoothSocket: BluetoothSocket? = null
    private var inputStream: InputStream? = null
    private var isReadingData = false

    // Start Bluetooth operations and try to connect to a paired device
    fun startBluetooth() {
        if (bluetoothAdapter == null) {
            Log.e("BluetoothService", "Bluetooth not supported")
            return
        }

        if (!bluetoothAdapter.isEnabled) {
            bluetoothAdapter.enable()
        }

        // Get paired devices and attempt to connect to valid ones only
        val pairedDevices = bluetoothAdapter.bondedDevices

        for (device in pairedDevices) {
            Log.d("BluetoothService", "Found paired device: ${device.name} - ${device.address}")

            // ✅ Filter only compatible devices like HC-05, HC-06, etc.
            if (device.name != null && (device.name.contains("HC-05", ignoreCase = true) ||
                                        device.name.contains("HC-06", ignoreCase = true) ||
                                        device.name.contains("ESP32", ignoreCase = true) ||
                                        device.name.contains("YourDeviceName", ignoreCase = true))) {

                Log.d("BluetoothService", "Trying to connect to: ${device.name}")
                connectToDevice(device)
                break // Stop after successful match to avoid multiple attempts
            }
        }
    }

    // Connect to the selected Bluetooth device
    public fun connectToDevice(device: BluetoothDevice) {
        try {
            val uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")  // Replace with your device's UUID
            bluetoothSocket = device.createRfcommSocketToServiceRecord(uuid)
            bluetoothSocket?.connect()

            // Once connected, get the InputStream to read data
            inputStream = bluetoothSocket?.inputStream

            Log.d("BluetoothService", "Connected to ${device.name} at ${device.address}")
            startReadingData()

        } catch (e: IOException) {
            Log.e("BluetoothService", "Error connecting to device: ${e.message}")
        }
    }

    // Start a new thread to continuously read data from the Bluetooth device
        public fun startReadingData() {
            isReadingData = true
            Thread {
                try {
                    val buffer = ByteArray(1024)
                    var bytes: Int
                    while (isReadingData) {
                        bytes = inputStream?.read(buffer) ?: -1
                        if (bytes != -1) {
                            // Decode the byte array using UTF-8 or another character set
                            val data = String(buffer, 0, bytes, Charsets.UTF_8).trim()

                            // Log the decoded data for debugging
                            Log.i("Bluetooth Read", "Received: $data")

                            // Send decoded data to Flutter
                            sendDataToFlutter(data)
                        }
                    }
                } catch (e: IOException) {
                    Log.e("BluetoothService", "Error reading data: ${e.message}")
                }
            }.start()
    }

    // Function to stop Bluetooth and close the connection
    fun stopBluetooth() {
        try {
            isReadingData = false
            inputStream?.close()
            bluetoothSocket?.close()
            Log.d("BluetoothService", "Bluetooth connection closed")
        } catch (e: IOException) {
            Log.e("BluetoothService", "Error closing Bluetooth connection: ${e.message}")
        }
    }

    // Function to send data back to Flutter
    public fun sendDataToFlutter(data: String) {
        channel.invokeMethod("onDataReceived", data)
    }
}
