import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/local_user_service.dart';

class UserProvider extends ChangeNotifier {
  final LocalUserService _userService = LocalUserService();
  List<UserModel> _users = [];
  UserModel? _currentUser;
  bool _isLoading = false;

  // Getters
  List<UserModel> get users => _users;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // Initialize the provider - load users from local storage
  Future<void> initialize() async {
    _setLoading(true);
    try {
      _users = await _userService.getUsers();
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing user provider: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Add a new user
  Future<void> addUser(UserModel user) async {
    _setLoading(true);
    try {
      final newUser = await _userService.addUser(user);
      _users.add(newUser);
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Get user by id
  Future<UserModel?> getUserById(String id) async {
    try {
      return await _userService.getUserById(id);
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }

  // Update a user
  Future<void> updateUser(UserModel user) async {
    _setLoading(true);
    try {
      final updatedUser = await _userService.updateUser(user);
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = updatedUser;
        // Update current user if it's the same user
        if (_currentUser != null && _currentUser!.id == user.id) {
          _currentUser = updatedUser;
        }
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a user
  Future<void> deleteUser(String id) async {
    _setLoading(true);
    try {
      await _userService.deleteUser(id);
      _users.removeWhere((user) => user.id == id);
      // Clear current user if it's the deleted user
      if (_currentUser != null && _currentUser!.id == id) {
        _currentUser = null;
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Set current user
  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }
}
