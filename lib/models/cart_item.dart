class CartItem {
  final String id;
  final String bookId;
  final String title;
  final String author;
  final String imageUrl;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.bookId,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.price,
    this.quantity = 1,
  });

  // Calculate total price for this item
  double get totalPrice => price * quantity;

  // Create a copy with updated fields
  CartItem copyWith({
    String? id,
    String? bookId,
    String? title,
    String? author,
    String? imageUrl,
    double? price,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      author: author ?? this.author,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'title': title,
      'author': author,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
    };
  }

  // Create from Map (from storage)
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      bookId: map['bookId'],
      title: map['title'],
      author: map['author'],
      imageUrl: map['imageUrl'],
      price: map['price'],
      quantity: map['quantity'],
    );
  }
}
