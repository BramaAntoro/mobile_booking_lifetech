import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../cubits/room_cubit.dart';

class RoomSetupPage extends StatefulWidget {
  const RoomSetupPage({super.key});

  @override
  State<RoomSetupPage> createState() => _RoomSetupPageState();
}

class _RoomSetupPageState extends State<RoomSetupPage> {
  String? _selectedRoomId;
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

  void _handleSaveSetup() async {
    if (_selectedRoomId == null || _myDeviceId == "Mengambil ID...") return;

    final bool isSuccess = await context.read<RoomCubit>().assignDeviceToRoom(
      _selectedRoomId!,
      _myDeviceId,
    );

    if (isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kunci sukses menggunakan ID: $_myDeviceId'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal mendaftarkan device ke backend.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
              final bool isLoading = state["isLoading"] ?? false;
              final String errorMessage = state["errorMessage"] ?? "";
              final List<Map<String, dynamic>> rooms =
                  List<Map<String, dynamic>>.from(state["rooms"] ?? []);

              if (isLoading && rooms.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (errorMessage.isNotEmpty && rooms.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<RoomCubit>().fetchRooms(),
                        child: const Text("Coba Lagi"),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Langkah Konfigurasi:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Pilih salah satu ruangan di bawah ini untuk dikunci ke Handphone ini secara permanen.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your Device ID: $_myDeviceId',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Daftar Ruangan Tersedia',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        final String roomId = room["id"].toString();
                        final isSelected = _selectedRoomId == roomId;
                        final statusColor = _getStatusColor(
                          room["displayColor"],
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Card(
                            elevation: isSelected ? 4 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Radio<String>(
                                value: roomId,
                                groupValue: _selectedRoomId,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRoomId = value;
                                  });
                                },
                              ),
                              title: Text(
                                room["name"] ?? "Tanpa Nama",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  room["deviceId"] ?? 'Device belum terhubung',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  room["status"] ?? "AVAILABLE",
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedRoomId = roomId;
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: ElevatedButton(
                      onPressed:
                          (_selectedRoomId != null &&
                              _myDeviceId != "Mengambil ID...")
                          ? _handleSaveSetup
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Kunci & Terapkan Ruangan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
