class CartItem {
  final int productId;
  final String title;
  final int quantity;
  final double price;
  final String? imageUrl;

  CartItem({
    required this.productId,
    required this.title,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });
}
