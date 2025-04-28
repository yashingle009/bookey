import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;
  bool _isLoading = true;

  // Orders data
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _processingOrders = [];
  List<Map<String, dynamic>> _deliveredOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if orders collection is accessible
      final isAccessible = await _firestoreService.isOrdersCollectionAccessible();

      if (!isAccessible) {
        // If not accessible, show sample orders
        _showSampleOrders();
        return;
      }

      // Check if there are any orders
      final ordersSnapshot = await _firestoreService.getUserOrders().first;

      if (ordersSnapshot.docs.isEmpty) {
        try {
          // Create a sample order if no orders exist
          await _firestoreService.createSampleOrder();

          // Wait a moment and try to load orders again
          await Future.delayed(const Duration(milliseconds: 500));
          final newOrdersSnapshot = await _firestoreService.getUserOrders().first;

          if (newOrdersSnapshot.docs.isEmpty) {
            // Still no orders, show sample orders
            _showSampleOrders();
            return;
          }

          await _processOrdersSnapshot(newOrdersSnapshot);
        } catch (e) {
          debugPrint('Error creating sample order: $e');
          _showSampleOrders();
        }
      } else {
        await _processOrdersSnapshot(ordersSnapshot);
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');

      // Show sample orders instead
      _showSampleOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Using sample orders due to permission restrictions'),
            action: SnackBarAction(
              label: 'DISMISS',
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  void _showSampleOrders() {
    // Create sample orders for demonstration
    final sampleOrders = [
      {
        'orderId': 'ORD-12345',
        'status': 'Delivered',
        'total': 29.99,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
        'items': [
          {
            'title': 'The Alchemist',
            'author': 'Paulo Coelho',
            'price': 12.99,
            'quantity': 1,
            'imageUrl': 'https://m.media-amazon.com/images/I/51Z0nLAfLmL._SY445_SX342_.jpg',
          },
          {
            'title': 'Atomic Habits',
            'author': 'James Clear',
            'price': 16.99,
            'quantity': 1,
            'imageUrl': 'https://m.media-amazon.com/images/I/513Y5o-DYtL.jpg',
          },
        ],
      },
      {
        'orderId': 'ORD-12346',
        'status': 'Delivered',
        'total': 24.99,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
        'items': [
          {
            'title': 'Dune',
            'author': 'Frank Herbert',
            'price': 24.99,
            'quantity': 1,
            'imageUrl': 'https://m.media-amazon.com/images/I/A1u+2fY5yTL._AC_UF1000,1000_QL80_.jpg',
          },
        ],
      },
      {
        'orderId': 'ORD-12347',
        'status': 'Processing',
        'total': 19.99,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 12))),
        'items': [
          {
            'title': 'The Silent Patient',
            'author': 'Alex Michaelides',
            'price': 19.99,
            'quantity': 1,
            'imageUrl': 'https://m.media-amazon.com/images/I/91lslnZ-btL._AC_UF1000,1000_QL80_.jpg',
          },
        ],
      },
    ];

    final processingOrders = sampleOrders
        .where((order) => order['status'] == 'Processing')
        .toList();

    final deliveredOrders = sampleOrders
        .where((order) => order['status'] == 'Delivered')
        .toList();

    if (mounted) {
      setState(() {
        _orders = sampleOrders;
        _processingOrders = processingOrders;
        _deliveredOrders = deliveredOrders;
        _isLoading = false;
      });
    }
  }

  Future<void> _processOrdersSnapshot(QuerySnapshot snapshot) async {
    final List<Map<String, dynamic>> orders = [];
    final List<Map<String, dynamic>> processingOrders = [];
    final List<Map<String, dynamic>> deliveredOrders = [];

    for (final doc in snapshot.docs) {
      try {
        final orderId = doc.id;

        // Get order details including items
        try {
          final orderDetails = await _firestoreService.getOrderDetails(orderId);

          // Add order to appropriate list based on status
          final status = orderDetails['status'] as String? ?? 'Processing';

          if (status == 'Delivered') {
            deliveredOrders.add(orderDetails);
          } else {
            processingOrders.add(orderDetails);
          }

          orders.add(orderDetails);
        } catch (e) {
          debugPrint('Error getting order details: $e');
        }
      } catch (e) {
        debugPrint('Error processing order: $e');
      }
    }

    if (mounted) {
      setState(() {
        _orders = orders;
        _processingOrders = processingOrders;
        _deliveredOrders = deliveredOrders;
        _isLoading = false;
      });
    }
  }

  Future<void> _createSampleOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.createSampleOrder();
      await _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample order created')),
        );
      }
    } catch (e) {
      debugPrint('Error creating sample order: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating sample order: ${e.toString()}')),
        );

        setState(() {
          _isLoading = false;
        });
      }
    }
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
        title: const Text('My Orders'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Processing'),
            Tab(text: 'Delivered'),
          ],
        ),
        actions: [
          // Add a refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Orders',
            onPressed: _loadOrders,
          ),
          // Add a button to create a sample order
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Sample Order',
            onPressed: _createSampleOrder,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadOrders(),
              child: TabBarView(
                controller: _tabController,
                children: [
                  // All Orders
                  _buildOrdersList(_orders),

                  // Processing Orders
                  _buildOrdersList(_processingOrders),

                  // Delivered Orders
                  _buildOrdersList(_deliveredOrders),
                ],
              ),
            ),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No orders found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your orders will appear here',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final items = order['items'] as List<dynamic>;
    final orderId = order['orderId'] as String? ?? 'Unknown';
    final status = order['status'] as String? ?? 'Processing';
    final total = order['total'] is double
        ? order['total']
        : (order['total'] as num?)?.toDouble() ?? 0.0;

    // Get the timestamp and convert to DateTime
    final timestamp = order['createdAt'] as Timestamp?;
    final orderDate = timestamp?.toDate() ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'Delivered'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status == 'Delivered'
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Order date
            Text(
              'Ordered on ${dateFormat.format(orderDate)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Order items
            ...items.map((item) => _buildOrderItem(item as Map<String, dynamic>)).toList(),

            const Divider(height: 24),

            // Order total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Order actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // View order details
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Viewing details for order $orderId')),
                    );
                  },
                  child: const Text('View Details'),
                ),
                if (status != 'Delivered')
                  TextButton(
                    onPressed: () {
                      // Track order
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tracking order $orderId')),
                      );
                    },
                    child: const Text('Track Order'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final title = item['title'] as String? ?? 'Unknown Title';
    final author = item['author'] as String? ?? 'Unknown Author';
    final imageUrl = item['imageUrl'] as String? ?? '';
    final price = item['price'] is double
        ? item['price']
        : (item['price'] as num?)?.toDouble() ?? 0.0;
    final quantity = item['quantity'] is int
        ? item['quantity']
        : (item['quantity'] as num?)?.toInt() ?? 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book cover
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 60,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.book, color: Colors.grey),
                      );
                    },
                  )
                : Container(
                    width: 60,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.book, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 12),

          // Book details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  author,
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
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Qty: $quantity',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
