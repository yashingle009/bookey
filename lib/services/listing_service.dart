import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/book_listing.dart';

class ListingService {
  // This is a mock service for demonstration purposes
  // In a real app, this would interact with Firebase or another backend
  
  // Mock list of book listings
  final List<BookListing> _listings = [];
  
  // Get all listings
  List<BookListing> getAllListings() {
    return _listings;
  }
  
  // Get user listings
  List<BookListing> getUserListings(String userId) {
    return _listings.where((listing) => listing.sellerId == userId).toList();
  }
  
  // Create a new listing
  Future<BookListing> createListing({
    required String title,
    required String author,
    required String category,
    required String condition,
    required String description,
    required double price,
    required String location,
    required List<File> images,
    required String sellerId,
    required String sellerName,
  }) async {
    try {
      // In a real app, you would upload images to storage and get URLs
      // For now, we'll just use mock URLs
      List<String> imageUrls = [];
      for (var i = 0; i < images.length; i++) {
        imageUrls.add('https://example.com/image_$i.jpg');
      }
      
      final listing = BookListing(
        id: const Uuid().v4(),
        title: title,
        author: author,
        category: category,
        condition: condition,
        description: description,
        price: price,
        location: location,
        imageUrls: imageUrls,
        sellerId: sellerId,
        sellerName: sellerName,
        createdAt: DateTime.now(),
      );
      
      // In a real app, you would save this to Firestore
      _listings.add(listing);
      
      return listing;
    } catch (e) {
      debugPrint('Error creating listing: $e');
      rethrow;
    }
  }
  
  // Update a listing
  Future<void> updateListing(BookListing listing) async {
    try {
      final index = _listings.indexWhere((l) => l.id == listing.id);
      if (index != -1) {
        _listings[index] = listing;
      }
    } catch (e) {
      debugPrint('Error updating listing: $e');
      rethrow;
    }
  }
  
  // Delete a listing
  Future<void> deleteListing(String listingId) async {
    try {
      _listings.removeWhere((listing) => listing.id == listingId);
    } catch (e) {
      debugPrint('Error deleting listing: $e');
      rethrow;
    }
  }
  
  // Toggle listing active status
  Future<void> toggleListingStatus(String listingId) async {
    try {
      final index = _listings.indexWhere((l) => l.id == listingId);
      if (index != -1) {
        final listing = _listings[index];
        final updatedListing = BookListing(
          id: listing.id,
          title: listing.title,
          author: listing.author,
          category: listing.category,
          condition: listing.condition,
          description: listing.description,
          price: listing.price,
          location: listing.location,
          imageUrls: listing.imageUrls,
          sellerId: listing.sellerId,
          sellerName: listing.sellerName,
          createdAt: listing.createdAt,
          isActive: !listing.isActive,
        );
        _listings[index] = updatedListing;
      }
    } catch (e) {
      debugPrint('Error toggling listing status: $e');
      rethrow;
    }
  }
}
