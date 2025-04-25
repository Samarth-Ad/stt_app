import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  // Check current connectivity status
  Future<bool> isConnected() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Stream to listen to connectivity changes
  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  // Show a snackbar when connectivity changes
  void showConnectivitySnackBar(BuildContext context, bool isConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isConnected
              ? 'Back online. You\'re now connected to the network.'
              : 'No internet connection. Working in offline mode.',
        ),
        backgroundColor: isConnected ? Colors.green : Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
