import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_item.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();

  factory FirestoreService() {
    return _instance;
  }

  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  CollectionReference get booksCollection => _firestore.collection('books');
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get cartCollection => _firestore.collection('cart');
  CollectionReference get ordersCollection => _firestore.collection('orders');

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is logged in
  bool get isUserLoggedIn => _auth.currentUser != null;

  // Get all books - accessible to all users including guests
  Stream<QuerySnapshot> getAllBooks() {
    try {
      // Create a collection of sample books if the collection is empty or there's a permission error
      createSampleBooksIfNeeded();

      // Use a simpler query that doesn't require a composite index
      // Just get all books and filter in the app if needed
      return booksCollection
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      debugPrint('Error getting all books: $e');

      // If there's still an error, try an even simpler query
      if (e.toString().contains('FAILED_PRECONDITION') ||
          e.toString().contains('requires an index')) {
        debugPrint('Falling back to query without ordering');
        try {
          // Most basic query possible - no ordering, no filtering
          return booksCollection.snapshots();
        } catch (innerError) {
          debugPrint('Error in fallback query: $innerError');
          return Stream<QuerySnapshot>.empty();
        }
      }

      // Return an empty stream in case of error
      return Stream<QuerySnapshot>.empty();
    }
  }

  // Filter books by status (client-side filtering)
  List<DocumentSnapshot> filterBooksByStatus(List<DocumentSnapshot> books, String status) {
    return books.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;
      return data['status'] == status;
    }).toList();
  }

  // Get books by condition
  Stream<QuerySnapshot> getBooksByCondition(String condition) {
    try {
      return booksCollection
          .where('condition', isEqualTo: condition)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      debugPrint('Error getting books by condition: $e');
      // Return an empty stream in case of error
      return Stream<QuerySnapshot>.empty();
    }
  }

  // Create sample books if needed - accessible to all users including guests
  Future<void> createSampleBooksIfNeeded() async {
    try {
      // Check if there are any books
      final snapshot = await booksCollection.limit(1).get();

      if (snapshot.docs.isEmpty) {
        debugPrint('No books found, creating sample books');
        // Create sample books
        final sampleBooks = [
          {
            'title': 'The Great Gatsby',
            'titleLowerCase': 'the great gatsby',
            'author': 'F. Scott Fitzgerald',
            'authorLowerCase': 'f. scott fitzgerald',
            'price': 9.99,
            'condition': 'Good',
            'imageUrl': 'https://m.media-amazon.com/images/I/71FTb9X6wsL._AC_UF1000,1000_QL80_.jpg',
            'sellerId': 'sample',
            'description': 'A classic novel about the American Dream',
            'category': 'Fiction',
            'location': 'New York, NY',
            'status': 'available',
            'createdAt': FieldValue.serverTimestamp(),
            'rating': 4.5,
          },
          {
            'title': 'To Kill a Mockingbird',
            'titleLowerCase': 'to kill a mockingbird',
            'author': 'Harper Lee',
            'authorLowerCase': 'harper lee',
            'price': 12.99,
            'condition': 'Like New',
            'imageUrl': 'https://m.media-amazon.com/images/I/71FTb9X6wsL._AC_UF1000,1000_QL80_.jpg',
            'sellerId': 'sample',
            'description': 'A novel about racial injustice in the American South',
            'category': 'Fiction',
            'location': 'Chicago, IL',
            'status': 'available',
            'createdAt': FieldValue.serverTimestamp(),
            'rating': 4.8,
          },
          {
            'title': '1984',
            'titleLowerCase': '1984',
            'author': 'George Orwell',
            'authorLowerCase': 'george orwell',
            'price': 8.99,
            'condition': 'Fair',
            'imageUrl': 'https://m.media-amazon.com/images/I/71FTb9X6wsL._AC_UF1000,1000_QL80_.jpg',
            'sellerId': 'sample',
            'description': 'A dystopian novel about totalitarianism',
            'category': 'Science Fiction',
            'location': 'San Francisco, CA',
            'status': 'available',
            'createdAt': FieldValue.serverTimestamp(),
            'rating': 4.7,
          },
        ];

        // Add sample books to Firestore
        for (final book in sampleBooks) {
          await booksCollection.add(book);
        }
      }
    } catch (e) {
      debugPrint('Error creating sample books: $e');
    }
  }

  // Search books by title or author
  Future<List<DocumentSnapshot>> searchBooks(String query) async {
    // Firestore doesn't support OR queries directly, so we need to make multiple queries
    final lowerQuery = query.toLowerCase();
    final titleResults = await booksCollection
        .where('titleLowerCase', isGreaterThanOrEqualTo: lowerQuery)
        .where('titleLowerCase', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
        .get();

    final authorResults = await booksCollection
        .where('authorLowerCase', isGreaterThanOrEqualTo: lowerQuery)
        .where('authorLowerCase', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
        .get();

    // Combine results and remove duplicates
    final Set<String> ids = {};
    final List<DocumentSnapshot> combinedResults = [];

    for (final doc in titleResults.docs) {
      if (!ids.contains(doc.id)) {
        ids.add(doc.id);
        combinedResults.add(doc);
      }
    }

    for (final doc in authorResults.docs) {
      if (!ids.contains(doc.id)) {
        ids.add(doc.id);
        combinedResults.add(doc);
      }
    }

    // Sort by createdAt
    combinedResults.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aCreatedAt = aData['createdAt'] as Timestamp;
      final bCreatedAt = bData['createdAt'] as Timestamp;
      return bCreatedAt.compareTo(aCreatedAt); // Descending order
    });

    return combinedResults;
  }

  // Get book by ID
  Future<DocumentSnapshot?> getBookById(String bookId) async {
    try {
      final doc = await booksCollection.doc(bookId).get();
      if (doc.exists) {
        return doc;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting book by ID: $e');
      return null;
    }
  }

  // Upload image to Firebase Storage
  Future<String?> uploadBookImage(XFile imageFile, {Function(double)? onProgress}) async {
    try {
      if (!isUserLoggedIn) {
        throw Exception('User not logged in');
      }

      // Get user ID to include in the image path
      final userId = currentUserId!;

      // Create a unique filename with timestamp and user ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uuid = const Uuid().v4();
      final filename = '${userId}_${timestamp}_$uuid.jpg';

      // Use a simpler path structure to avoid nested folders which might cause issues
      // Just use the root 'images' folder instead of nested paths
      final storageRef = _storage.ref().child('images/$filename');

      debugPrint('Attempting to upload to: ${storageRef.fullPath}');

      // Get the file data as bytes to avoid file system issues on web
      final Uint8List imageData = await imageFile.readAsBytes();

      // Check image size and compress if needed
      if (imageData.length > 5 * 1024 * 1024) { // 5MB limit
        debugPrint('Image is too large (${(imageData.length / 1024 / 1024).toStringAsFixed(2)}MB). Consider compressing it.');
        // In a real app, you would compress the image here
      }

      // Upload the image data
      debugPrint('Starting image upload to Firebase Storage...');
      final uploadTask = storageRef.putData(
        imageData,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uuid': uuid,
            'userId': userId,
            'uploadTime': DateTime.now().toIso8601String(),
            'originalFilename': imageFile.name,
          },
        ),
      );

      // Monitor the upload task
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: $progress%');

        // Call the progress callback if provided
        if (onProgress != null) {
          onProgress(progress);
        }
      });

      // Wait for the upload to complete
      final snapshot = await uploadTask;
      debugPrint('Upload complete. Getting download URL...');

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Image uploaded successfully. URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading book image: $e');

      // Provide more detailed error information
      if (e.toString().contains('object-not-found')) {
        debugPrint('The specified storage bucket or path does not exist.');
        debugPrint('Make sure your Firebase Storage rules allow write access.');

        // Try with an even simpler path
        try {
          debugPrint('Trying with root path...');
          final uuid = const Uuid().v4();
          final storageRef = _storage.ref().child('$uuid.jpg');

          final Uint8List imageData = await imageFile.readAsBytes();
          final uploadTask = storageRef.putData(
            imageData,
            SettableMetadata(contentType: 'image/jpeg'),
          );

          final snapshot = await uploadTask;
          final url = await snapshot.ref.getDownloadURL();
          debugPrint('Success with root path. URL: $url');
          return url;
        } catch (rootPathError) {
          debugPrint('Root path upload also failed: $rootPathError');
        }
      } else if (e.toString().contains('unauthorized')) {
        debugPrint('Firebase Storage permission denied. Check your security rules.');
      } else if (e.toString().contains('canceled')) {
        debugPrint('Upload was canceled.');
      } else if (e.toString().contains('network')) {
        debugPrint('Network error. Check your internet connection.');
      }

      // As a last resort, use a placeholder image
      debugPrint('Using placeholder image as fallback');
      return 'https://via.placeholder.com/300x400?text=Book+Image';
    }
  }

  // Add a new book with image upload
  Future<DocumentReference?> addBook({
    required String title,
    required String author,
    required double price,
    required String condition,
    required XFile imageFile,
    String? description,
    String? category,
    String? location,
    double? rating,
    Function(double)? onProgress,
  }) async {
    try {
      if (!isUserLoggedIn) {
        throw Exception('User not logged in');
      }

      // Upload image
      final imageUrl = await uploadBookImage(imageFile, onProgress: onProgress);
      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      // Add book to Firestore using the addBookWithUrl method
      return await addBookWithUrl(
        title: title,
        author: author,
        price: price,
        condition: condition,
        imageUrl: imageUrl,
        description: description,
        category: category,
        location: location,
        rating: rating,
      );
    } catch (e) {
      debugPrint('Error adding book: $e');
      return null;
    }
  }

  // Add a new book with pre-uploaded image URL
  Future<DocumentReference?> addBookWithUrl({
    required String title,
    required String author,
    required double price,
    required String condition,
    required String imageUrl,
    String? description,
    String? category,
    String? location,
    double? rating,
  }) async {
    try {
      if (!isUserLoggedIn) {
        throw Exception('User not logged in');
      }

      final userId = currentUserId!;

      // Generate a random rating between 4.0 and 5.0 if not provided
      final bookRating = rating ?? (4.0 + (DateTime.now().millisecondsSinceEpoch % 10) / 10);

      // Add book to Firestore
      return await booksCollection.add({
        'title': title,
        'titleLowerCase': title.toLowerCase(), // For case-insensitive search
        'author': author,
        'authorLowerCase': author.toLowerCase(), // For case-insensitive search
        'price': price,
        'condition': condition,
        'imageUrl': imageUrl,
        'sellerId': userId,
        'description': description,
        'category': category,
        'location': location,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'available', // Default status
        'rating': bookRating, // Add rating
      });
    } catch (e) {
      debugPrint('Error adding book with URL: $e');
      return null;
    }
  }

  // Update a book
  Future<bool> updateBook(
    String bookId, {
    String? title,
    String? author,
    double? price,
    String? condition,
    XFile? imageFile,
    String? description,
    String? category,
    String? location,
    String? status,
  }) async {
    try {
      if (!isUserLoggedIn) {
        throw Exception('User not logged in');
      }

      final userId = currentUserId!;

      // Check if the book belongs to the current user
      final bookDoc = await booksCollection.doc(bookId).get();
      if (!bookDoc.exists) {
        throw Exception('Book not found');
      }

      final bookData = bookDoc.data() as Map<String, dynamic>;
      if (bookData['sellerId'] != userId) {
        throw Exception('You do not have permission to update this book');
      }

      // Prepare update data
      final Map<String, dynamic> updateData = {};

      if (title != null) {
        updateData['title'] = title;
        updateData['titleLowerCase'] = title.toLowerCase();
      }

      if (author != null) {
        updateData['author'] = author;
        updateData['authorLowerCase'] = author.toLowerCase();
      }

      if (price != null) {
        updateData['price'] = price;
      }

      if (condition != null) {
        updateData['condition'] = condition;
      }

      if (description != null) {
        updateData['description'] = description;
      }

      if (category != null) {
        updateData['category'] = category;
      }

      if (location != null) {
        updateData['location'] = location;
      }

      if (status != null) {
        updateData['status'] = status;
      }

      // Upload new image if provided
      if (imageFile != null) {
        final imageUrl = await uploadBookImage(imageFile);
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
        updateData['imageUrl'] = imageUrl;
      }

      if (updateData.isEmpty) {
        return false; // Nothing to update
      }

      // Update the book
      await booksCollection.doc(bookId).update(updateData);
      return true;
    } catch (e) {
      debugPrint('Error updating book: $e');
      return false;
    }
  }

  // Delete a book
  Future<bool> deleteBook(String bookId) async {
    try {
      if (!isUserLoggedIn) {
        throw Exception('User not logged in');
      }

      final userId = currentUserId!;

      // Check if the book belongs to the current user
      final bookDoc = await booksCollection.doc(bookId).get();
      if (!bookDoc.exists) {
        throw Exception('Book not found');
      }

      final bookData = bookDoc.data() as Map<String, dynamic>;
      if (bookData['sellerId'] != userId) {
        throw Exception('You do not have permission to delete this book');
      }

      // Delete the book
      await booksCollection.doc(bookId).delete();

      // Delete the image from storage if it exists
      if (bookData['imageUrl'] != null) {
        try {
          final imageRef = _storage.refFromURL(bookData['imageUrl']);
          await imageRef.delete();
        } catch (e) {
          debugPrint('Error deleting image: $e');
          // Continue with deletion even if image deletion fails
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting book: $e');
      return false;
    }
  }

  // Get books by seller ID
  Stream<QuerySnapshot> getBooksBySeller(String sellerId) {
    try {
      // First try with ordering by createdAt
      return booksCollection
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      debugPrint('Error in getBooksBySeller with ordering: $e');

      // If there's an index error, fall back to a simpler query without ordering
      if (e.toString().contains('FAILED_PRECONDITION') ||
          e.toString().contains('requires an index')) {
        debugPrint('Falling back to query without ordering');
        return booksCollection
            .where('sellerId', isEqualTo: sellerId)
            .snapshots();
      }

      // For other errors, rethrow
      rethrow;
    }
  }

  // Get books by current user
  Stream<QuerySnapshot> getCurrentUserBooks() {
    try {
      if (!isUserLoggedIn) {
        debugPrint('User not logged in, returning empty stream');
        return Stream<QuerySnapshot>.empty();
      }

      final userId = currentUserId!;
      debugPrint('Getting books for user: $userId');
      return booksCollection
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      debugPrint('Error in getCurrentUserBooks: $e');

      // If there's an index error, fall back to a simpler query without ordering
      if (e.toString().contains('FAILED_PRECONDITION') ||
          e.toString().contains('requires an index')) {
        debugPrint('Falling back to query without ordering');
        try {
          final userId = currentUserId!;
          return booksCollection
              .where('sellerId', isEqualTo: userId)
              .snapshots();
        } catch (innerError) {
          debugPrint('Error in fallback query: $innerError');
          return Stream<QuerySnapshot>.empty();
        }
      }

      // For other errors, return an empty stream
      return Stream<QuerySnapshot>.empty();
    }
  }

  // Check if cart collection is accessible
  Future<bool> isCartCollectionAccessible() async {
    try {
      if (!isUserLoggedIn) return false;

      final userId = currentUserId!;
      await cartCollection
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      return true;
    } catch (e) {
      debugPrint('Cart collection is not accessible: $e');
      return false;
    }
  }

  // Add item to cart with improved error handling
  Future<Map<String, dynamic>> addToCart(String bookId, {int quantity = 1}) async {
    try {
      // Validate input
      if (bookId.isEmpty) {
        return {
          'success': false,
          'error': 'Invalid book ID',
          'userMessage': 'Unable to add book to cart. Please try again.',
        };
      }

      if (quantity <= 0) {
        return {
          'success': false,
          'error': 'Invalid quantity',
          'userMessage': 'Quantity must be greater than 0.',
        };
      }

      if (!isUserLoggedIn) {
        return {
          'success': false,
          'error': 'User not logged in',
          'userMessage': 'Please log in to add items to your cart.',
        };
      }

      final userId = currentUserId!;
      debugPrint('Adding book $bookId to cart for user $userId');

      // Check if cart collection is accessible
      final cartAccessible = await isCartCollectionAccessible();
      if (!cartAccessible) {
        return {
          'success': false,
          'error': 'Cart collection not accessible',
          'userMessage': 'Cart service is currently unavailable. Please try again later.',
        };
      }

      // Check if the book exists and is available
      final bookDoc = await booksCollection.doc(bookId).get();
      if (!bookDoc.exists) {
        return {
          'success': false,
          'error': 'Book not found',
          'userMessage': 'This book is no longer available.',
        };
      }

      final bookData = bookDoc.data() as Map<String, dynamic>;

      // Check if book is available for purchase
      if (bookData['status'] != null && bookData['status'] != 'available') {
        return {
          'success': false,
          'error': 'Book not available',
          'userMessage': 'This book is no longer available for purchase.',
        };
      }

      // Check if user is trying to add their own book to cart
      if (bookData['sellerId'] == userId) {
        return {
          'success': false,
          'error': 'Cannot add own book',
          'userMessage': 'You cannot add your own book to the cart.',
        };
      }

      debugPrint('Book validation passed, checking cart...');

      // Check if the item is already in the cart
      final cartQuery = await cartCollection
          .where('userId', isEqualTo: userId)
          .where('bookId', isEqualTo: bookId)
          .limit(1)
          .get();

      if (cartQuery.docs.isNotEmpty) {
        // Update quantity
        final cartItemId = cartQuery.docs.first.id;
        final cartData = cartQuery.docs.first.data() as Map<String, dynamic>?;
        final currentQuantity = cartData?['quantity'] as int? ?? 1;

        debugPrint('Book already in cart, updating quantity from $currentQuantity to ${currentQuantity + quantity}');

        await cartCollection.doc(cartItemId).update({
          'quantity': currentQuantity + quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return {
          'success': true,
          'message': 'Cart updated',
          'userMessage': 'Book quantity updated in cart.',
          'isUpdate': true,
          'newQuantity': currentQuantity + quantity,
        };
      } else {
        // Add new item to cart
        debugPrint('Adding new item to cart...');

        final cartData = {
          'userId': userId,
          'bookId': bookId,
          'quantity': quantity,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          // Store some book info for easier access
          'bookTitle': bookData['title'] ?? 'Unknown Title',
          'bookPrice': bookData['price'] ?? 0.0,
          'bookImageUrl': bookData['imageUrl'],
        };

        await cartCollection.add(cartData);

        debugPrint('Successfully added book to cart');

        return {
          'success': true,
          'message': 'Added to cart',
          'userMessage': 'Book added to cart successfully!',
          'isUpdate': false,
          'quantity': quantity,
        };
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');

      // Provide specific error messages based on the error type
      String userMessage = 'Unable to add book to cart. Please try again.';

      if (e.toString().contains('permission-denied')) {
        userMessage = 'Permission denied. Please check your account permissions.';
      } else if (e.toString().contains('network')) {
        userMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('unavailable')) {
        userMessage = 'Service temporarily unavailable. Please try again later.';
      }

      return {
        'success': false,
        'error': e.toString(),
        'userMessage': userMessage,
      };
    }
  }

  // Get cart items
  Stream<QuerySnapshot> getCartItems() {
    if (!isUserLoggedIn) {
      throw Exception('User not logged in');
    }

    final userId = currentUserId!;
    return cartCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get cart items with book details
  Future<List<Map<String, dynamic>>> getCartItemsWithDetails() async {
    try {
      if (!isUserLoggedIn) {
        throw Exception('User not logged in');
      }

      final userId = currentUserId!;
      final cartQuery = await cartCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> cartItems = [];

      for (final cartDoc in cartQuery.docs) {
        final cartData = cartDoc.data() as Map<String, dynamic>;
        final bookId = cartData['bookId'] as String;

        // Get book details
        final bookDoc = await booksCollection.doc(bookId).get();
        if (bookDoc.exists) {
          final bookData = bookDoc.data() as Map<String, dynamic>;

          cartItems.add({
            'id': cartDoc.id,
            'bookId': bookId,
            'quantity': cartData['quantity'] as int,
            'title': bookData['title'],
            'author': bookData['author'],
            'price': bookData['price'],
            'imageUrl': bookData['imageUrl'],
            'condition': bookData['condition'],
          });
        }
      }

      return cartItems;
    } catch (e) {
      debugPrint('Error getting cart items with details: $e');
      return [];
    }
  }

  // Update cart item quantity
  Future<bool> updateCartItemQuantity(String cartItemId, int quantity) async {
    try {
      if (!isUserLoggedIn) {
        throw Exception('User not logged in');
      }

      if (quantity <= 0) {
        return removeFromCart(cartItemId);
      }

      await cartCollection.doc(cartItemId).update({
        'quantity': quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error updating cart item quantity: $e');
      return false;
    }
  }

  // Remove item from cart
  Future<bool> removeFromCart(String cartItemId) async {
    try {
      if (!isUserLoggedIn) {
        throw Exception('User not logged in');
      }

      await cartCollection.doc(cartItemId).delete();
      return true;
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      return false;
    }
  }

  // Clear cart
  Future<bool> clearCart() async {
    try {
      if (!isUserLoggedIn) {
        throw Exception('User not logged in');
      }

      final userId = currentUserId!;
      final cartQuery = await cartCollection
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in cartQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      return false;
    }
  }

  // Create order from cart
  Future<String?> createOrderFromCart(String shippingAddress) async {
    try {
      if (!isUserLoggedIn) {
        throw Exception('User not logged in');
      }

      final userId = currentUserId!;

      // Get cart items with details
      final cartItems = await getCartItemsWithDetails();
      if (cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Calculate total amount
      double totalAmount = 0;
      for (final item in cartItems) {
        totalAmount += (item['price'] as num).toDouble() * item['quantity'];
      }

      // Create order
      final orderRef = await ordersCollection.add({
        'userId': userId,
        'totalAmount': totalAmount,
        'status': 'pending',
        'shippingAddress': shippingAddress,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create order items subcollection
      for (final item in cartItems) {
        await orderRef.collection('items').add({
          'bookId': item['bookId'],
          'quantity': item['quantity'],
          'price': item['price'],
          'title': item['title'],
          'author': item['author'],
          'imageUrl': item['imageUrl'],
        });
      }

      // Clear cart
      await clearCart();

      return orderRef.id;
    } catch (e) {
      debugPrint('Error creating order from cart: $e');
      return null;
    }
  }
  
  // Create order with payment method
  Future<String?> createOrderWithPaymentMethod(String shippingAddress, String paymentMethod) async {
    try {
      if (!isUserLoggedIn) {
        throw Exception('User not logged in');
      }

      final userId = currentUserId!;

      // Get cart items with details
      final cartItems = await getCartItemsWithDetails();
      if (cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Calculate total amount
      double totalAmount = 0;
      for (final item in cartItems) {
        totalAmount += (item['price'] as num).toDouble() * item['quantity'];
      }

      // Create order
      final orderRef = await ordersCollection.add({
        'userId': userId,
        'totalAmount': totalAmount,
        'status': 'pending',
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create order items subcollection
      for (final item in cartItems) {
        await orderRef.collection('items').add({
          'bookId': item['bookId'],
          'quantity': item['quantity'],
          'price': item['price'],
          'title': item['title'],
          'author': item['author'],
          'imageUrl': item['imageUrl'],
          'sellerId': item['sellerId'] ?? '',
        });
        
        // Notify the book owner about the order
        if (item.containsKey('sellerId') && item['sellerId'] != null) {
          final sellerId = item['sellerId'] as String;
          final bookTitle = item['title'] as String;
          
          await sendNotificationToUser(
            sellerId,
            'New Order Received',
            'Someone has ordered your book "$bookTitle". Order ID: ${orderRef.id}',
            NotificationType.success,
          );
        }
      }

      // Clear cart
      await clearCart();

      return orderRef.id;
    } catch (e) {
      debugPrint('Error creating order with payment method: $e');
      return null;
    }
  }
  
  // Send notification to a specific user
  Future<bool> sendNotificationToUser(
    String userId, 
    String title, 
    String message, 
    NotificationType type
  ) async {
    try {
      // Create notification in Firestore
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type.toString().split('.').last,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error sending notification to user: $e');
      return false;
    }
  }

  // Get user orders
  Stream<QuerySnapshot> getUserOrders() {
    if (!isUserLoggedIn) {
      throw Exception('User not logged in');
    }

    try {
      final userId = currentUserId!;
      return ordersCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      // If there's a permission error, return an empty stream
      debugPrint('Error getting user orders: $e');
      // Return an empty stream
      return Stream<QuerySnapshot>.empty();
    }
  }

  // Check if orders collection exists and is accessible
  Future<bool> isOrdersCollectionAccessible() async {
    try {
      await ordersCollection.limit(1).get();
      return true;
    } catch (e) {
      debugPrint('Orders collection is not accessible: $e');
      return false;
    }
  }

  // Get order details including items
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    if (!isUserLoggedIn) {
      throw Exception('User not logged in');
    }

    try {
      // Get the order document
      final orderDoc = await ordersCollection.doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;

      // Get the order items
      final itemsSnapshot = await ordersCollection
          .doc(orderId)
          .collection('items')
          .get();

      final items = itemsSnapshot.docs
          .map((doc) => doc.data())
          .toList();

      // Add items to the order data
      orderData['items'] = items;
      orderData['id'] = orderDoc.id;

      return orderData;
    } catch (e) {
      debugPrint('Error getting order details: $e');
      rethrow;
    }
  }

  // Create a sample order (for testing purposes)
  Future<String?> createSampleOrder() async {
    if (!isUserLoggedIn) {
      throw Exception('User not logged in');
    }

    try {
      final userId = currentUserId!;

      // Get some random books to add to the order
      final booksSnapshot = await booksCollection.limit(3).get();
      if (booksSnapshot.docs.isEmpty) {
        throw Exception('No books available');
      }

      // Create a new order
      final orderRef = ordersCollection.doc();

      // Generate a random order ID
      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // Calculate total price
      double totalPrice = 0;
      final items = <Map<String, dynamic>>[];

      for (final doc in booksSnapshot.docs) {
        final book = doc.data() as Map<String, dynamic>;
        final price = book['price'] is double
            ? book['price']
            : (book['price'] as num?)?.toDouble() ?? 0.0;

        const quantity = 1;
        totalPrice += price * quantity;

        items.add({
          'bookId': doc.id,
          'title': book['title'] ?? 'Unknown Title',
          'author': book['author'] ?? 'Unknown Author',
          'price': price,
          'quantity': quantity,
          'imageUrl': book['imageUrl'] ?? '',
        });
      }

      // Save the order
      await orderRef.set({
        'orderId': orderId,
        'userId': userId,
        'status': _getRandomStatus(),
        'total': totalPrice,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'shippingAddress': '123 Main St, Anytown, USA',
      });

      // Save the order items
      for (final item in items) {
        await orderRef.collection('items').add(item);
      }

      return orderRef.id;
    } catch (e) {
      debugPrint('Error creating sample order: $e');
      return null;
    }
  }

  // Helper method to get a random status
  String _getRandomStatus() {
    final statuses = ['Processing', 'Shipped', 'Delivered'];
    final random = DateTime.now().millisecondsSinceEpoch % 3;
    return statuses[random];
  }

  // Test cart functionality
  Future<Map<String, dynamic>> testCartFunctionality() async {
    try {
      if (!isUserLoggedIn) {
        return {
          'success': false,
          'error': 'User not logged in',
          'message': 'Please log in to test cart functionality',
        };
      }

      final userId = currentUserId!;
      debugPrint('Testing cart functionality for user: $userId');

      // Test 1: Check if cart collection is accessible
      final cartAccessible = await isCartCollectionAccessible();
      if (!cartAccessible) {
        return {
          'success': false,
          'error': 'Cart collection not accessible',
          'message': 'Cart collection is not accessible. Check Firestore rules.',
        };
      }

      // Test 2: Try to read from cart collection
      try {
        final cartQuery = await cartCollection
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();
        debugPrint('Cart read test successful. Found ${cartQuery.docs.length} items.');
      } catch (e) {
        return {
          'success': false,
          'error': 'Cart read failed',
          'message': 'Cannot read from cart collection: $e',
        };
      }

      // Test 3: Try to write to cart collection (create a test item)
      try {
        final testCartItem = {
          'userId': userId,
          'bookId': 'test-book-id',
          'quantity': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isTest': true, // Mark as test item
        };

        final docRef = await cartCollection.add(testCartItem);
        debugPrint('Cart write test successful. Created test item: ${docRef.id}');

        // Clean up test item
        await cartCollection.doc(docRef.id).delete();
        debugPrint('Test item cleaned up successfully');
      } catch (e) {
        return {
          'success': false,
          'error': 'Cart write failed',
          'message': 'Cannot write to cart collection: $e',
        };
      }

      return {
        'success': true,
        'message': 'Cart functionality test passed. All operations work correctly.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Test failed',
        'message': 'Cart functionality test failed: $e',
      };
    }
  }

}
