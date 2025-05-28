import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../providers/cart_provider.dart';
import 'package:provider/provider.dart';

class BookSelectionScreen extends StatefulWidget {
  static const routeName = '/book-selection';

  const BookSelectionScreen({Key? key}) : super(key: key);

  @override
  State<BookSelectionScreen> createState() => _BookSelectionScreenState();
}

class _BookSelectionScreenState extends State<BookSelectionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _selectedBooks = [];
  List<DocumentSnapshot> _books = [];
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _firestoreService.getAllBooks().first;
      
      setState(() {
        _books = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading books: $e')),
        );
      }
    }
  }

  void _toggleBookSelection(DocumentSnapshot book) {
    final bookData = book.data() as Map<String, dynamic>;
    final bookId = book.id;
    
    setState(() {
      // Check if the book is already selected
      final existingIndex = _selectedBooks.indexWhere((b) => b['id'] == bookId);
      
      if (existingIndex >= 0) {
        // Remove the book if it's already selected
        _selectedBooks.removeAt(existingIndex);
      } else {
        // Add the book to selected books
        _selectedBooks.add({
          'id': bookId,
          'title': bookData['title'],
          'author': bookData['author'],
          'price': bookData['price'],
          'imageUrl': bookData['imageUrl'],
          'sellerId': bookData['sellerId'],
          'sellerName': bookData['sellerName'],
          'quantity': 1,
        });
      }
    });
  }

  void _addSelectedBooksToCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    for (final book in _selectedBooks) {
      cartProvider.addItem(
        bookId: book['id'],
        title: book['title'],
        author: book['author'],
        imageUrl: book['imageUrl'],
        price: book['price'].toDouble(),
      );
    }
    
    Navigator.of(context).pop(_selectedBooks);
  }

  void _filterBooks(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter books based on search query
    final filteredBooks = _searchQuery.isEmpty
        ? _books
        : _books.where((book) {
            final data = book.data() as Map<String, dynamic>;
            final title = data['title'].toString().toLowerCase();
            final author = data['author'].toString().toLowerCase();
            return title.contains(_searchQuery) || author.contains(_searchQuery);
          }).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Books'),
        actions: [
          if (_selectedBooks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  '${_selectedBooks.length} selected',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search books by title or author',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _filterBooks,
            ),
          ),
          
          // Book list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBooks.isEmpty
                    ? const Center(child: Text('No books found'))
                    : ListView.builder(
                        itemCount: filteredBooks.length,
                        itemBuilder: (ctx, i) {
                          final book = filteredBooks[i];
                          final data = book.data() as Map<String, dynamic>;
                          final bookId = book.id;
                          
                          // Check if this book is selected
                          final isSelected = _selectedBooks.any((b) => b['id'] == bookId);
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  data['imageUrl'] ?? '',
                                  width: 50,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 50,
                                      height: 70,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.book),
                                    );
                                  },
                                ),
                              ),
                              title: Text(
                                data['title'] ?? 'Unknown Title',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['author'] ?? 'Unknown Author'),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${(data['price'] as num).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleBookSelection(book),
                              ),
                              onTap: () => _toggleBookSelection(book),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedBooks.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _addSelectedBooksToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: Text(
                  'ADD ${_selectedBooks.length} BOOKS TO CART',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
    );
  }
}