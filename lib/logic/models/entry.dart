class Entry {
  final int id;
  final DateTime createdAt;
  final String qrCode;
  final double length;
  final double width;
  final double height;

  Entry({
    required this.id,
    required this.createdAt,
    required this.qrCode,
    required this.length,
    required this.width,
    required this.height,
  });

  static Entry fromJson(Map<String, dynamic> json) {
    return Entry(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      qrCode: json['qr_code'],
      length: json['length'],
      width: json['width'],
      height: json['height'],
    );
  }
}