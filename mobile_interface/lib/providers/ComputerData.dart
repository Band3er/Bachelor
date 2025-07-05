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
  }) : statusHistory = statusHistory ?? [];

  factory ComputerData.fromJson(Map<String, dynamic> json) {
    return ComputerData(
      id: json['id'] ?? 'null',
      name: json['name'] ?? '',
      macAddress: json['mac'].toString(),
      ipAddress: json['ip'].toString(),
      lastOnline: json['online'].toString(),
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
