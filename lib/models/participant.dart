// lib/models/participant.dart
class Participant {
  final String id;
  final String name;

  Participant({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Participant &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

   @override
  String toString() {
    return 'Participant{id: $id, name: $name}';
  }
}