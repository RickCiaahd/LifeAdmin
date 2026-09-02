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
}
