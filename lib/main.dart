import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/providers.dart';
import 'data/firestore_repository.dart';
import 'data/repository.dart';

/// Build flags:
///   --dart-define=BACKEND=firebase plus FIREBASE_API_KEY / FIREBASE_APP_ID /
///   FIREBASE_PROJECT_ID / FIREBASE_SENDER_ID to use Cloud Firestore.
///   --dart-define=STRIPE_PAYMENT_LINK=https://buy.stripe.com/test_... for Stripe Checkout.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MarketRepository repo = InMemoryRepository();
  if (const String.fromEnvironment('BACKEND') == 'firebase') {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
          appId: String.fromEnvironment('FIREBASE_APP_ID'),
          messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
          projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
        ),
      );
      repo = FirestoreRepository(FirebaseFirestore.instance);
    } catch (e) {
      debugPrint('Firebase unavailable, using demo mode: $e');
    }
  }
  runApp(ProviderScope(overrides: [repositoryProvider.overrideWithValue(repo)], child: const SlotwiseApp()));
}
