class BookListing {
  final String id;
  final String title;
  final String author;
  final String category;
  final String condition;
  final String description;
  final double price;
  final String location;
  final List<String> imageUrls;
  final String sellerId;
  final String sellerName;
  final DateTime createdAt;
  final bool isActive;

  BookListing({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.condition,
    required this.description,
    required this.price,
    required this.location,
    required this.imageUrls,
    required this.sellerId,
    required this.sellerName,
    required this.createdAt,
    this.isActive = true,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'category': category,
      'condition': condition,
      'description': description,
      'price': price,
      'location': location,
      'imageUrls': imageUrls,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  // Create from Map (from Firestore)
  factory BookListing.fromMap(Map<String, dynamic> map) {
    return BookListing(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      category: map['category'],
      condition: map['condition'],
      description: map['description'],
      price: map['price'],
      location: map['location'],
      imageUrls: List<String>.from(map['imageUrls']),
      sellerId: map['sellerId'],
      sellerName: map['sellerName'],
      createdAt: map['createdAt'].toDate(),
      isActive: map['isActive'],
    );
  }
}
