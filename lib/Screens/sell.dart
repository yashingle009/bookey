import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../Widgets/book_card.dart';
import 'sell_book_screen.dart';

class Sell extends StatefulWidget {
  const Sell({super.key});

  @override
  State<Sell> createState() => _SellState();
}

class _SellState extends State<Sell> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToSellForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SellBookScreen()),
    );

    if (result == true) {
      // Book was successfully listed, show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your book is now listed and visible to all users!'),
            backgroundColor: Colors.green,
          ),
        );

        // Force refresh the UI
        setState(() {});
      }
    }
  }

  void _showBookOptions(DocumentSnapshot book) {
    final bookData = book.data() as Map<String, dynamic>;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Listing'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit form
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit functionality coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Listing'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteBook(book.id, bookData['title']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteBook(String bookId, String title) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Book Listing'),
          content: Text('Are you sure you want to delete "$title"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        setState(() {
          _isLoading = true;
        });

        final success = await _firestoreService.deleteBook(bookId);

        setState(() {
          _isLoading = false;
        });

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Book listing deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete book listing'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting book listing: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Sell Books'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Listings'),
            Tab(text: 'Sold Books'),
          ],
        ),
        actions: [
          // Add a button to sell a new book
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Sell a Book',
            onPressed: _navigateToSellForm,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // My Listings Tab
                _buildMyListingsTab(),

                // Sold Books Tab (to be implemented)
                const Center(
                  child: Text('Sold books feature coming soon'),
                ),
              ],
            ),
    );
  }

  Widget _buildMyListingsTab() {
    if (!_firestoreService.isUserLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_circle,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Please log in to view your listings',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Log In'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getCurrentUserBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
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
                  'Error loading your listings',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    '${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                // Show special message for index errors
                if (snapshot.error.toString().contains('requires an index') ||
                    snapshot.error.toString().contains('FAILED_PRECONDITION')) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'This error is related to Firestore indexes. You need to create the required index in the Firebase console.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Create Index'),
                    onPressed: () {
                      // Extract the URL from the error message
                      final errorMsg = snapshot.error.toString();
                      final urlRegex = RegExp(r'https://console\.firebase\.google\.com[^\s]+');
                      final match = urlRegex.firstMatch(errorMsg);
                      if (match != null) {
                        final url = match.group(0);
                        // Open the URL in a browser
                        // This would typically use url_launcher package
                        debugPrint('Index creation URL: $url');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please create the index at: $url')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No books listed yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _navigateToSellForm,
                  child: const Text('Sell a Book'),
                ),
              ],
            ),
          );
        }

        final books = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final doc = books[index];
            final book = doc.data() as Map<String, dynamic>;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: LargeBookCard(
                title: book['title'] ?? 'No Title',
                author: book['author'] ?? 'Unknown Author',
                imageUrl: book['imageUrl'] ?? 'https://via.placeholder.com/150',
                price: book['price'] is double
                    ? book['price']
                    : (book['price'] as num).toDouble(),
                rating: 5.0, // Default rating
                description: book['description'] ?? book['condition'] ?? 'No description',
                onTap: () => _showBookOptions(doc),
              ),
            );
          },
        );
      },
    );
  }
}
