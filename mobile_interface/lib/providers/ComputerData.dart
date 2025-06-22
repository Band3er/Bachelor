import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ComputerData {
  final String id;
  final String name;
  final String macAddress;
  final String ipAddress;
  final String lastOnline;
  String doArp = '0';
  String sendWol = '0';

  ComputerData({
    required this.id,
    required this.name,
    required this.macAddress,
    required this.ipAddress,
    required this.lastOnline,
  });

  factory ComputerData.fromJson(Map<String, dynamic> json) {
    return ComputerData(
      id: json['id'] ?? 'null',
      name: json['name'] ?? '',
      macAddress: json['mac'] as String ?? 'null',
      ipAddress: json['ip'] as String ?? 'null',
      lastOnline: json['online'] as String ?? 'null',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mac': macAddress,
      'ip': ipAddress,
      'online': lastOnline,
    };
  }
}

