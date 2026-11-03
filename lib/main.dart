import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'router.dart';
import 'services/auth_service.dart';
import 'services/recipe_repository.dart';
import 'state/recipe_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RecipeBoxApp());
}

class RecipeBoxApp extends StatefulWidget {
  const RecipeBoxApp({super.key});

  @override
  State<RecipeBoxApp> createState() => _RecipeBoxAppState();
}

class _RecipeBoxAppState extends State<RecipeBoxApp> {
  late final AuthService _auth = AuthService(FirebaseAuth.instance);
  late final RecipeStore _recipes =
      RecipeStore(_auth, RecipeRepository(FirebaseFirestore.instance));
  late final GoRouter _router = createRouter(_auth);

  @override
  void dispose() {
    _router.dispose();
    _recipes.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _recipes),
      ],
      child: MaterialApp.router(
        title: 'RecipeBox',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
