// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class UserModel {
  String? firstName;
  String? lastName;
  String? phoneNumber;
  String? pin;

  UserModel({
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.pin,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'pin': pin,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> user) {
    return UserModel(
      firstName: user['first_name'] as String?,
      lastName: user['last_name'] as String?,
      phoneNumber: user['phone_number'] as String?,
      pin: user['pin'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);
}