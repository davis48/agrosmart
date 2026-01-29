import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Will be available after build
import 'package:go_router/go_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/onboarding_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/otp_page.dart';
import 'features/auth/presentation/pages/role_selection_page.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/buyer_dashboard/presentation/pages/buyer_dashboard_page.dart';
import 'features/parcelles/presentation/pages/parcelles_page.dart';
import 'features/capteurs/presentation/pages/capteurs_page.dart';
import 'package:agriculture/features/diagnostic/presentation/pages/diagnostic_page.dart';
import 'package:agriculture/features/marketplace/presentation/pages/marketplace_page.dart';
import 'features/marketplace/presentation/pages/add_product_page.dart';
import 'features/formations/presentation/pages/formations_page.dart';
import 'features/messages/presentation/pages/messages_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/profile/presentation/pages/edit_profile_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/analytics/presentation/pages/analytics_page.dart';
import 'features/notifications/presentation/pages/notifications_page.dart';
import 'features/recommandations/presentation/pages/recommandations_page.dart';
import 'features/orders/presentation/pages/orders_page.dart';
import 'features/diagnostic/presentation/pages/diagnostic_history_page.dart';
import 'features/diagnostic/presentation/pages/diagnostic_detail_page.dart';
import 'features/diagnostic/presentation/pages/pest_map_page.dart';
import 'features/support/presentation/pages/support_page.dart';
import 'features/about/presentation/pages/about_page.dart';
import 'features/orders/presentation/pages/order_detail_page.dart';
import 'features/orders/domain/entities/order.dart';
import 'features/parcelles/presentation/pages/parcelle_detail_page.dart';
import 'features/capteurs/presentation/pages/capteur_detail_page.dart';
import 'features/parcelles/domain/entities/parcelle.dart';
import 'features/capteurs/domain/entities/sensor.dart';
import 'features/parcelles/presentation/bloc/parcelle_bloc.dart';
import 'features/capteurs/presentation/bloc/sensor_bloc.dart';
import 'features/notifications/presentation/bloc/alert_bloc.dart';
import 'features/weather/presentation/bloc/weather_bloc.dart';
import 'features/weather/presentation/pages/weather_page.dart';
import 'features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'features/analytics/presentation/bloc/analytics_bloc.dart';
import 'features/recommandations/presentation/bloc/recommandation_bloc.dart';
import 'features/irrigation/presentation/pages/irrigation_page.dart';
import 'features/marketplace/presentation/bloc/equipment_bloc.dart';
import 'features/community/presentation/bloc/chat_bloc.dart';
import 'features/community/presentation/bloc/community_listing_bloc.dart';
import 'features/community/presentation/pages/community_marketplace_page.dart';
import 'features/community/presentation/pages/create_listing_page.dart';
import 'features/forum/presentation/pages/community_page.dart';
import 'features/assistant/presentation/bloc/chatbot_bloc.dart';
import 'features/assistant/presentation/pages/agri_chatbot_page.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/cart/presentation/pages/cart_page.dart';
import 'features/favorites/presentation/pages/favorites_page.dart';
import 'features/favorites/presentation/bloc/favorites_bloc.dart';
import 'features/checkout/presentation/pages/checkout_page.dart';
import 'shared/pages/main_shell_page.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'injection_container.dart' as di;
import 'core/theme/theme_cubit.dart';
import 'features/settings/presentation/bloc/settings_cubit.dart';
import 'core/utils/app_bloc_observer.dart';
import 'core/config/environment_config.dart';
import 'core/utils/error_handler.dart';

void main() async {
  // Capturer les erreurs Flutter synchrones
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log l'erreur de manière sécurisée
    ErrorHandler.logError(
      details.exception,
      stackTrace: details.stack,
      context: 'Flutter Framework Error',
    );
  };

  // Capturer les erreurs asynchrones non gérées
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Configurer le BlocObserver pour le debugging
      Bloc.observer = AppBlocObserver();

      await initializeDateFormatting('fr', null);
      await di.init();

      runApp(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => di.sl<AuthBloc>()),
            BlocProvider(create: (_) => ThemeCubit(storage: di.sl())),
            BlocProvider(create: (_) => SettingsCubit(di.sl())),
            BlocProvider(
              create: (_) => di.sl<ParcelleBloc>()..add(LoadParcelles()),
            ),
            BlocProvider(
              create: (_) => di.sl<SensorBloc>()..add(LoadSensors()),
            ),
            BlocProvider(create: (_) => di.sl<AlertBloc>()..add(LoadAlerts())),
            BlocProvider(
              create: (_) =>
                  di.sl<MarketplaceBloc>()..add(LoadMarketplaceProducts()),
            ),
            BlocProvider(
              create: (_) => di.sl<WeatherBloc>()
                ..add(
                  LoadWeatherForecast(latitude: 5.3600, longitude: -4.0083),
                ),
            ),
            BlocProvider(
              create: (_) => di.sl<AnalyticsBloc>()..add(LoadAnalytics()),
            ),
            BlocProvider(
              create: (_) =>
                  di.sl<RecommandationBloc>()..add(LoadRecommandations()),
            ),
            BlocProvider(
              create: (_) => di.sl<EquipmentBloc>()..add(LoadEquipments()),
            ),
            BlocProvider(
              create: (_) => di.sl<ChatBloc>()..add(LoadConversations()),
            ),
            BlocProvider(
              create: (_) => di.sl<CommunityListingBloc>()..add(LoadListings()),
            ),
            BlocProvider(create: (_) => di.sl<ChatbotBloc>()),
            BlocProvider(create: (_) => di.sl<CartBloc>()..add(LoadCart())),
            BlocProvider(
              create: (_) => di.sl<FavoritesBloc>()..add(LoadFavorites()),
            ),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stackTrace) {
      // Gestion globale des erreurs asynchrones
      ErrorHandler.logError(
        error,
        stackTrace: stackTrace,
        context: 'Global Async Error',
      );

      // En production, afficher un message générique plutôt que crasher
      if (EnvironmentConfig.isProduction) {
        debugPrint('[ERROR] Une erreur inattendue s\'est produite');
      } else {
        debugPrint('[ERROR] Uncaught async error: $error');
        debugPrint('[ERROR] Stack trace: $stackTrace');
      }
    },
  );
}

final _authKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  navigatorKey: _authKey,
  initialLocation: '/', // Marketplace-first: on démarre sur le shell principal
  routes: [
    // Main Shell (Bottom Navigation avec Marketplace, Dashboard, Panier, Profil)
    GoRoute(path: '/', builder: (context, state) => const MainShellPage()),

    // Auth routes
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        // Récupérer le rôle passé en extra depuis la page de sélection
        String role = 'ACHETEUR';
        if (state.extra is Map<String, dynamic>) {
          role = (state.extra as Map<String, dynamic>)['role'] ?? 'ACHETEUR';
        } else if (state.extra is String) {
          role = state.extra as String;
        }
        return RegisterPage(role: role);
      },
    ),
    GoRoute(
      path: '/role-selection',
      name: 'role-selection',
      builder: (context, state) => const RoleSelectionPage(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final telephone = state.extra as String;
        return OtpPage(telephone: telephone);
      },
    ),

    // Cart & Checkout routes
    GoRoute(
      path: '/cart',
      name: 'cart',
      builder: (context, state) => const CartPage(),
    ),
    GoRoute(
      path: '/checkout',
      name: 'checkout',
      builder: (context, state) => const CheckoutPage(),
    ),
    GoRoute(
      path: '/favorites',
      name: 'favorites',
      builder: (context, state) => const FavoritesPage(),
    ),

    // Dashboard routes
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/buyer-dashboard',
      name: 'buyer-dashboard',
      builder: (context, state) => const BuyerDashboardPage(),
    ),
    GoRoute(
      path: '/parcelles',
      builder: (context, state) => const ParcellesPage(),
    ),
    GoRoute(
      path: '/capteurs',
      builder: (context, state) => const CapteursPage(),
    ),
    GoRoute(
      path: '/diagnostic',
      builder: (context, state) => const DiagnosticPage(),
    ),
    GoRoute(
      path: '/marketplace',
      builder: (context, state) => const MarketplacePage(),
    ),
    GoRoute(
      path: '/add-product',
      builder: (context, state) => const AddProductPage(),
    ),
    GoRoute(
      path: '/formations',
      builder: (context, state) => const FormationsPage(),
    ),
    GoRoute(
      path: '/messages',
      builder: (context, state) => const MessagesPage(),
    ),

    // Profile & Settings
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),

    // Analytics & Notifications
    GoRoute(
      path: '/analytics',
      name: 'analytics',
      builder: (context, state) => const AnalyticsPage(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/recommandations',
      builder: (context, state) => const RecommandationsPage(),
    ),
    GoRoute(path: '/weather', builder: (context, state) => const WeatherPage()),

    // Additional pages
    GoRoute(
      path: '/orders',
      name: 'orders',
      builder: (context, state) => const OrdersPage(),
    ),
    GoRoute(
      path: '/diagnostic-history',
      name: 'diagnostic-history',
      builder: (context, state) => const DiagnosticHistoryPage(),
    ),
    GoRoute(
      path: '/community',
      builder: (context, state) => const CommunityPage(),
    ),
    GoRoute(
      path: '/irrigation',
      name: 'irrigation',
      builder: (context, state) => const IrrigationPage(),
    ),
    GoRoute(
      path: '/support',
      name: 'support',
      builder: (context, state) => const SupportPage(),
    ),
    GoRoute(
      path: '/about',
      name: 'about',
      builder: (context, state) => const AboutPage(),
    ),
    GoRoute(
      path: '/diagnostic-detail',
      name: 'diagnostic-detail',
      builder: (context, state) {
        final diagnostic = state.extra as Map<String, dynamic>;
        return DiagnosticDetailPage(diagnostic: diagnostic);
      },
    ),
    GoRoute(
      path: '/pest-map',
      name: 'pest-map',
      builder: (context, state) => const PestMapPage(),
    ),
    GoRoute(
      path: '/order-detail',
      name: 'order-detail',
      builder: (context, state) {
        final order = state.extra as Order;
        return OrderDetailPage(order: order);
      },
    ),
    GoRoute(
      path: '/parcelle-detail',
      name: 'parcelle-detail',
      builder: (context, state) {
        final parcelle = state.extra as Parcelle;
        return ParcelleDetailPage(parcelle: parcelle);
      },
    ),
    GoRoute(
      path: '/capteur-detail',
      name: 'capteur-detail',
      builder: (context, state) {
        final capteur = state.extra as Sensor;
        return CapteurDetailPage(capteur: capteur);
      },
    ),
    GoRoute(
      path: '/community-marketplace',
      name: 'community-marketplace',
      builder: (context, state) => const CommunityMarketplacePage(),
    ),
    GoRoute(
      path: '/community-marketplace/create',
      name: 'create-listing',
      builder: (context, state) => const CreateListingPage(),
    ),
    GoRoute(
      path: '/chatbot',
      name: 'chatbot',
      builder: (context, state) => const AgriChatbotPage(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp.router(
          title: 'Agrosmart CI',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E1E1E),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              labelStyle: const TextStyle(color: Colors.grey),
              hintStyle: const TextStyle(color: Colors.grey),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
              titleLarge: TextStyle(color: Colors.white),
              titleMedium: TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white70),
            listTileTheme: const ListTileThemeData(
              iconColor: Colors.white70,
              textColor: Colors.white,
            ),
          ),
          themeMode: themeMode,
          routerConfig: _router,
        );
      },
    );
  }
}
