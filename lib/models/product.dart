class Product {
  final int? id;
  final String name;
  final double price;
  final double? costPrice; // Harga modal
  int stock;
  final String? imageUrl;
  final int? categoryId;
  final String? sku; // Kode produk
  final String? description; // Deskripsi produk
  final String? barcode; // Barcode

  Product({
    this.id,
    required this.name,
    required this.price,
    this.costPrice,
    required this.stock,
    this.imageUrl,
    this.categoryId,
    this.sku,
    this.description,
    this.barcode,
  });

  // Convert a Product into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'cost_price': costPrice,
      'stock': stock,
      'image_url': imageUrl,
      'category_id': categoryId,
      'sku': sku,
      'description': description,
      'barcode': barcode,
    };
  }

  // Create a Product from a Map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      costPrice: map['cost_price'],
      stock: map['stock'],
      imageUrl: map['image_url'],
      categoryId: map['category_id'],
      sku: map['sku'],
      description: map['description'],
      barcode: map['barcode'],
    );
  }

  // Create a copy of product with updated values
  Product copyWith({
    int? id,
    String? name,
    double? price,
    double? costPrice,
    int? stock,
    String? imageUrl,
    int? categoryId,
    String? sku,
    String? description,
    String? barcode,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      sku: sku ?? this.sku,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
    );
  }
}
