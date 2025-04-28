import 'package:flutter/material.dart';
import '../Widgets/book_card.dart';

class CategoryDetails extends StatefulWidget {
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;

  const CategoryDetails({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  });

  @override
  State<CategoryDetails> createState() => _CategoryDetailsState();
}

class _CategoryDetailsState extends State<CategoryDetails> {
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'Popularity';
  final List<String> _sortOptions = ['Popularity', 'Price: Low to High', 'Price: High to Low', 'Rating', 'Newest'];

  // Sample books data for each category
  late List<Map<String, dynamic>> _categoryBooks;

  @override
  void initState() {
    super.initState();
    // Initialize with sample books based on category
    _loadCategoryBooks();
  }

  void _loadCategoryBooks() {
    // This would typically come from a database or API
    // For now, we'll use sample data
    _categoryBooks = [
      {
        'title': 'The Great ${widget.categoryName} Book',
        'author': 'John Author',
        'imageUrl': 'https://m.media-amazon.com/images/I/71FTb9X6wsL._AC_UF1000,1000_QL80_.jpg',
        'price': 12.99,
        'rating': 4.5,
        'description': 'A fantastic book about ${widget.categoryName.toLowerCase()}.',
      },
      {
        'title': 'Advanced ${widget.categoryName}',
        'author': 'Jane Writer',
        'imageUrl': 'https://m.media-amazon.com/images/I/71kxa1-0mfL._AC_UF1000,1000_QL80_.jpg',
        'price': 15.99,
        'rating': 4.7,
        'description': 'An advanced guide to ${widget.categoryName.toLowerCase()} concepts and techniques.',
      },
      {
        'title': '${widget.categoryName} for Beginners',
        'author': 'Bob Teacher',
        'imageUrl': 'https://m.media-amazon.com/images/I/81wgcld4wxL._AC_UF1000,1000_QL80_.jpg',
        'price': 9.99,
        'rating': 4.3,
        'description': 'Start your journey into ${widget.categoryName.toLowerCase()} with this beginner-friendly guide.',
      },
      {
        'title': 'The Art of ${widget.categoryName}',
        'author': 'Sarah Expert',
        'imageUrl': 'https://m.media-amazon.com/images/I/91lslnZ-btL._AC_UF1000,1000_QL80_.jpg',
        'price': 14.50,
        'rating': 4.8,
        'description': 'Explore the artistic side of ${widget.categoryName.toLowerCase()} with this beautifully illustrated book.',
      },
      {
        'title': '${widget.categoryName} Masterclass',
        'author': 'Michael Pro',
        'imageUrl': 'https://m.media-amazon.com/images/I/71FxgtFKcQL._AC_UF1000,1000_QL80_.jpg',
        'price': 19.99,
        'rating': 4.9,
        'description': 'Take your ${widget.categoryName.toLowerCase()} skills to the next level with this comprehensive masterclass.',
      },
      {
        'title': 'Modern ${widget.categoryName}',
        'author': 'Lisa Contemporary',
        'imageUrl': 'https://m.media-amazon.com/images/I/A1u+2fY5yTL._AC_UF1000,1000_QL80_.jpg',
        'price': 13.75,
        'rating': 4.6,
        'description': 'A modern approach to ${widget.categoryName.toLowerCase()} for today\'s readers.',
      },
    ];

    // Add more specific books based on category
    if (widget.categoryName == 'Fiction') {
      _categoryBooks.addAll([
        {
          'title': 'The Silent Patient',
          'author': 'Alex Michaelides',
          'imageUrl': 'https://m.media-amazon.com/images/I/91lslnZ-btL._AC_UF1000,1000_QL80_.jpg',
          'price': 12.99,
          'rating': 4.6,
          'description': 'A psychological thriller about a woman who shoots her husband and then stops speaking.',
        },
        {
          'title': 'The Midnight Library',
          'author': 'Matt Haig',
          'imageUrl': 'https://m.media-amazon.com/images/I/81tCtHFtOgL._AC_UF1000,1000_QL80_.jpg',
          'price': 11.99,
          'rating': 4.5,
          'description': 'Between life and death there is a library, and within that library, the shelves go on forever.',
        },
      ]);
    } else if (widget.categoryName == 'Non-Fiction') {
      _categoryBooks.addAll([
        {
          'title': 'Atomic Habits',
          'author': 'James Clear',
          'imageUrl': 'https://m.media-amazon.com/images/I/81wgcld4wxL._AC_UF1000,1000_QL80_.jpg',
          'price': 14.99,
          'rating': 4.8,
          'description': 'A guide to building good habits and breaking bad ones.',
        },
        {
          'title': 'Sapiens',
          'author': 'Yuval Noah Harari',
          'imageUrl': 'https://m.media-amazon.com/images/I/71N3-2sYDRL._AC_UF1000,1000_QL80_.jpg',
          'price': 16.99,
          'rating': 4.7,
          'description': 'A brief history of humankind.',
        },
      ]);
    }
  }

  void _handleBookTap(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_categoryBooks[index]['title']} tapped')),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.categoryColor.withOpacity(0.8),
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterOptions(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search in ${widget.categoryName}',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (value) {
                // Implement search functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Searching for: $value in ${widget.categoryName}')),
                );
              },
            ),
          ),

          // Sort by dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Sort by: '),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: Container(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _sortBy = newValue;
                        // Implement sorting logic here
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sorting by: $newValue')),
                        );
                      });
                    }
                  },
                  items: _sortOptions.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Category header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  widget.categoryIcon,
                  color: widget.categoryColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'All ${widget.categoryName} Books',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Books grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _categoryBooks.length,
              itemBuilder: (context, index) {
                final book = _categoryBooks[index];
                return GestureDetector(
                  onTap: () => _handleBookTap(index),
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
                        ClipRRect(
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
                                      color: widget.categoryColor,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Books',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Price Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Min',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Max',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (int i = 1; i <= 5; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Row(
                          children: [
                            Text('$i'),
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                          ],
                        ),
                        selected: false,
                        onSelected: (bool selected) {
                          // Implement filter logic
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Apply filters
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filters applied')),
                      );
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
