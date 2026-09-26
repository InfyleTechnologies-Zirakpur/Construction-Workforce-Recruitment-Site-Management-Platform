import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/bloc/worker_blocs.dart';
import 'features/repositories/worker_repository.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(
    // DevicePreview(enabled: false, builder: (context) => const BuildHireApp()),
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
        BlocProvider(create: (_) => MessagesCubit(repository)),
        BlocProvider(create: (_) => NotificationsCubit(repository)),
      ],
      child: MaterialApp(
      title: 'BuildHire',
      debugShowCheckedModeBanner: false,

      // Required for device_preview to work correctly
      // useInheritedMediaQuery: true,
      // locale: DevicePreview.locale(context),
      // builder: DevicePreview.appBuilder,

      theme: AppTheme.build(context),
      home: const LoginScreen(),
      ),
    );
  }
}
