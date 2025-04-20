import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:stt_app/firebase_options.dart';

class FirebaseUtils {
  // Initialize Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await _configureFirestore();
  }

  // Configure Firestore for better performance
  static Future<void> _configureFirestore() async {
    try {
      // Enable offline persistence
      await FirebaseFirestore.instance.enablePersistence(
        const PersistenceSettings(synchronizeTabs: true),
      );

      // Configure settings
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Log success
      if (kDebugMode) {
        print('Firestore persistence enabled successfully');
      }
    } catch (e) {
      // Log error
      if (kDebugMode) {
        print('Error configuring Firestore: $e');
      }
    }
  }

  // Clear Firestore cache (use cautiously)
  static Future<void> clearFirestoreCache() async {
    try {
      await FirebaseFirestore.instance.clearPersistence();
      if (kDebugMode) {
        print('Firestore cache cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing Firestore cache: $e');
      }
    }
  }

  // Helper to set default caching for collection queries
  static Query<Map<String, dynamic>> getCachedCollection(
    String collectionPath,
  ) {
    return FirebaseFirestore.instance
        .collection(collectionPath)
        .withConverter(
          fromFirestore: (snapshot, _) => snapshot.data() ?? {},
          toFirestore: (data, _) => data,
        );
  }

  // Helper to get document with server and cache
  static Future<DocumentSnapshot<Map<String, dynamic>>> getDocumentWithCache(
    String collectionPath,
    String documentId,
  ) async {
    return FirebaseFirestore.instance
        .collection(collectionPath)
        .doc(documentId)
        .get(const GetOptions(source: Source.serverAndCache));
  }
}
