import 'package:flutter/material.dart';
import '../Widgets/book_card.dart';
import '../Widgets/category_card.dart';
import '../Widgets/book_carousel.dart';
import '../Widgets/section_title.dart';
import '../Widgets/custom_app_bar.dart';
import 'category_details.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _searchController = TextEditingController();

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleCategoryTap(int index) {
    final category = _categories[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetails(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Bookey',
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: null, // We'll implement this later
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for books, authors, or ISBN',
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Searching for: $value')),
                  );
                },
              ),
            ),

            // Categories
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

            const SizedBox(height: 16),

            // Top Books Carousel
            BookCarousel(
              books: _topBooks,
              title: 'Top Books',
              onBookTap: (index) => _handleBookTap(index, 'Top Books'),
            ),

            const SizedBox(height: 24),

            // Books Near You
            SectionTitle(
              title: 'Books Near You',
              onSeeAllPressed: () => _handleBookTap(-1, 'See All Books Near You'),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _nearbyBooks.length,
              itemBuilder: (context, index) {
                final book = _nearbyBooks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: LargeBookCard(
                    title: book['title'],
                    author: book['author'],
                    imageUrl: book['imageUrl'],
                    price: book['price'],
                    rating: book['rating'],
                    description: book['description'],
                    onTap: () => _handleBookTap(index, 'Books Near You'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
