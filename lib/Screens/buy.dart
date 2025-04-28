import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../Widgets/book_card.dart';
import '../Widgets/category_card.dart';
import '../Widgets/section_title.dart';
import '../Widgets/filter_bottom_sheet.dart';
import '../Widgets/custom_app_bar.dart';
import '../Widgets/shimmer_loading.dart';
import '../utils/animations.dart';
import '../utils/page_transitions.dart';
import 'animated_book_detail_screen.dart';

class Buy extends StatefulWidget {
  const Buy({super.key});

  @override
  State<Buy> createState() => _BuyState();
}

class _BuyState extends State<Buy> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isLoading = true;
  late AnimationController _animationController;

  // Filters
  Map<String, dynamic> _filters = {
    'categories': [],
    'priceMin': null,
    'priceMax': null,
    'rating': 0.0,
    'availability': 'all',
    'sortBy': 'popularity',
  };

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
    {
      'name': 'Mystery',
      'icon': Icons.search,
      'color': Colors.teal,
    },
  ];

  // Sample data for books
  final List<Map<String, dynamic>> _allBooks = [
    {
      'title': 'The Silent Patient',
      'author': 'Alex Michaelides',
      'imageUrl': 'https://m.media-amazon.com/images/I/91lslnZ-btL._AC_UF1000,1000_QL80_.jpg',
      'price': 12.99,
      'rating': 4.6,
      'description': 'A psychological thriller about a woman who shoots her husband and then stops speaking.',
      'category': 'Fiction',
      'availability': 'in_stock',
      'publishDate': '2019-02-05',
    },
    {
      'title': 'Atomic Habits',
      'author': 'James Clear',
      'imageUrl': 'https://m.media-amazon.com/images/I/81wgcld4wxL._AC_UF1000,1000_QL80_.jpg',
      'price': 14.99,
      'rating': 4.8,
      'description': 'A guide to building good habits and breaking bad ones.',
      'category': 'Non-Fiction',
      'availability': 'in_stock',
      'publishDate': '2018-10-16',
    },
    {
      'title': 'Dune',
      'author': 'Frank Herbert',
      'imageUrl': 'https://m.media-amazon.com/images/I/A1u+2fY5yTL._AC_UF1000,1000_QL80_.jpg',
      'price': 10.99,
      'rating': 4.7,
      'description': 'A science fiction novel set in a distant future amidst a feudal interstellar society.',
      'category': 'Science Fiction',
      'availability': 'in_stock',
      'publishDate': '1965-08-01',
    },
    {
      'title': 'The Alchemist',
      'author': 'Paulo Coelho',
      'imageUrl': 'https://m.media-amazon.com/images/I/51Z0nLAfLmL.jpg',
      'price': 9.99,
      'rating': 4.5,
      'description': 'A philosophical novel about a young Andalusian shepherd who dreams of finding treasure.',
      'category': 'Fiction',
      'availability': 'in_stock',
      'publishDate': '1988-01-01',
    },
    {
      'title': 'To Kill a Mockingbird',
      'author': 'Harper Lee',
      'imageUrl': 'https://m.media-amazon.com/images/I/71FxgtFKcQL._AC_UF1000,1000_QL80_.jpg',
      'price': 8.99,
      'rating': 4.8,
      'description': 'A novel about racial inequality and moral growth in the American South.',
      'category': 'Fiction',
      'availability': 'in_stock',
      'publishDate': '1960-07-11',
    },
    {
      'title': '1984',
      'author': 'George Orwell',
      'imageUrl': 'https://m.media-amazon.com/images/I/71kxa1-0mfL._AC_UF1000,1000_QL80_.jpg',
      'price': 7.99,
      'rating': 4.7,
      'description': 'A dystopian novel set in a totalitarian society.',
      'category': 'Fiction',
      'availability': 'in_stock',
      'publishDate': '1949-06-08',
    },
    {
      'title': 'The Great Gatsby',
      'author': 'F. Scott Fitzgerald',
      'imageUrl': 'https://m.media-amazon.com/images/I/71FTb9X6wsL._AC_UF1000,1000_QL80_.jpg',
      'price': 6.99,
      'rating': 4.5,
      'description': 'A novel about the American Dream and the Roaring Twenties.',
      'category': 'Fiction',
      'availability': 'in_stock',
      'publishDate': '1925-04-10',
    },
    {
      'title': 'Pride and Prejudice',
      'author': 'Jane Austen',
      'imageUrl': 'https://m.media-amazon.com/images/I/71Q1tPupKjL._AC_UF1000,1000_QL80_.jpg',
      'price': 5.99,
      'rating': 4.6,
      'description': 'A romantic novel about the Bennet family and Mr. Darcy.',
      'category': 'Romance',
      'availability': 'in_stock',
      'publishDate': '1813-01-28',
    },
    {
      'title': 'Sapiens: A Brief History of Humankind',
      'author': 'Yuval Noah Harari',
      'imageUrl': 'https://m.media-amazon.com/images/I/71N3-2sYDRL._AC_UF1000,1000_QL80_.jpg',
      'price': 15.99,
      'rating': 4.7,
      'description': 'A book that explores the history of the human species from the evolution of archaic human species in the Stone Age up to the twenty-first century.',
      'category': 'Non-Fiction',
      'availability': 'in_stock',
      'publishDate': '2011-01-01',
    },
    {
      'title': 'The Hobbit',
      'author': 'J.R.R. Tolkien',
      'imageUrl': 'https://m.media-amazon.com/images/I/710+HcoP38L._AC_UF1000,1000_QL80_.jpg',
      'price': 11.99,
      'rating': 4.8,
      'description': 'A fantasy novel about the adventures of hobbit Bilbo Baggins, who is hired by the wizard Gandalf as a burglar for a group of dwarves.',
      'category': 'Fantasy',
      'availability': 'in_stock',
      'publishDate': '1937-09-21',
    },
    {
      'title': 'The Da Vinci Code',
      'author': 'Dan Brown',
      'imageUrl': 'https://m.media-amazon.com/images/I/91Q5dCjc2KL._AC_UF1000,1000_QL80_.jpg',
      'price': 9.99,
      'rating': 4.2,
      'description': 'A mystery thriller novel that follows symbologist Robert Langdon as he investigates a murder in the Louvre Museum in Paris.',
      'category': 'Mystery',
      'availability': 'in_stock',
      'publishDate': '2003-03-18',
    },
    {
      'title': 'The Power of Now',
      'author': 'Eckhart Tolle',
      'imageUrl': 'https://m.media-amazon.com/images/I/714FbKtXS+L._AC_UF1000,1000_QL80_.jpg',
      'price': 13.99,
      'rating': 4.7,
      'description': 'A guide to spiritual enlightenment that emphasizes the importance of living in the present moment.',
      'category': 'Non-Fiction',
      'availability': 'in_stock',
      'publishDate': '1997-01-01',
    },
  ];

  List<Map<String, dynamic>> get _filteredBooks {
    List<Map<String, dynamic>> result = List.from(_allBooks);

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      result = result.where((book) {
        return book['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
               book['author'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply category filter
    if (_filters['categories'].isNotEmpty) {
      result = result.where((book) {
        return (_filters['categories'] as List).contains(book['category']);
      }).toList();
    }

    // Apply price filter
    if (_filters['priceMin'] != null) {
      result = result.where((book) => book['price'] >= _filters['priceMin']).toList();
    }
    if (_filters['priceMax'] != null) {
      result = result.where((book) => book['price'] <= _filters['priceMax']).toList();
    }

    // Apply rating filter
    if (_filters['rating'] > 0) {
      result = result.where((book) => book['rating'] >= _filters['rating']).toList();
    }

    // Apply availability filter
    if (_filters['availability'] != 'all') {
      result = result.where((book) => book['availability'] == _filters['availability']).toList();
    }

    // Apply sorting
    switch (_filters['sortBy']) {
      case 'price_asc':
        result.sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));
        break;
      case 'price_desc':
        result.sort((a, b) => (b['price'] as double).compareTo(a['price'] as double));
        break;
      case 'rating':
        result.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
        break;
      case 'newest':
        result.sort((a, b) => (b['publishDate'] as String).compareTo(a['publishDate'] as String));
        break;
      case 'popularity':
      default:
        // Assume popularity is already sorted in the original list
        break;
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();

    // Simulate loading delay
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
    setState(() {
      _filters['categories'] = [category['name']];
    });
  }

  void _handleBookTap(Map<String, dynamic> book, {String? heroTag}) {
    Navigator.push(
      context,
      AppPageTransition.fadeTransition(
        AnimatedBookDetailScreen(
          book: book,
          heroTag: heroTag,
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return FilterBottomSheet(
              currentFilters: _filters,
              onApplyFilters: (filters) {
                setState(() {
                  _filters = filters;
                });
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSearching
          ? AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search for books or authors',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                ),
              ],
            )
          : CustomAppBar(
              title: 'Buy Books',
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterBottomSheet,
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            // Active Filters
            if (_filters['categories'].isNotEmpty ||
                _filters['priceMin'] != null ||
                _filters['priceMax'] != null ||
                _filters['rating'] > 0 ||
                _filters['availability'] != 'all' ||
                _filters['sortBy'] != 'popularity')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Active Filters:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _buildActiveFiltersText(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filters = {
                            'categories': [],
                            'priceMin': null,
                            'priceMax': null,
                            'rating': 0.0,
                            'availability': 'all',
                            'sortBy': 'popularity',
                          };
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),

            // Categories (only show if not searching)
            if (_searchQuery.isEmpty && _filters['categories'].isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Categories'),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return CategoryCard(
                          name: category['name'],
                          icon: category['icon'],
                          color: category['color'],
                          onTap: () => _handleCategoryTap(index),
                        );
                      },
                    ),
                  ),
                ],
              ),

            // Books Grid
            Expanded(
              child: _filteredBooks.isEmpty
                  ? const Center(
                      child: Text(
                        'No books found matching your criteria',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : _isLoading
                      ? GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: 6,
                          itemBuilder: (context, index) {
                            return const BookCardShimmer();
                          },
                        )
                      : AnimationLimiter(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _filteredBooks.length,
                            itemBuilder: (context, index) {
                              final book = _filteredBooks[index];
                              final heroTag = 'book-${book['title']}-$index';
                              return AnimatedGridItem(
                                index: index,
                                columnCount: 2,
                                child: GestureDetector(
                                  onTap: () => _handleBookTap(book, heroTag: heroTag),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Book cover image
                                        Hero(
                                          tag: heroTag,
                                          child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    book['imageUrl'],
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 150,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.book,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                        ),
                                      ),
                                        // Book details
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                      Text(
                                        book['title'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        book['author'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '\$${book['price'].toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.star,
                                                size: 16,
                                                color: Colors.amber[700],
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                book['rating'].toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildActiveFiltersText() {
    List<String> filterTexts = [];

    if (_filters['categories'].isNotEmpty) {
      filterTexts.add('Categories: ${(_filters['categories'] as List).join(', ')}');
    }

    if (_filters['priceMin'] != null || _filters['priceMax'] != null) {
      String priceText = 'Price: ';
      if (_filters['priceMin'] != null) {
        priceText += '\$${_filters['priceMin']}';
      }
      priceText += ' - ';
      if (_filters['priceMax'] != null) {
        priceText += '\$${_filters['priceMax']}';
      }
      filterTexts.add(priceText);
    }

    if (_filters['rating'] > 0) {
      filterTexts.add('Rating: ${_filters['rating']}+');
    }

    if (_filters['availability'] != 'all') {
      String availabilityText = 'Availability: ';
      switch (_filters['availability']) {
        case 'in_stock':
          availabilityText += 'In Stock';
          break;
        case 'ebook':
          availabilityText += 'E-Book';
          break;
        case 'audiobook':
          availabilityText += 'Audiobook';
          break;
      }
      filterTexts.add(availabilityText);
    }

    if (_filters['sortBy'] != 'popularity') {
      String sortText = 'Sort: ';
      switch (_filters['sortBy']) {
        case 'price_asc':
          sortText += 'Price: Low to High';
          break;
        case 'price_desc':
          sortText += 'Price: High to Low';
          break;
        case 'rating':
          sortText += 'Rating';
          break;
        case 'newest':
          sortText += 'Newest';
          break;
      }
      filterTexts.add(sortText);
    }

    return filterTexts.join(' | ');
  }
}
