  import 'dart:convert';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:http/http.dart' as http;
  import 'package:shared_preferences/shared_preferences.dart';

  class RoomCubit extends Cubit<Map<String, dynamic>> {
    RoomCubit()
      : super({
          "isLoading": false,
          "rooms": <Map<String, dynamic>>[],
          "errorMessage": "",
          "lockedRoomId": null,
          "isInitialized": false,
          "roomDetail": null,
        });
    final String _baseUrl = "http://localhost:3000/api";

    Future<void> checkLocalLockStatus() async {
      final prefs = await SharedPreferences.getInstance();
      final String? localRoomId = prefs.getString("saved_room_id");

      await fetchRooms();

      if (localRoomId != null) {
        final List<Map<String, dynamic>> currentRooms = 
            List<Map<String, dynamic>>.from(state["rooms"] ?? []);

        final currentRoomFromServer = currentRooms.firstWhere(
          (r) => r["id"].toString() == localRoomId.toString(),
          orElse: () => <String, dynamic>{},
        );

        if (currentRoomFromServer.isEmpty || currentRoomFromServer["deviceId"] == null) {
          print("[Sync] Di DB backend data kunci sudah dihapus! HP ikut melepaskan kunci.");
          await prefs.remove("saved_room_id"); 
          emit({
            ...state,
            "lockedRoomId": null, 
            "isInitialized": true, 
          });
        } else {
          emit({
            ...state, 
            "lockedRoomId": localRoomId,
            "isInitialized": true,
          });
          await fetchRoomDetail(localRoomId);
        }
      } else {
        emit({
          ...state,
          "isInitialized": true,
        });
      }
    }

    Future<void> fetchRooms() async {
      emit({
        ...state,
        "isLoading": state["rooms"].isEmpty ? true : false,
        "errorMessage": "",
      });

      try {
        final url = Uri.parse("$_baseUrl/rooms");
        final response = await http.get(url).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final List<dynamic> rawData = responseData["data"] ?? [];

          final List<Map<String, dynamic>> roomsData = rawData
              .map((item) => Map<String, dynamic>.from(item))
              .toList();

          emit({
            ...state,
            "isLoading": false,
            "rooms": roomsData,
            "errorMessage": "",
          });
        } else {
          final Map<String, dynamic> errorData = json.decode(response.body);
          emit({
            ...state,
            "isLoading": false,
            "errorMessage": errorData["message"] ?? "Gagal mengambil data.",
          });
        }
      } catch (error) {
        print("[Cubit Error] Catch Jaringan: $error");
        emit({
          ...state,
          "isLoading": false,
          "errorMessage": "Tidak dapat terhubung ke server backend. Pastikan API menyala.",
        });
      }
    }

    Future<void> fetchRoomDetail(String roomId) async {
      emit({
        ...state,
        "isLoading": true,
        "errorMessage": "",
      });

      try {
        final url = Uri.parse("$_baseUrl/rooms/$roomId");
        final response = await http.get(url).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final Map<String, dynamic> roomDetail = responseData["data"] ?? {};

          emit({
            ...state,
            "isLoading": false,
            "roomDetail": roomDetail,
            "errorMessage": "",
          });
        } else {
          final Map<String, dynamic> errorData = json.decode(response.body);
          emit({
            ...state,
            "isLoading": false,
            "errorMessage": errorData["message"] ?? "Gagal mengambil detail ruangan.",
          });
        }
      } catch (error) {
        print("[Cubit Error] Catch Room Detail: $error");
        emit({
          ...state,
          "isLoading": false,
          "errorMessage": "Gagal terhubung ke server untuk mengambil detail.",
        });
      }
    }

    Future<bool> createBooking({
      required String roomId,
      required String bookedByName,
      required DateTime startTime,
    }) async {
      try {
        final url = Uri.parse("$_baseUrl/bookings");
        final response = await http
            .post(
              url,
              headers: {"Content-Type": "application/json"},
              body: json.encode({
                "roomId": roomId,
                "bookedByName": bookedByName,
                "startTime": startTime.toUtc().toIso8601String(),
              }),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 201) {
          await fetchRoomDetail(roomId);
          await fetchRooms();
          return true;
        } else {
          final Map<String, dynamic> errorData = json.decode(response.body);
          print("[Booking Error] ${errorData["message"]}");
          return false;
        }
      } catch (error) {
        print("[Cubit Error] Catch Create Booking: $error");
        return false;
      }
    }

    Future<bool> assignDeviceToRoom(String roomId, String deviceId) async {
      try {
        final url = Uri.parse("$_baseUrl/rooms/$roomId");

        final List<Map<String, dynamic>> currentRooms = 
            List<Map<String, dynamic>>.from(state["rooms"] ?? []);

        final Map<String, dynamic> currentRoom = currentRooms.firstWhere(
          (r) => r["id"].toString() == roomId.toString(),
          orElse: () => <String, dynamic>{},
        );

        if (currentRoom.isEmpty) return false;

        final response = await http
            .put(
              url,
              headers: {"Content-Type": "application/json"},
              body: json.encode({
                "name": currentRoom["name"],
                "deviceId": deviceId,
                "status": currentRoom["status"] ?? "AVAILABLE",
              }),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("saved_room_id", roomId.toString());

          emit({
            ...state, 
            "lockedRoomId": roomId
          });

          await fetchRooms();
          return true;
        } else {
          return false;
        }
      } catch (error) {
        print("[Cubit Error] Catch Update Device: $error");
        return false;
      }
    }
  }