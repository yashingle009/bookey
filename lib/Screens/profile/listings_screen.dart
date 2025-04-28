import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../Widgets/shimmer_loading.dart';
import '../sell.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  late TabController _tabController;

  bool _isLoading = true;
  List<DocumentSnapshot> _activeListings = [];
  List<DocumentSnapshot> _soldListings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        // Get the user's listings from Firestore
        final snapshot = await _firestoreService.getCurrentUserBooks().first;

        final allBooks = snapshot.docs;
        if (allBooks.isNotEmpty) {
          // Filter active and sold listings
          _activeListings = allBooks
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['status'] == 'available';
              })
              .toList();

          _soldListings = allBooks
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['status'] == 'sold';
              })
              .toList();
        } else {
          _activeListings = [];
          _soldListings = [];
        }
      }
    } catch (e) {
      debugPrint('Error loading listings: $e');

      // If there's an error, show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading listings: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteListing(String bookId, int index) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text('Are you sure you want to delete this listing? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteListing(bookId, index);
    }
  }

  Future<void> _deleteListing(String bookId, int index) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Delete the book from Firestore
      final success = await _firestoreService.deleteBook(bookId);

      if (success && mounted) {
        // Remove from local list
        setState(() {
          _activeListings.removeAt(index);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete listing'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting listing: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToSellForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Sell(),
      ),
    ).then((_) => _loadListings()); // Refresh listings when returning from sell form
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Sold'),
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
          : RefreshIndicator(
              onRefresh: _loadListings,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Active Listings
                  _activeListings.isEmpty
                      ? _buildEmptyState('No active listings', 'Books you are selling will appear here')
                      : _buildListingsGrid(_activeListings, true),

                  // Sold Listings
                  _soldListings.isEmpty
                      ? _buildEmptyState('No sold listings', 'Books you have sold will appear here')
                      : _buildListingsGrid(_soldListings, false),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToSellForm,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _navigateToSellForm,
                icon: const Icon(Icons.add),
                label: const Text('Sell a Book'),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _loadListings,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListingsGrid(List<DocumentSnapshot> listings, bool isActive) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final doc = listings[index];
        final book = doc.data() as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book cover
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    book['imageUrl'] ?? 'https://via.placeholder.com/150',
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(Icons.book, color: Colors.grey),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Book details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book['author'] ?? 'Unknown Author',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${(book['price'] is double ? book['price'] : (book['price'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Sold',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isActive) ...[
                            TextButton(
                              onPressed: () {
                                // Edit listing
                              },
                              child: const Text('Edit'),
                            ),
                            TextButton(
                              onPressed: () => _confirmDeleteListing(doc.id, index),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ] else ...[
                            TextButton(
                              onPressed: () {
                                // View details
                              },
                              child: const Text('View Details'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
