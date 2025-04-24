class Product {
  final int? id;
  final String name;
  final double price;
  int stock;
  final String? imageUrl;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.imageUrl,
  });

  // Convert a Product into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
    };
  }

  // Create a Product from a Map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      stock: map['stock'],
      imageUrl: map['image_url'],
    );
  }

  // Create a copy of product with updated values
  Product copyWith({
    int? id,
    String? name,
    double? price,
    int? stock,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
} 