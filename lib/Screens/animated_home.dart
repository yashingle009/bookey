import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../Widgets/book_card.dart';
import '../Widgets/category_card.dart';
import '../Widgets/book_carousel.dart';
import '../Widgets/section_title.dart';
import '../Widgets/custom_app_bar.dart';
import '../Widgets/shimmer_loading.dart';
import '../Widgets/notification_overlay.dart';
import '../utils/animations.dart';
import '../utils/page_transitions.dart';
import '../services/firestore_service.dart';
import '../models/notification_item.dart';
import '../providers/notification_provider.dart';
import 'category_details.dart';
import 'book_details_screen.dart';

class AnimatedHome extends StatefulWidget {
  const AnimatedHome({super.key});

  @override
  State<AnimatedHome> createState() => _AnimatedHomeState();
}

class _AnimatedHomeState extends State<AnimatedHome> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isSearchLoading = false;
  final FirestoreService _firestoreService = FirestoreService();
  Stream<QuerySnapshot>? _booksStream;
  List<DocumentSnapshot> _searchResults = [];

  // Sample data for categories
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Fiction',
      'icon': Icons.auto_stories,
      'color': Colors.blue,
    },
    {
      'name': 'Non-Fiction',
      'icon': Icons.menu_book,
      'color': Colors.green,
    },
    {
      'name': 'Science',
      'icon': Icons.science,
      'color': Colors.purple,
    },
    {
      'name': 'Devotional',
      'icon': Icons.church,
      'color': Colors.orange,
    },
    {
      'name': 'Biography',
      'icon': Icons.person,
      'color': Colors.red,
    },
    {
      'name': 'History',
      'icon': Icons.history_edu,
      'color': Colors.brown,
    },
    {
      'name': 'Fantasy',
      'icon': Icons.castle,
      'color': Colors.indigo,
    },
    {
      'name': 'Romance',
      'icon': Icons.favorite,
      'color': Colors.pink,
    },
  ];

  // Sample data for top books
  final List<Map<String, dynamic>> _topBooks = [
    {
      'title': 'The Silent Patient',
      'author': 'Alex Michaelides',
      'imageUrl': 'https://m.media-amazon.com/images/I/91lslnZ-btL._AC_UF1000,1000_QL80_.jpg',
      'price': 12.99,
      'rating': 4.6,
      'description': 'A psychological thriller about a woman who shoots her husband and then stops speaking.',
    },
    {
      'title': 'Atomic Habits',
      'author': 'James Clear',
      'imageUrl': 'https://m.media-amazon.com/images/I/81wgcld4wxL._AC_UF1000,1000_QL80_.jpg',
      'price': 14.99,
      'rating': 4.8,
      'description': 'A guide to building good habits and breaking bad ones.',
    },
    {
      'title': 'Dune',
      'author': 'Frank Herbert',
      'imageUrl': 'https://m.media-amazon.com/images/I/A1u+2fY5yTL._AC_UF1000,1000_QL80_.jpg',
      'price': 10.99,
      'rating': 4.7,
      'description': 'A science fiction novel set in a distant future amidst a feudal interstellar society.',
    },
    {
      'title': 'The Alchemist',
      'author': 'Paulo Coelho',
      'imageUrl': 'https://m.media-amazon.com/images/I/51Z0nLAfLmL.jpg',
      'price': 9.99,
      'rating': 4.5,
      'description': 'A philosophical novel about a young Andalusian shepherd who dreams of finding treasure.',
    },
  ];

  // Sample data for books near you
  final List<Map<String, dynamic>> _nearbyBooks = [
    {
      'title': 'To Kill a Mockingbird',
      'author': 'Harper Lee',
      'imageUrl': 'https://m.media-amazon.com/images/I/71FxgtFKcQL._AC_UF1000,1000_QL80_.jpg',
      'price': 8.99,
      'rating': 4.8,
      'description': 'A novel about racial inequality and moral growth in the American South.',
      'distance': '0.8 miles away',
    },
    {
      'title': '1984',
      'author': 'George Orwell',
      'imageUrl': 'https://m.media-amazon.com/images/I/71kxa1-0mfL._AC_UF1000,1000_QL80_.jpg',
      'price': 7.99,
      'rating': 4.7,
      'description': 'A dystopian novel set in a totalitarian society.',
      'distance': '1.2 miles away',
    },
    {
      'title': 'The Great Gatsby',
      'author': 'F. Scott Fitzgerald',
      'imageUrl': 'https://m.media-amazon.com/images/I/71FTb9X6wsL._AC_UF1000,1000_QL80_.jpg',
      'price': 6.99,
      'rating': 4.5,
      'description': 'A novel about the American Dream and the Roaring Twenties.',
      'distance': '1.5 miles away',
    },
    {
      'title': 'Pride and Prejudice',
      'author': 'Jane Austen',
      'imageUrl': 'https://m.media-amazon.com/images/I/71Q1tPupKjL._AC_UF1000,1000_QL80_.jpg',
      'price': 5.99,
      'rating': 4.6,
      'description': 'A romantic novel about the Bennet family and Mr. Darcy.',
      'distance': '2.0 miles away',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();

    // Initialize books stream
    _booksStream = _firestoreService.getAllBooks();

    // Set loading to false after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleCategoryTap(int index) {
    final category = _categories[index];
    Navigator.push(
      context,
      AppPageTransition.slideRightTransition(
        CategoryDetails(
          categoryName: category['name'],
          categoryIcon: category['icon'],
          categoryColor: category['color'],
        ),
      ),
    );
  }

  void _handleBookTap(int index, String source) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$source: ${index == -1 ? 'Book' : _topBooks[index]['title']} tapped')),
    );
  }

  void _navigateToBookDetails(DocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailsScreen(bookId: doc.id),
      ),
    );
  }

  void _toggleNotifications() {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    notificationProvider.toggleNotificationOverlay();
  }

  void _handleNotificationTap(NotificationItem notification) {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    // Mark as read
    notificationProvider.markAsRead(notification.id);

    // Close notification panel
    notificationProvider.toggleNotificationOverlay();

    // Show a snackbar to confirm the action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification: ${notification.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Perform search using Firestore
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearchLoading = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearchLoading = true;
      _isSearching = true;
    });

    try {
      // Only search if query is at least 2 characters
      if (query.length >= 2) {
        final results = await _firestoreService.searchBooks(query);
        setState(() {
          _searchResults = results;
          _isSearchLoading = false;
        });
      } else {
        setState(() {
          _searchResults = [];
          _isSearchLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching books: $e');
      setState(() {
        _searchResults = [];
        _isSearchLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Animated SliverAppBar
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: FadeTransition(
                opacity: _animationController,
                child: const Text(
                  'Bookey',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.7),
                      Theme.of(context).primaryColor,
                    ],
                  ),
                ),
              ),
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
            ),
            actions: [
              Consumer<NotificationProvider>(
                builder: (ctx, notificationProvider, _) => Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white),
                      onPressed: _toggleNotifications,
                    ),
                    // Notification badge
                    if (notificationProvider.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            notificationProvider.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Welcome Message
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: FadeTransition(
                opacity: _animationController,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(_animationController),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'Welcome to your book world!',
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        speed: const Duration(milliseconds: 50),
                      ),
                    ],
                    totalRepeatCount: 1,
                    displayFullTextOnTap: true,
                  ),
                ),
              ),
            ),
          ),

          // Modern Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FadeTransition(
                opacity: _animationController,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for books or authors',
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchResults = [];
                                        _isSearching = false;
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            if (value.isEmpty) {
                              setState(() {
                                _searchResults = [];
                                _isSearching = false;
                              });
                            } else {
                              _performSearch(value);
                            }
                          },
                        ),
                      ),
                      if (_isSearchLoading)
                        const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Search Results (shown when searching)
          if (_isSearching && _searchResults.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Search Results (${_searchResults.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchResults = [];
                              _isSearching = false;
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 300, // Fixed height for search results
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final doc = _searchResults[index];
                        final book = doc.data() as Map<String, dynamic>;
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _navigateToBookDetails(doc),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Book cover
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      book['imageUrl'] ?? 'https://via.placeholder.com/150',
                                      width: 70,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 70,
                                          height: 100,
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
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '\$${(book['price'] is double ? book['price'] : (book['price'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).primaryColor,
                                              ),
                                            ),
                                            if (book['location'] != null)
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on,
                                                    color: Colors.red,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    book['location'].toString().split(',').first,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Categories (hidden when showing search results)
          if (!_isSearching || _searchResults.isEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: _isLoading
                        ? _buildCategoryShimmer()
                        : AnimationLimiter(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                return AnimatedListItem(
                                  index: index,
                                  horizontalAnimation: true,
                                  child: CategoryCard(
                                    name: _categories[index]['name'],
                                    icon: _categories[index]['icon'],
                                    color: _categories[index]['color'],
                                    onTap: () => _handleCategoryTap(index),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),

          // Top Books (hidden when showing search results)
          if (!_isSearching || _searchResults.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        'Top Books',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _isLoading
                        ? _buildBookCarouselShimmer()
                        : FadeTransition(
                            opacity: _animationController,
                            child: BookCarousel(
                              books: _topBooks,
                              title: '',
                              onBookTap: (index) => _handleBookTap(index, 'Top Books'),
                            ),
                          ),
                  ],
                ),
              ),
            ),

          // Books Near You (hidden when showing search results)
          if (!_isSearching || _searchResults.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Books Near You',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _handleBookTap(-1, 'See All Books Near You'),
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                    ),
                  _isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: BookListShimmer(itemCount: 3),
                        )
                      : StreamBuilder<QuerySnapshot>(
                          stream: _booksStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }

                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text('No books available'),
                              );
                            }

                            final books = snapshot.data!.docs;
                            return AnimationLimiter(
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: books.length > 4 ? 4 : books.length, // Limit to 4 books
                                itemBuilder: (context, index) {
                                  final doc = books[index];
                                  final book = doc.data() as Map<String, dynamic>;

                                  // Create a description that includes location if available
                                  String description = book['description'] ?? book['condition'] ?? 'No description';
                                  if (book['location'] != null) {
                                    description = '$description\nLocation: ${book['location']}';
                                  }

                                  return AnimatedListItem(
                                    index: index,
                                    child: Padding(
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
                                        onTap: () => _navigateToBookDetails(doc),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),

      // Notification Overlay
      Consumer<NotificationProvider>(
        builder: (ctx, notificationProvider, _) {
          return notificationProvider.showNotificationOverlay
              ? NotificationOverlay(
                  notifications: notificationProvider.notifications,
                  onClose: _toggleNotifications,
                  onNotificationTap: _handleNotificationTap,
                )
              : const SizedBox.shrink();
        },
      ),
      ],
    ));
  }

  Widget _buildCategoryShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 6,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: CategoryShimmer(),
        );
      },
    );
  }

  Widget _buildBookCarouselShimmer() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return const SizedBox(
            width: 160,
            child: BookCardShimmer(),
          );
        },
      ),
    );
  }
}

// Search delegate for books
class BookSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> books;

  BookSearchDelegate(this.books);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filteredBooks = books.where((book) {
      return book['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
          book['author'].toString().toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (query.isEmpty) {
      return const Center(
        child: Text('Type to search for books'),
      );
    }

    if (filteredBooks.isEmpty) {
      return const Center(
        child: Text('No books found'),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        itemCount: filteredBooks.length,
        itemBuilder: (context, index) {
          final book = filteredBooks[index];
          return AnimatedListItem(
            index: index,
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  book['imageUrl'],
                  width: 50,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 70,
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, color: Colors.grey),
                    );
                  },
                ),
              ),
              title: Text(book['title']),
              subtitle: Text(book['author']),
              trailing: Text('\$${book['price'].toStringAsFixed(2)}'),
              onTap: () {
                // Handle book selection
                close(context, book);
              },
            ),
          );
        },
      ),
    );
  }
}
