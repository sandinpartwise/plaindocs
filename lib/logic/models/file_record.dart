import 'dart:typed_data';

class FileRecord {
  final int id;
  final DateTime createdAt;
  final String name;
  final int entryId;

  Uint8List? bytes;

  FileRecord({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.entryId,
  });

  static FileRecord fromJson(Map<String, dynamic> json) {
    return FileRecord(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      name: json['name'],
      entryId: json['entry_id'],
    );
  }
}