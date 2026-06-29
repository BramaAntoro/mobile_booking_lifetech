import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../cubits/room_cubit.dart';

class RoomMonitorPage extends StatefulWidget {
  const RoomMonitorPage({super.key});

  @override
  State<RoomMonitorPage> createState() => _RoomMonitorPageState();
}

class _RoomMonitorPageState extends State<RoomMonitorPage> {
  String _myDeviceId = "Mengambil ID..."; 

  @override
  void initState() {
    super.initState();
    _getHardwareDeviceId(); 
  }

  Future<void> _getHardwareDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceId = "UNKNOWN_DEVICE";

    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId =
            "ANDROID_${androidInfo.brand.toUpperCase()}_${androidInfo.model.toUpperCase()}_${androidInfo.id}";
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = "IOS_${iosInfo.identifierForVendor ?? 'UNKNOWN'}";
      }
    } catch (e) {
      debugPrint("Gagal mengambil info device: $e");
      deviceId = "ERROR_DEVICE_ID";
    }

    if (mounted) {
      setState(() {
        _myDeviceId = deviceId;
      });
    }
  }

  Color _getStatusColor(String? colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red.shade700;
      case 'yellow':
        return Colors.amber.shade800;
      case 'grey':
        return Colors.grey.shade600;
      case 'blue':
      default:
        return Colors.blue.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Room IoT Monitor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocBuilder<RoomCubit, Map<String, dynamic>>(
            builder: (context, state) {
              final String? lockedRoomId = state["lockedRoomId"];
              final List<Map<String, dynamic>> rooms =
                  List<Map<String, dynamic>>.from(state["rooms"] ?? []);

              final lockedRoom = rooms.firstWhere(
                (r) => r["id"].toString() == lockedRoomId,
                orElse: () => {
                  "name": "Ruangan Terkunci",
                  "status": "UNKNOWN",
                  "displayColor": "grey",
                },
              );
              final statusColor = _getStatusColor(lockedRoom["displayColor"]);

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 72,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "MODE MONITOR AKTIF",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lockedRoom["name"] ?? "Nama Ruangan",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        lockedRoom["status"] ?? "AVAILABLE",
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "Device ID: $_myDeviceId",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Device ini dikunci untuk ruangan ini.\nHubungi Admin utama untuk mengubah konfigurasi.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.read<RoomCubit>().fetchRooms(),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Perbarui Status"),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
