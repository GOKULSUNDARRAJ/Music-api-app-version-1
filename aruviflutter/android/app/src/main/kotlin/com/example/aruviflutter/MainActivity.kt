package com.example.aruviflutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.media.AudioManager
import android.media.AudioDeviceInfo

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.saalai.salaimusicapp/bluetooth"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getConnectedDevice" -> {
                    result.success(getConnectedBluetoothDevice())
                }
                "getPairedDevices" -> {
                    result.success(getPairedBluetoothDevices())
                }
                "openBluetoothSettings" -> {
                    val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getConnectedBluetoothDevice(): String? {
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val devices = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            for (device in devices) {
                if (device.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                    device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                    device.type == AudioDeviceInfo.TYPE_BLE_HEADSET) {
                    return device.productName.toString()
                }
            }
        } catch (e: Exception) {
            // Ignore exceptions
        }
        return null
    }

    private fun getPairedBluetoothDevices(): List<Map<String, String>> {
        val pairedList = mutableListOf<Map<String, String>>()
        try {
            val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            val adapter = bluetoothManager.adapter
            if (adapter != null) {
                val pairedDevices = adapter.bondedDevices
                for (device in pairedDevices) {
                    val deviceMap = mapOf(
                        "name" to (device.name ?: "Unknown Device"),
                        "address" to device.address
                    )
                    pairedList.add(deviceMap)
                }
            }
        } catch (e: SecurityException) {
            // Missing permissions, return what we can or empty
        } catch (e: Exception) {
            // Ignore other exceptions
        }
        return pairedList
    }
}
