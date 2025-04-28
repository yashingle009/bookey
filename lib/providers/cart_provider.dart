import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final Cart _cart = Cart();

  // Get all items in the cart
  Map<String, CartItem> get items => _cart.items;

  // Get the number of items in the cart
  int get itemCount => _cart.itemCount;

  // Get the total number of products (including quantities)
  int get productCount => _cart.productCount;

  // Get the total price of all items in the cart
  double get totalAmount => _cart.totalAmount;

  // Add an item to the cart
  void addItem({
    required String bookId,
    required String title,
    required String author,
    required String imageUrl,
    required double price,
  }) {
    _cart.addItem(
      bookId: bookId,
      title: title,
      author: author,
      imageUrl: imageUrl,
      price: price,
    );
    notifyListeners();
  }

  // Remove an item from the cart
  void removeItem(String bookId) {
    _cart.removeItem(bookId);
    notifyListeners();
  }

  // Decrease the quantity of an item
  void decreaseQuantity(String bookId) {
    _cart.decreaseQuantity(bookId);
    notifyListeners();
  }

  // Increase the quantity of an item
  void increaseQuantity(String bookId) {
    _cart.increaseQuantity(bookId);
    notifyListeners();
  }

  // Clear the cart
  void clear() {
    _cart.clear();
    notifyListeners();
  }
}
