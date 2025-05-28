import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../models/notification_item.dart';
import '../../providers/cart_provider.dart';
import '../../services/cart_service.dart';
import '../../services/notification_service.dart';
import '../../services/firestore_service.dart';

class OrderScreen extends StatefulWidget {
  static const routeName = '/order';

  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cashOnDelivery;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cartService = Provider.of<CartService>(context, listen: false);
      final firestoreService = FirestoreService();
      final notificationService = NotificationService();
      
      // Create the order with payment method
      final orderId = await firestoreService.createOrderWithPaymentMethod(
        _addressController.text,
        _selectedPaymentMethod.toString().split('.').last,
      );

      if (orderId != null) {
        // Send notifications to book owners
        final cartItems = cartService.cartItems;
        for (final item in cartItems) {
          final bookId = item['bookId'] as String;
          final bookTitle = item['title'] as String;
          
          // Get book details to find the seller
          final bookDoc = await firestoreService.getBookById(bookId);
          if (bookDoc != null && bookDoc.exists) {
            final bookData = bookDoc.data() as Map<String, dynamic>;
            final sellerId = bookData['sellerId'] as String;
            final sellerName = bookData['sellerName'] as String;
            
            // Send notification to the seller
            await firestoreService.sendNotificationToUser(
              sellerId,
              'New Order Received',
              'Someone has ordered your book "$bookTitle". Order ID: $orderId',
              NotificationType.success,
            );
            
            // Add local notification for demo purposes
            notificationService.addNotification(
              'Order Placed Successfully',
              'Your order for "$bookTitle" has been placed. Order ID: $orderId',
              NotificationType.success,
            );
          }
        }

        // Navigate to order confirmation screen
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/order-confirmation',
            arguments: orderId,
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to place order. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final items = cartProvider.items.values.toList();
    final totalAmount = cartProvider.totalAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary
                  Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Order Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  // Navigate to book selection screen
                                  Navigator.of(context).pushNamed('/book-selection');
                                },
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Books'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...items.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          item.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.book),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text('${item.quantity} x \$${item.price.toStringAsFixed(2)}'),
                                        ],
                                      ),
                                    ),
                                    Text('\$${item.totalPrice.toStringAsFixed(2)}'),
                                  ],
                                ),
                              )),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Shipping Address
                  Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Shipping Address',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Full Address',
                                border: OutlineInputBorder(),
                                hintText: 'Enter your full shipping address',
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your shipping address';
                                }
                                if (value.length < 10) {
                                  return 'Please enter a complete address';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Payment Method
                  Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Method',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Credit Card
                          RadioListTile<PaymentMethod>(
                            title: const Row(
                              children: [
                                Icon(Icons.credit_card),
                                SizedBox(width: 8),
                                Text('Credit Card'),
                              ],
                            ),
                            value: PaymentMethod.creditCard,
                            groupValue: _selectedPaymentMethod,
                            onChanged: (PaymentMethod? value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          ),
                          
                          // Debit Card
                          RadioListTile<PaymentMethod>(
                            title: const Row(
                              children: [
                                Icon(Icons.credit_card),
                                SizedBox(width: 8),
                                Text('Debit Card'),
                              ],
                            ),
                            value: PaymentMethod.debitCard,
                            groupValue: _selectedPaymentMethod,
                            onChanged: (PaymentMethod? value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          ),
                          
                          // PayPal
                          RadioListTile<PaymentMethod>(
                            title: const Row(
                              children: [
                                Icon(Icons.account_balance_wallet),
                                SizedBox(width: 8),
                                Text('PayPal'),
                              ],
                            ),
                            value: PaymentMethod.paypal,
                            groupValue: _selectedPaymentMethod,
                            onChanged: (PaymentMethod? value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          ),
                          
                          // Cash on Delivery
                          RadioListTile<PaymentMethod>(
                            title: const Row(
                              children: [
                                Icon(Icons.money),
                                SizedBox(width: 8),
                                Text('Cash on Delivery'),
                              ],
                            ),
                            value: PaymentMethod.cashOnDelivery,
                            groupValue: _selectedPaymentMethod,
                            onChanged: (PaymentMethod? value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          ),
                          
                          // Bank Transfer
                          RadioListTile<PaymentMethod>(
                            title: const Row(
                              children: [
                                Icon(Icons.account_balance),
                                SizedBox(width: 8),
                                Text('Bank Transfer'),
                              ],
                            ),
                            value: PaymentMethod.bankTransfer,
                            groupValue: _selectedPaymentMethod,
                            onChanged: (PaymentMethod? value) {
                              setState(() {
                                _selectedPaymentMethod = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Place Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'PLACE ORDER',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}