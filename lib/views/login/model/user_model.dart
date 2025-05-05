class UserModel {
  String? uuid;
  String? firstname;
  String? lastname;
  String? username;
  String? email;

  UserModel({
    this.uuid,
    this.firstname,
    this.lastname,
    this.username,
    this.email,
  });

  factory UserModel.fromJSON(Map<String, dynamic> json) {
    return UserModel(
      uuid: json['uuid'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      username: json['username'],
      email: json['email'],
    );
  }
}