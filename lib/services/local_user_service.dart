import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class LocalUserService {
  static const String _userListKey = 'local_users';

  // Load all users from local storage
  Future<List<UserModel>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_userListKey) ?? [];

    return usersJson.map((userString) {
      final Map<String, dynamic> userMap = json.decode(userString);
      return UserModel.fromMap(userMap);
    }).toList();
  }

  // Save the list of users to local storage
  Future<void> _saveUsers(List<UserModel> users) async {
    final prefs = await SharedPreferences.getInstance();
    final userJsonList =
        users.map((user) => json.encode(user.toMap())).toList();
    await prefs.setStringList(_userListKey, userJsonList);
  }

  // Add a new user
  Future<UserModel> addUser(UserModel user) async {
    final users = await getUsers();

    // Check if user with the same email already exists
    if (users.any((existingUser) => existingUser.email == user.email)) {
      throw Exception('A user with this email already exists');
    }

    // Create a new user with a unique ID if one wasn't provided
    final newUser =
        user.id.isNotEmpty ? user : user.copyWith(id: const Uuid().v4());

    users.add(newUser);
    await _saveUsers(users);
    return newUser;
  }

  // Get a user by ID
  Future<UserModel?> getUserById(String id) async {
    final users = await getUsers();
    return users.firstWhere(
      (user) => user.id == id,
      orElse: () => throw Exception('User not found'),
    );
  }

  // Update a user
  Future<UserModel> updateUser(UserModel user) async {
    final users = await getUsers();
    final index = users.indexWhere(
      (existingUser) => existingUser.id == user.id,
    );

    if (index == -1) {
      throw Exception('User not found');
    }

    users[index] = user;
    await _saveUsers(users);
    return user;
  }

  // Delete a user
  Future<void> deleteUser(String id) async {
    final users = await getUsers();
    users.removeWhere((user) => user.id == id);
    await _saveUsers(users);
  }
}
