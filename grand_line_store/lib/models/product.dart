class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final int stock;
  final double rating;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.stock,
    required this.rating,
  })  : assert(price >= 0, 'price must be >= 0'),
        assert(rating >= 0 && rating <= 5, 'rating must be between 0 and 5');

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String,
        price: (json['price'] as num).toDouble(),
        category: json['category'] as String,
        imageUrl: json['imageUrl'] as String,
        stock: json['stock'] as int,
        rating: (json['rating'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'imageUrl': imageUrl,
        'stock': stock,
        'rating': rating,
      };
}
