import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ortopedi_ai/theme/light_mode.dart';
import 'package:ortopedi_ai/theme/theme_provider.dart';
import 'package:ortopedi_ai/utils/api_client.dart';
import 'package:ortopedi_ai/views/DoctorViews/dfile_page.dart';
import 'package:ortopedi_ai/views/DoctorViews/dformpage.dart';
import 'package:ortopedi_ai/views/DoctorViews/dpatient_page.dart';
import 'package:ortopedi_ai/views/DoctorViews/dprofile_page.dart';
import 'package:ortopedi_ai/views/TenantViews/thomepage.dart';
import 'package:ortopedi_ai/views/TenantViews/tprofile_page.dart';
import 'package:ortopedi_ai/views/login_page.dart';
import 'package:ortopedi_ai/views/splash_screen.dart';
import 'package:provider/provider.dart';
import 'services/tenant_service.dart';
import 'theme/dark_mode.dart';
import 'views/DoctorViews/dhomepage.dart';
import 'views/promotion_page.dart';
import 'views/register_page.dart';
import 'views/DoctorViews/dteam_page.dart';

void main() {
  final storage = const FlutterSecureStorage();
  final dioClient = DioClient(storage: storage);
  final tenantService = TenantService(
    dioClient: dioClient,
    secureStorage: storage,
  );

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(),
      ),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => SplashScreen(),
          '/promotion': (context) => const PromotionPage(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/tenant/home': (context) => const THomePage(),
          '/doctor/home': (context) => const DHomePage(),
          '/tenant/profile': (context) => const TProfilePage(),
          '/doctor/forms': (context) => const DFormPage(formId: ''),
        },
        theme: lightMode,
        darkTheme: darkMode,
        themeMode: Provider.of<ThemeProvider>(context).isDarkMode
            ? ThemeMode.dark
            : ThemeMode.light);
  }
}
