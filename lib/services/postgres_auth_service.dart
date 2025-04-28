import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'firestore_service.dart';

class PostgresAuthService extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  String? _userId;
  String? _userEmail;
  String? _userName;
  String? _error;
  bool _isLoading = false;
  
  final FirestoreService _firestoreService = FirestoreService();
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get error => _error;
  bool get isLoading => _isLoading;
  
  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('userId');
      final storedUserEmail = prefs.getString('userEmail');
      final storedUserName = prefs.getString('userName');
      
      if (storedUserId != null && storedUserEmail != null) {
        _userId = storedUserId;
        _userEmail = storedUserEmail;
        _userName = storedUserName;
        _isAuthenticated = true;
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error = 'Error initializing auth service: $e';
      debugPrint(_error);
    }
  }
  
  // Register a new user
  Future<bool> register(String email, String password, String name) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Hash the password
      final passwordHash = _hashPassword(password);
      
      // Use Firebase Auth instead
      return await _registerWithFirebase(email, password, name);
    } catch (e) {
      _error = 'Error registering user: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Login a user
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Use Firebase Auth instead
      return await _loginWithFirebase(email, password);
    } catch (e) {
      _error = 'Error logging in: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!_isAuthenticated || _userId == null) {
      _error = 'User not authenticated';
      return null;
    }
    
    try {
      // Use Firebase Auth instead
      return _firestoreService.isUserLoggedIn ? {'id': _firestoreService.currentUserId, 'email': _userEmail, 'name': _userName} : null;
    } catch (e) {
      _error = 'Error getting user profile: $e';
      return null;
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Clear stored user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userId');
      await prefs.remove('userEmail');
      await prefs.remove('userName');
      
      // Reset state
      _userId = null;
      _userEmail = null;
      _userName = null;
      _isAuthenticated = false;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error logging out: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Hash password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Register with Firebase
  Future<bool> _registerWithFirebase(String email, String password, String name) async {
    try {
      // This is just a stub - we're actually using Firebase Auth directly
      // in the real implementation
      
      // Simulate success
      _userId = DateTime.now().millisecondsSinceEpoch.toString();
      _userEmail = email;
      _userName = name;
      _isAuthenticated = true;
      
      // Store user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', _userId!);
      await prefs.setString('userEmail', _userEmail!);
      await prefs.setString('userName', _userName!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error registering with Firebase: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Login with Firebase
  Future<bool> _loginWithFirebase(String email, String password) async {
    try {
      // This is just a stub - we're actually using Firebase Auth directly
      // in the real implementation
      
      // Simulate success
      _userId = DateTime.now().millisecondsSinceEpoch.toString();
      _userEmail = email;
      _userName = 'User';
      _isAuthenticated = true;
      
      // Store user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', _userId!);
      await prefs.setString('userEmail', _userEmail!);
      await prefs.setString('userName', _userName!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error logging in with Firebase: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
