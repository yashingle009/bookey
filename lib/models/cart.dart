import 'cart_item.dart';

class Cart {
  final Map<String, CartItem> _items = {};

  // Get all items in the cart
  Map<String, CartItem> get items => {..._items};

  // Get the number of items in the cart
  int get itemCount => _items.length;

  // Get the total number of products (including quantities)
  int get productCount {
    return _items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  // Get the total price of all items in the cart
  double get totalAmount {
    return _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Add an item to the cart
  void addItem({
    required String bookId,
    required String title,
    required String author,
    required String imageUrl,
    required double price,
  }) {
    if (_items.containsKey(bookId)) {
      // Increase quantity if the item already exists
      _items.update(
        bookId,
        (existingItem) => existingItem.copyWith(
          quantity: existingItem.quantity + 1,
        ),
      );
    } else {
      // Add new item
      _items.putIfAbsent(
        bookId,
        () => CartItem(
          id: DateTime.now().toString(),
          bookId: bookId,
          title: title,
          author: author,
          imageUrl: imageUrl,
          price: price,
          quantity: 1,
        ),
      );
    }
  }

  // Remove an item from the cart
  void removeItem(String bookId) {
    _items.remove(bookId);
  }

  // Decrease the quantity of an item
  void decreaseQuantity(String bookId) {
    if (!_items.containsKey(bookId)) return;
    
    if (_items[bookId]!.quantity > 1) {
      _items.update(
        bookId,
        (existingItem) => existingItem.copyWith(
          quantity: existingItem.quantity - 1,
        ),
      );
    } else {
      removeItem(bookId);
    }
  }

  // Increase the quantity of an item
  void increaseQuantity(String bookId) {
    if (!_items.containsKey(bookId)) return;
    
    _items.update(
      bookId,
      (existingItem) => existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      ),
    );
  }

  // Clear the cart
  void clear() {
    _items.clear();
  }
}
