import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_colors.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/bloc/worker_blocs.dart';
import 'features/repositories/worker_repository.dart';
import 'screens/splash/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.instance.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(
    const BuildHireApp(),
  );
}

/// Root App
class BuildHireApp extends StatelessWidget {
  const BuildHireApp({super.key});

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
        BlocProvider(create: (_) => DocumentsCubit(repository)),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'BuildHire',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(context),
        color: AppColors.primary,
        home: const SplashScreen(),
      ),
    );
  }
}
