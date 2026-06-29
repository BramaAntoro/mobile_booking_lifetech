import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubits/room_cubit.dart';
import 'pages/room_monitor_page.dart';
import 'pages/room_setup_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Room Device Setup',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (context) => RoomCubit()..checkLocalLockStatus(),
        child: const AppHome(),
      ),
    );
  }
}

class AppHome extends StatelessWidget {
  const AppHome({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomCubit, Map<String, dynamic>>(
      builder: (context, state) {
        final bool isInitialized = state["isInitialized"] ?? false;
        final String? lockedRoomId = state["lockedRoomId"];

        if (!isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (lockedRoomId != null) {
          return const RoomMonitorPage();
        }

        return const RoomSetupPage();
      },
    );
  }
}
