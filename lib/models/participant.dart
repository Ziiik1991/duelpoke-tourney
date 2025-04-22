/// Representa a un participante individual en el torneo.
class Participant {
  final String id; // Identificador único
  final String name; // Nombre del participante

  Participant({required this.id, required this.name});

  // Sobrescribir igualdad para comparar por ID
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Participant &&
          runtimeType == other.runtimeType &&
          id == other.id;

  // Sobrescribir hashCode basado en ID
  @override
  int get hashCode => id.hashCode;

  // Representación en texto para debugging
  @override
  String toString() {
    return 'Participant{id: $id, name: $name}';
  }

  // --- JSON Serialization (si se usa save/load) ---
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
