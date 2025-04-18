enum ScanStatus {
  safe,
  caution,
  danger
}

class ProductScan {
  final String name;
  final ScanStatus status;
  final String description;
  final String imagePath;
  final DateTime scanDate;

  ProductScan({
    required this.name,
    required this.status,
    required this.description,
    required this.imagePath,
    required this.scanDate,
  });
}