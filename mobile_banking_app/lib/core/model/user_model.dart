// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class UserModel {
  String? firstName;
  String? lastName;
  String? phoneNumber;
  String? pin;
  String? profilePhoto;
  String? nidNumber;
  String? nidFullName;
  String? dateOfBirth;
  String? expiryDate;
  String? gender;
  String? kycStatus;
  String? nidFrontPath;
  bool? isVerified;
  Map<String, dynamic>? nidData;

  UserModel({
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.pin,
    this.profilePhoto,
    this.nidNumber,
    this.nidFullName,
    this.dateOfBirth,
    this.expiryDate,
    this.gender,
    this.kycStatus,
    this.nidFrontPath,
    this.isVerified,
    this.nidData,
  });

  String get fullName {
    if (nidFullName != null && nidFullName!.trim().isNotEmpty) {
      return nidFullName!.trim();
    }
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'pin': pin,
      'profile_photo': profilePhoto,
      'nid_number': nidNumber,
      'nid_full_name': nidFullName,
      'date_of_birth': dateOfBirth,
      'expiry_date': expiryDate,
      'gender': gender,
      'kyc_status': kycStatus,
      'nid_front_path': nidFrontPath,
      'is_verified': isVerified,
      'nid_data': nidData,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> user) {
    String? photo = user['profile_photo'] as String?;
    if (photo != null) {
      photo = photo.replaceAll('\\', '/');
    }

    String? nidFront = (user['nid_front_path'] ?? user['nid_image']) as String?;
    if (nidFront != null) {
      nidFront = nidFront.replaceAll('\\', '/');
    }

    final rawNidData = user['nid_data'];
    Map<String, dynamic>? nidDataMap;
    if (rawNidData is Map) {
      nidDataMap = Map<String, dynamic>.from(rawNidData);
    }

    final String? nidNum = (user['nid_number'] ?? nidDataMap?['nid_number'])?.toString();
    final String? nidName = (user['full_name'] ?? nidDataMap?['full_name'])?.toString();
    final String? dob = (user['date_of_birth'] ?? nidDataMap?['date_of_birth'])?.toString();
    final String? exp = (user['expiry_date'] ?? nidDataMap?['expiry_date'])?.toString();
    final String? gen = (user['gender'] ?? nidDataMap?['gender'])?.toString();

    return UserModel(
      firstName: user['first_name'] as String?,
      lastName: user['last_name'] as String?,
      phoneNumber: user['phone_number'] as String?,
      pin: user['pin'] as String?,
      profilePhoto: photo,
      nidNumber: nidNum,
      nidFullName: nidName,
      dateOfBirth: dob,
      expiryDate: exp,
      gender: gen,
      kycStatus: user['kyc_status'] as String?,
      nidFrontPath: nidFront,
      isVerified: user['is_verified'] as bool?,
      nidData: nidDataMap,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);
}