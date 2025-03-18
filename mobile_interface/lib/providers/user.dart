class User {
  late  String? id;
  late  String email;
  late  String password;
  late String? dateTime;

  User({this.id, required this.email, required this.password, this.dateTime});

  Map<String, Object?> toMap() {
    return {'id': id, 'email': email, 'password': password, 'dateTime': dateTime};
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, password: $password, dateTime: $dateTime);';
  }
}