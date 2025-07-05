import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/ComputerData.dart';

class SessionStorageService {
  final String userId;

  SessionStorageService({required this.userId});

  // Cheie pentru MAC ESP32
  String get _macKey => '${userId}_esp32_mac';

  // Cheie pentru lista de calculatoare
  String get _computersKey => '${userId}_computers';

  // Cheie pentru istoricul statusului
  String get _pingHistoryKey => '${userId}_ping_history';

  // MAC ESP32
  Future<void> saveMacAddress(String mac) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_macKey, mac);
  }

  Future<String?> getMacAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_macKey);
  }

  // CALCULATOARE
  Future<void> saveComputers(List<ComputerData> computers) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = computers.map((c) => c.toJson()).toList();
    await prefs.setString(_computersKey, jsonEncode(jsonList));
  }

  Future<List<Map<String, dynamic>>> getComputers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_computersKey);
    if (jsonString == null) return [];

    final decoded = jsonDecode(jsonString);
    return List<Map<String, dynamic>>.from(decoded);
  }

  // ISTORIC STATUS
  Future<void> savePingHistory(Map<String, List<bool>> pingHistory) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      pingHistory.map(
        (key, value) => MapEntry(key, value.map((v) => v ? 1 : 0).toList()),
      ),
    );
    await prefs.setString(_pingHistoryKey, encoded);
  }

  Future<Map<String, List<bool>>> getPingHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_pingHistoryKey);
    if (jsonString == null) return {};

    final Map<String, dynamic> decoded = jsonDecode(jsonString);
    return decoded.map(
      (key, value) =>
          MapEntry(key, List<int>.from(value).map((e) => e == 1).toList()),
    );
  }
}
