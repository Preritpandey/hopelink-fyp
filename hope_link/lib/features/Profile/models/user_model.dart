import 'location_model.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<String> interest;
  final String status;
  final String gender;
  final String description;
  final String bio;
  final LocationModel location;
  final String profileImage;
  final String cv;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.interest,
    required this.status,
    required this.gender,
    required this.description,
    required this.bio,
    required this.location,
    required this.profileImage,
    required this.cv,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'] ?? '',
      interest: List<String>.from(json['interest'] ?? []),
      status: json['status'] ?? '',
      gender: json['gender'] ?? '',
      description: json['description'] ?? '',
      bio: json['bio'] ?? '',
      location: LocationModel.fromJson(json['location'] ?? {}),
      profileImage: json['profileImage'] ?? '',
      cv: json['cv'] ?? '',
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    List<String>? interest,
    String? status,
    String? gender,
    String? description,
    String? bio,
    LocationModel? location,
    String? profileImage,
    String? cv,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      interest: interest ?? this.interest,
      status: status ?? this.status,
      gender: gender ?? this.gender,
      description: description ?? this.description,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      profileImage: profileImage ?? this.profileImage,
      cv: cv ?? this.cv,
    );
  }
}
