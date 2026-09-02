enum LifeObjectType { home, vehicle, person, pet, subscription, other }

class LifeObject {
  const LifeObject({
    required this.id,
    required this.name,
    required this.type,
    this.details,
  });

  final String id;
  final String name;
  final LifeObjectType type;
  final String? details;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'details': details,
      };

  factory LifeObject.fromJson(Map<String, dynamic> json) {
    return LifeObject(
      id: json['id'] as String,
      name: json['name'] as String,
      type: LifeObjectType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => LifeObjectType.other,
      ),
      details: json['details'] as String?,
    );
  }
}
