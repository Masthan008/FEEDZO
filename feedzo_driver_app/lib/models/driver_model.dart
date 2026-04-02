class DriverModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String vehicleType;
  final String vehicleNumber;
  final int totalDeliveries;
  final double rating;
  final String avatarInitials;

  const DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.totalDeliveries,
    required this.rating,
    required this.avatarInitials,
  });
}
