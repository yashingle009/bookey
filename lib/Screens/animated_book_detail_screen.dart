import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/cart_provider.dart';
import '../utils/animations.dart';
import 'cart_screen.dart';

class AnimatedBookDetailScreen extends StatefulWidget {
  final Map<String, dynamic> book;
  final String? heroTag;

  const AnimatedBookDetailScreen({
    Key? key,
    required this.book,
    this.heroTag,
  }) : super(key: key);

  @override
  State<AnimatedBookDetailScreen> createState() => _AnimatedBookDetailScreenState();
}

class _AnimatedBookDetailScreenState extends State<AnimatedBookDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  double _imageHeight = 300;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scrollController = ScrollController()
      ..addListener(() {
        // Calculate image height based on scroll position
        final scrollOffset = _scrollController.offset;
        final newHeight = 300 - scrollOffset;
        final newOpacity = 1.0 - (scrollOffset / 200);

        setState(() {
          _imageHeight = newHeight > 100 ? newHeight : 100;
          _opacity = newOpacity > 0 ? (newOpacity < 1.0 ? newOpacity : 1.0) : 0;
        });
      });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image with parallax effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _imageHeight,
            child: Opacity(
              opacity: _opacity,
              child: widget.heroTag != null
                  ? Hero(
                      tag: widget.heroTag!,
                      child: _buildCoverImage(),
                    )
                  : _buildCoverImage(),
            ),
          ),

          // Main content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to favorites')),
                      );
                    },
                  ).animate().fadeIn(delay: 300.ms),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share functionality coming soon')),
                      );
                    },
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),

              // Book Details
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Author
                        Text(
                          widget.book['title'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 8),

                        Text(
                          'by ${widget.book['author']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 16),

                        // Rating and Price
                        Row(
                          children: [
                            // Rating
                            _buildRatingIndicator(widget.book['rating']),
                            const SizedBox(width: 16),

                            // Price
                            Text(
                              '\$${widget.book['price'].toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Buy Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              final cartProvider = Provider.of<CartProvider>(context, listen: false);
                              cartProvider.addItem(
                                bookId: widget.book['title'],
                                title: widget.book['title'],
                                author: widget.book['author'],
                                imageUrl: widget.book['imageUrl'],
                                price: widget.book['price'],
                              );

                              // Show animated snackbar
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 12),
                                      const Text('Added to cart'),
                                    ],
                                  ),
                                  action: SnackBarAction(
                                    label: 'VIEW CART',
                                    onPressed: () {
                                      Navigator.of(context).pushNamed(CartScreen.routeName);
                                    },
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Add to Cart',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

                        const SizedBox(height: 24),

                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(delay: 600.ms),

                        const SizedBox(height: 8),

                        Text(
                          widget.book['description'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ).animate().fadeIn(delay: 700.ms),

                        const SizedBox(height: 24),

                        // Book Details
                        const Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(delay: 800.ms),

                        const SizedBox(height: 8),

                        _buildDetailRow('Publisher', 'Penguin Random House')
                            .animate().fadeIn(delay: 850.ms),
                        _buildDetailRow('Language', 'English')
                            .animate().fadeIn(delay: 900.ms),
                        _buildDetailRow('Paperback', '320 pages')
                            .animate().fadeIn(delay: 950.ms),
                        _buildDetailRow('ISBN', '978-3-16-148410-0')
                            .animate().fadeIn(delay: 1000.ms),
                        _buildDetailRow('Publication Date', 'January 1, 2023')
                            .animate().fadeIn(delay: 1050.ms),

                        const SizedBox(height: 24),

                        // Similar Books
                        const Text(
                          'You May Also Like',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(delay: 1100.ms),

                        const SizedBox(height: 16),

                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 4,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            'https://picsum.photos/200/300?random=$index',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Similar Book',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: (1200 + (index * 100)).ms).slideX(begin: 0.2, end: 0);
                            },
                          ),
                        ),

                        const SizedBox(height: 80), // Bottom padding for floating button
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final cartProvider = Provider.of<CartProvider>(context, listen: false);
          cartProvider.addItem(
            bookId: widget.book['title'],
            title: widget.book['title'],
            author: widget.book['author'],
            imageUrl: widget.book['imageUrl'],
            price: widget.book['price'],
          );
          Navigator.of(context).pushNamed(CartScreen.routeName);
        },
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Buy Now'),
      ).animate().fadeIn(delay: 1000.ms).slideY(begin: 1, end: 0),
    );
  }

  Widget _buildCoverImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Book cover image
        Image.network(
          widget.book['imageUrl'],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(
                Icons.book,
                size: 100,
                color: Colors.grey,
              ),
            );
          },
        ),
        // Gradient overlay for better text visibility
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
              stops: const [0.7, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingIndicator(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          ...List.generate(5, (index) {
            return Icon(
              index < rating.floor() ? Icons.star : Icons.star_border,
              color: Colors.amber[700],
              size: 18,
            ).animate(delay: (300 + (index * 100)).ms).fadeIn().scale();
          }),
          const SizedBox(width: 4),
          Text(
            rating.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amber[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
