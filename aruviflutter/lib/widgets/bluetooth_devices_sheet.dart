import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

class BluetoothDevicesSheet extends StatefulWidget {
  const BluetoothDevicesSheet({super.key});

  @override
  State<BluetoothDevicesSheet> createState() => _BluetoothDevicesSheetState();
}

class _BluetoothDevicesSheetState extends State<BluetoothDevicesSheet> {
  final BluetoothService _bluetoothService = BluetoothService();
  bool _isLoading = true;
  List<Map<String, String>> _pairedDevices = [];
  String? _connectedDeviceName;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    
    final connected = await _bluetoothService.getConnectedDevice();
    final paired = await _bluetoothService.getPairedDevices();
    
    setState(() {
      _connectedDeviceName = connected;
      _pairedDevices = paired;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E24), // Dark background matching the screenshot
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Bluetooth Devices',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadDevices,
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Scanning for devices...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            )
          else ...[
            Expanded(
              child: ListView.separated(
                itemCount: _pairedDevices.length,
                separatorBuilder: (context, index) => const Divider(
                  color: Colors.white24,
                  height: 1,
                  indent: 64,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final device = _pairedDevices[index];
                  final isConnected = device['name'] == _connectedDeviceName;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const Icon(
                      Icons.headset,
                      color: Colors.red,
                      size: 32,
                    ),
                    title: Text(
                      device['name'] ?? 'Unknown Device',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device['address'] ?? '',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        Text(
                          isConnected ? 'Connected' : 'Paired',
                          style: TextStyle(
                            color: isConnected ? Colors.green : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _bluetoothService.openBluetoothSettings();
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
