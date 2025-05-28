import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/postgres_auth_service.dart';
import 'auth/login_screen.dart';

class BookDetailsScreen extends StatefulWidget {
  final String? bookId;
  final Map<String, dynamic>? book;

  const BookDetailsScreen({
    super.key,
    this.bookId,
    this.book,
  }) : assert(bookId != null || book != null, 'Either bookId or book must be provided');

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _book;

  @override
  void initState() {
    super.initState();
    _loadBookDetails();
  }

  Future<void> _loadBookDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _book = widget.book;
    });

    try {
      String bookId;

      // If bookId is provided directly, use it
      if (widget.bookId != null) {
        bookId = widget.bookId!;
      }
      // Otherwise, get it from the book map
      else if (widget.book != null && widget.book!['id'] != null) {
        bookId = widget.book!['id'];
      }
      // If neither is available, throw an error
      else {
        throw Exception('No book ID available');
      }

      final bookDetails = await _firestoreService.getBookById(bookId);

      if (bookDetails != null) {
        setState(() {
          _book = bookDetails.data() as Map<String, dynamic>;
          _book!['id'] = bookDetails.id; // Add the document ID to the book data
        });
      } else {
        setState(() {
          _error = 'Book not found';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading book details: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _bookNow() async {
    if (!_firestoreService.isUserLoggedIn) {
      // Show login dialog
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Login Required'),
          content: const Text('You need to login to book this item.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Login'),
            ),
          ],
        ),
      );

      if (result == true) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }

      return;
    }

    // Validate that we have a book with an ID
    if (_book == null || _book!['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to book this item. Book information is missing.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookId = _book!['id'] as String;
      debugPrint('Attempting to book $bookId');

      // Show payment method selection dialog
      final paymentMethod = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Credit Card'),
                onTap: () => Navigator.of(context).pop('credit_card'),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('Digital Wallet'),
                onTap: () => Navigator.of(context).pop('digital_wallet'),
              ),
              ListTile(
                leading: const Icon(Icons.money),
                title: const Text('Cash on Delivery'),
                onTap: () => Navigator.of(context).pop('cod'),
              ),
            ],
          ),
        ),
      );

      if (paymentMethod == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final result = await _firestoreService.addToCart(bookId);

      if (!mounted) return;

      final success = result['success'] as bool? ?? false;
      final userMessage = result['userMessage'] as String? ?? 'Unknown error occurred';

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Book reserved successfully! Payment method: ${paymentMethod == 'credit_card' ? 'Credit Card' : paymentMethod == 'digital_wallet' ? 'Digital Wallet' : 'Cash on Delivery'}')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'VIEW DETAILS',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Navigate to booking details screen
                debugPrint('Navigate to booking details');
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(userMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _bookNow,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('Exception in _addToCart: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Unexpected error: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: _bookNow,
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCartFunctionality() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _firestoreService.testCartFunctionality();

      if (!mounted) return;

      final success = result['success'] as bool? ?? false;
      final message = result['message'] as String? ?? 'Unknown result';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_book?['title'] ?? 'Book Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBookDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Book Image with Hero animation
                      Center(
                        child: Hero(
                          tag: 'book-image-${_book?['id'] ?? 'default'}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _book?['imageUrl'] ?? 'https://via.placeholder.com/150',
                              height: 300,
                              width: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 300,
                                  width: 200,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                          : null,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 300,
                                  width: 200,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Title
                      Text(
                        _book?['title'] ?? 'No Title',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Author
                      Text(
                        'by ${_book?['author'] ?? 'Unknown Author'}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Price and Condition
                      Row(
                        children: [
                          // Price
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '\$${_book?['price']?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Condition
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey[400]!),
                            ),
                            child: Text(
                              _book?['condition'] ?? 'Unknown Condition',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Description
                      if (_book?['description'] != null) ...[
                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _book!['description'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Category
                      if (_book?['category'] != null) ...[
                        Row(
                          children: [
                            Text(
                              'Category: ',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _book!['category'],
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Location
                      if (_book?['location'] != null) ...[
                        Row(
                          children: [
                            Text(
                              'Location: ',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _book!['location'],
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Seller Info
                      if (_book?['sellerId'] != null) ...[
                        Row(
                          children: [
                            Text(
                              'Seller ID: ',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _book!['sellerId'],
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Test Cart Functionality Button (for debugging)
                      if (_firestoreService.isUserLoggedIn) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _testCartFunctionality,
                            child: const Text(
                              'Test Cart Functionality',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Add to Cart Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _bookNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'BOOK NOW',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
