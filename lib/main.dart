import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'providers/pricing_provider.dart';
import 'services/customer_session.dart';
import 'services/location_controller.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fire-and-forget rather than awaited: both just restore a previously
  // saved value from SharedPreferences (a manually-picked city, a logged-in
  // customer) into a ChangeNotifier/ValueNotifier that the UI already
  // watches reactively, so screens pick the restored value up the moment
  // it lands. Blocking runApp() on this disk I/O instead just holds
  // Flutter's first frame back — and with it, Android's native splash
  // screen, which only dismisses once that first frame paints.
  unawaited(LocationController.instance.init());
  unawaited(CustomerSession.instance.initialize());
  runApp(const RentMitraApp());
}

class RentMitraApp extends StatelessWidget {
  const RentMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PricingProvider()..load()),
      ],
      child: MaterialApp.router(
        title: 'RentMitra',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.purple,
            primary: AppColors.purple,
            surface: AppColors.background,
          ),
          textTheme: GoogleFonts.interTextTheme(),
          fontFamily: GoogleFonts.inter().fontFamily,
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
