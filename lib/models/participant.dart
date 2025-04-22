/// Representa a un participante individual en el torneo.
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

  // --- JSON Serialization
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'ErrorName',
    );
  }
  // --- Fin JSON Serialization ---
}
