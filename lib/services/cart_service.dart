import 'package:flutter/material.dart';
import 'firestore_service.dart';

class CartService extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<Map<String, dynamic>> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Calculate total price
  double get totalPrice {
    double total = 0;
    for (final item in _cartItems) {
      total += (item['price'] as num).toDouble() * item['quantity'];
    }
    return total;
  }
  
  // Get cart item count
  int get itemCount {
    int count = 0;
    for (final item in _cartItems) {
      count += item['quantity'] as int;
    }
    return count;
  }
  
  // Load cart items
  Future<void> loadCartItems() async {
    if (!_firestoreService.isUserLoggedIn) {
      _cartItems = [];
      notifyListeners();
      return;
    }
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final items = await _firestoreService.getCartItemsWithDetails();
      _cartItems = items;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading cart items: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add to cart
  Future<bool> addToCart(String bookId, {int quantity = 1}) async {
    if (!_firestoreService.isUserLoggedIn) {
      _error = 'You need to be logged in to add items to your cart';
      notifyListeners();
      return false;
    }
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final success = await _firestoreService.addToCart(bookId, quantity: quantity);
      
      if (success) {
        await loadCartItems();
      } else {
        _error = 'Failed to add item to cart';
        _isLoading = false;
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      _error = 'Error adding item to cart: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Update cart item quantity
  Future<bool> updateCartItemQuantity(String cartItemId, int quantity) async {
    if (!_firestoreService.isUserLoggedIn) {
      _error = 'You need to be logged in to update your cart';
      notifyListeners();
      return false;
    }
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final success = await _firestoreService.updateCartItemQuantity(cartItemId, quantity);
      
      if (success) {
        await loadCartItems();
      } else {
        _error = 'Failed to update cart item';
        _isLoading = false;
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      _error = 'Error updating cart item: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Remove from cart
  Future<bool> removeFromCart(String cartItemId) async {
    if (!_firestoreService.isUserLoggedIn) {
      _error = 'You need to be logged in to remove items from your cart';
      notifyListeners();
      return false;
    }
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final success = await _firestoreService.removeFromCart(cartItemId);
      
      if (success) {
        await loadCartItems();
      } else {
        _error = 'Failed to remove item from cart';
        _isLoading = false;
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      _error = 'Error removing item from cart: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Clear cart
  Future<bool> clearCart() async {
    if (!_firestoreService.isUserLoggedIn) {
      _error = 'You need to be logged in to clear your cart';
      notifyListeners();
      return false;
    }
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final success = await _firestoreService.clearCart();
      
      if (success) {
        _cartItems = [];
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Error clearing cart: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Create order from cart
  Future<String?> createOrder(String shippingAddress) async {
    if (!_firestoreService.isUserLoggedIn) {
      _error = 'You need to be logged in to create an order';
      notifyListeners();
      return null;
    }
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final orderId = await _firestoreService.createOrderFromCart(shippingAddress);
      
      if (orderId != null) {
        _cartItems = [];
      }
      
      _isLoading = false;
      notifyListeners();
      return orderId;
    } catch (e) {
      _error = 'Error creating order: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
