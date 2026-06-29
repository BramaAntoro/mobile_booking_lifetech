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
  final TextEditingController _nameController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now().add(const Duration(minutes: 5));

  @override
  void initState() {
    super.initState();
    _getHardwareDeviceId();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (date != null) {
      if (!mounted) return;
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _handleBooking(String roomId) async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama pemesan harus diisi")),
      );
      return;
    }

    final success = await context.read<RoomCubit>().createBooking(
      roomId: roomId,
      bookedByName: _nameController.text,
      startTime: _selectedDateTime,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking Berhasil!")),
        );
        _nameController.clear();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal melakukan booking. Cek jadwal tabrakan.")),
        );
      }
    }
  }

  String _getStatusLabel(String? colorName) {
    switch (colorName) {
      case 'red':
        return "Sedang digunakan";
      case 'yellow':
        return "Segera";
      case 'grey':
        return "Pemeliharaan";
      case 'blue':
      default:
        return "Tersedia";
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
        actions: [
          IconButton(
            onPressed: () {
              final state = context.read<RoomCubit>().state;
              if (state["lockedRoomId"] != null) {
                context.read<RoomCubit>().fetchRoomDetail(state["lockedRoomId"]);
              }
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<RoomCubit, Map<String, dynamic>>(
          builder: (context, state) {
            final String? lockedRoomId = state["lockedRoomId"];
            final Map<String, dynamic>? roomDetail = state["roomDetail"];
            final bool isLoading = state["isLoading"] ?? false;

            if (lockedRoomId == null) {
              return const Center(child: Text("Room not locked."));
            }

            final String roomName = roomDetail?["name"] ?? "Loading...";
            final String status = roomDetail?["status"] ?? "AVAILABLE";
            final String displayColor = roomDetail?["displayColor"] ?? "blue";
            final List<dynamic> schedules = roomDetail?["bookedSchedules"] ?? [];

            final statusColor = _getStatusColor(displayColor);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                            roomName,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              _getStatusLabel(displayColor),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Booking Ruangan",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: "Nama Pemesan",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _pickDateTime,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: "Waktu Mulai (30 Menit)",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                "${_selectedDateTime.day}/${_selectedDateTime.month}/${_selectedDateTime.year}  ${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}",
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: isLoading ? null : () => _handleBooking(lockedRoomId),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator()
                                : const Text("Booking Sekarang"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Schedule List
                  const Text(
                    "Jadwal Mendatang",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (schedules.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: Text("Belum ada jadwal.")),
                    )
                  else
                    ...schedules.map((s) {
                      final start = DateTime.parse(s["startTime"]).toLocal();
                      final end = DateTime.parse(s["endTime"]).toLocal();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.event_available, color: Colors.green),
                          title: Text(s["bookedByName"] ?? "Anonim"),
                          subtitle: Text(
                            "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}",
                          ),
                          trailing: Text(
                            "${start.day}/${start.month}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      "Device ID: $_myDeviceId",
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

