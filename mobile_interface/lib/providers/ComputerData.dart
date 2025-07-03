import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ComputerData {
  final String id;
  final String name;
   final String macAddress;
    String ipAddress;
    String lastOnline;
  List<bool> statusHistory;

  ComputerData({
    required this.id,
    required this.name,
    required this.macAddress,
    required this.ipAddress,
    required this.lastOnline,
    List<bool>? statusHistory,
  }): statusHistory = statusHistory ?? [];




  factory ComputerData.fromJson(Map<String, dynamic> json) {
    return ComputerData(
      id: json['id'] ?? 'null',
      name: json['name'] ?? '',
      macAddress: json['mac'] as String ?? 'null',
      ipAddress: json['ip'] as String ?? 'null',
      lastOnline: json['online'] as String ?? 'null',
      statusHistory: List<bool>.from(json['statusHistory'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mac': macAddress,
      'ip': ipAddress,
      'online': lastOnline,
      'statusHistory': statusHistory,
    };
  }
}