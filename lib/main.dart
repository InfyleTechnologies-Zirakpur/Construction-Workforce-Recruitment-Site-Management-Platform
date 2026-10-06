import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/bloc/worker_blocs.dart';
import 'features/repositories/worker_repository.dart';
import 'screens/auth/login_screen.dart';
import 'screens/company/company_home_screen.dart';
import 'screens/home/home_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

 
  await NotificationService.instance.initialize();

  runApp(
    const BuildHireApp(),
  );
} 

/// Root App
class BuildHireApp extends StatefulWidget {
  const BuildHireApp({super.key});

  @override
  State<BuildHireApp> createState() => _BuildHireAppState();
}

class _BuildHireAppState extends State<BuildHireApp> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isCompany = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    try {
      final token = await storage.read(key: 'accessToken');
      final role = await storage.read(key: 'role');
      if (mounted) {
        setState(() {
          _isLoggedIn = token != null && token.isNotEmpty;
          _isCompany = role == 'company';
          _isLoading = false;
        });
        if (_isLoggedIn) {
          NotificationService.instance.syncDeviceToken();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isCompany = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = WorkerRepository();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(repository)),
        BlocProvider(create: (_) => ProfileCubit(repository)),
        BlocProvider(create: (_) => JobsCubit(repository)),
        BlocProvider(create: (_) => FeedCubit()),
        BlocProvider(create: (_) => DashboardCubit(repository)),
        BlocProvider(create: (_) => MessagesCubit(repository)),
        BlocProvider(create: (_) => NotificationsCubit(repository)),

      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'BuildHire',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(context),
        home: _isLoading
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : _isLoggedIn
                ? (_isCompany ? const CompanyHomeScreen() : const HomePage())
                : const LoginScreen(),
      ),
    );
  }
}
