class Category {
  final int? id;
  final String name;
  final String? description;
  final String? color;

  Category({this.id, required this.name, this.description, this.color});

  Category copyWith({
    int? id,
    String? name,
    String? description,
    String? color,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'description': description, 'color': color};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      color: map['color'],
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, description: $description, color: $color)';
  }
}
