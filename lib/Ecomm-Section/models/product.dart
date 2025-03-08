class Product {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final String description;
  final String size;
  final double rating;
  final int reviews;
  final bool isOnSale;
  final double discountPercentage;
  int quantity;

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.description = '',
    this.size = 'M',
    this.rating = 0.0,
    this.reviews = 0,
    this.isOnSale = false,
    this.discountPercentage = 0.0,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;
}
