import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled
}

enum PaymentMethod {
  creditCard,
  debitCard,
  paypal,
  cashOnDelivery,
  bankTransfer
}

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalAmount;
  final String shippingAddress;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  
  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.shippingAddress,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
  });
  
  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalAmount': totalAmount,
      'shippingAddress': shippingAddress,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
  
  // Create from Map (from Firestore)
  factory Order.fromMap(Map<String, dynamic> map, String docId, List<CartItem> orderItems) {
    return Order(
      id: docId,
      userId: map['userId'],
      items: orderItems,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      shippingAddress: map['shippingAddress'],
      status: _parseOrderStatus(map['status']),
      paymentMethod: _parsePaymentMethod(map['paymentMethod']),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
  
  static OrderStatus _parseOrderStatus(String status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
  
  static PaymentMethod _parsePaymentMethod(String method) {
    switch (method) {
      case 'creditCard':
        return PaymentMethod.creditCard;
      case 'debitCard':
        return PaymentMethod.debitCard;
      case 'paypal':
        return PaymentMethod.paypal;
      case 'cashOnDelivery':
        return PaymentMethod.cashOnDelivery;
      case 'bankTransfer':
        return PaymentMethod.bankTransfer;
      default:
        return PaymentMethod.cashOnDelivery;
    }
  }
}