class LocationModel {
  final String country;
  final String city;
  final String address;

  LocationModel({
    required this.country,
    required this.city,
    required this.address,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {"country": country, "city": city, "address": address};
  }
}
