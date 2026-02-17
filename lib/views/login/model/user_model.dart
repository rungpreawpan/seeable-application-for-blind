class UserModel {
  int? id;
  String? firstname;
  String? lastname;
  String? username;
  String? email;

  UserModel({
    this.id,
    this.firstname,
    this.lastname,
    this.username,
    this.email,
  });

  factory UserModel.fromJSON(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      username: json['username'],
      email: json['email'],
    );
  }
}