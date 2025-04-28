import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../Widgets/book_card.dart';
import 'book_details_screen.dart';
import 'sell_book_screen.dart';

class FirestoreBooksScreen extends StatefulWidget {
  const FirestoreBooksScreen({super.key});

  @override
  State<FirestoreBooksScreen> createState() => _FirestoreBooksScreenState();
}

class _FirestoreBooksScreenState extends State<FirestoreBooksScreen> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  Stream<QuerySnapshot>? _booksStream;
  List<DocumentSnapshot>? _searchResults;
  bool _isSearching = false;
  String _selectedCondition = 'All';
  final List<String> _conditions = ['All', 'New', 'Like New', 'Good', 'Fair', 'Poor'];

  @override
  void initState() {
    super.initState();
    _booksStream = _firestoreService.getAllBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchBooks(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = null;
        if (_selectedCondition == 'All') {
          _booksStream = _firestoreService.getAllBooks();
        } else {
          _booksStream = _firestoreService.getBooksByCondition(_selectedCondition);
        }
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await _firestoreService.searchBooks(query);

    setState(() {
      _searchResults = results;
    });
  }

  void _selectCondition(String condition) {
    setState(() {
      _selectedCondition = condition;
      _searchResults = null;
      _isSearching = false;
      _searchController.clear();

      if (condition == 'All') {
        _booksStream = _firestoreService.getAllBooks();
      } else {
        _booksStream = _firestoreService.getBooksByCondition(condition);
      }
    });
  }

  void _handleBookTap(DocumentSnapshot book) {
    final bookData = book.data() as Map<String, dynamic>;
    bookData['id'] = book.id; // Add the document ID to the book data

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookDetailsScreen(book: bookData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SellBookScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search books by title or author',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _searchBooks,
            ),
          ),

          // Conditions
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _conditions.length,
              itemBuilder: (context, index) {
                final condition = _conditions[index];
                final isSelected = condition == _selectedCondition;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(condition),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _selectCondition(condition);
                      }
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.7),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                );
              },
            ),
          ),

          // Books List
          Expanded(
            child: _isSearching
                ? _buildSearchResultsList()
                : _buildBooksStreamList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList() {
    if (_searchResults == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No books found',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            Text(
              'Try a different search or condition',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) {
        final doc = _searchResults![index];
        final book = doc.data() as Map<String, dynamic>;

        // Create a description that includes location if available
        String description = book['description'] ?? book['condition'] ?? 'No description';
        if (book['location'] != null) {
          description = '$description\nLocation: ${book['location']}';
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: LargeBookCard(
            title: book['title'] ?? 'No Title',
            author: book['author'] ?? 'Unknown Author',
            imageUrl: book['imageUrl'] ?? 'https://via.placeholder.com/150',
            price: book['price'] is double
                ? book['price']
                : (book['price'] as num).toDouble(),
            rating: 5.0, // Default rating
            description: description,
            onTap: () => _handleBookTap(doc),
          ),
        );
      },
    );
  }

  Widget _buildBooksStreamList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _booksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('Error in StreamBuilder: ${snapshot.error}');

          // Check if it's a permission error
          final errorMessage = snapshot.error.toString();
          if (errorMessage.contains('permission-denied') || errorMessage.contains('Missing or insufficient permissions')) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Firestore Permission Error',
                    style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'Your Firestore security rules need to be updated to allow reading books.',
                      style: TextStyle(color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try with Sample Data'),
                    onPressed: () async {
                      // Create sample data and retry
                      await _firestoreService.createSampleBooksIfNeeded();
                      setState(() {
                        if (_selectedCondition == 'All') {
                          _booksStream = _firestoreService.getAllBooks();
                        } else {
                          _booksStream = _firestoreService.getBooksByCondition(_selectedCondition);
                        }
                      });
                    },
                  ),
                ],
              ),
            );
          }

          // For other errors
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error loading books',
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    '${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  onPressed: () {
                    setState(() {
                      if (_selectedCondition == 'All') {
                        _booksStream = _firestoreService.getAllBooks();
                      } else {
                        _booksStream = _firestoreService.getBooksByCondition(_selectedCondition);
                      }
                    });
                  },
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No books found',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 16),
                Text(
                  'Try a different condition or add some books',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final books = snapshot.data!.docs;
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              if (_selectedCondition == 'All') {
                _booksStream = _firestoreService.getAllBooks();
              } else {
                _booksStream = _firestoreService.getBooksByCondition(_selectedCondition);
              }
            });
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final doc = books[index];
              final book = doc.data() as Map<String, dynamic>;

              // Create a description that includes location if available
              String description = book['description'] ?? book['condition'] ?? 'No description';
              if (book['location'] != null) {
                description = '$description\nLocation: ${book['location']}';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: LargeBookCard(
                  title: book['title'] ?? 'No Title',
                  author: book['author'] ?? 'Unknown Author',
                  imageUrl: book['imageUrl'] ?? 'https://via.placeholder.com/150',
                  price: book['price'] is double
                      ? book['price']
                      : (book['price'] as num).toDouble(),
                  rating: 5.0, // Default rating
                  description: description,
                  onTap: () => _handleBookTap(doc),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
