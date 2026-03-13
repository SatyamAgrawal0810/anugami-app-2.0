// lib/main.dart
import 'package:anu_app/providers/review_provider.dart';
import 'package:anu_app/providers/wishlist_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:anu_app/api/services/notification_service.dart';
import 'package:anu_app/handlers/notification_handler.dart';
import 'package:anu_app/config/environment.dart';
import 'package:anu_app/core/error_handler.dart';

import 'presentation/splash_screen.dart';
import 'providers/optimized_product_provider.dart';
import 'providers/cart_provider.dart';
import 'api/services/auth_service.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/category_provider.dart';
import 'providers/user_provider.dart';
import 'providers/address_provider.dart';
import 'firebase_options.dart';

// ✅ Top-level background handler — ONLY registered here, NOT in NotificationService
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  developer.log('📩 BG Notification: ${message.notification?.title}',
      name: 'FCM-BG');
  developer.log('📦 BG Data: ${message.data}', name: 'FCM-BG');
}

// ✅ Send FCM token to backend — called after login & on token refresh
Future<void> _sendFcmTokenToBackend(String fcmToken) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');
    if (authToken == null || authToken.isEmpty) {
      developer.log('FCM: User not logged in — skipping backend update',
          name: 'FCM');
      return;
    }
    final response = await http.post(
      Uri.parse('https://anugami.com/api/v1/customers/fcm-token/update/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $authToken',
      },
      body: jsonEncode({'fcm_token': fcmToken}),
    );
    developer.log('✅ FCM token sent to backend: ${response.statusCode}',
        name: 'FCM');
  } catch (e) {
    developer.log('❌ FCM token backend update failed: $e', name: 'FCM');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  EnvironmentConfig.printConfig();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    ErrorHandler.logError(
      'Flutter Error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // ✅ STEP 1: Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    developer.log('✅ Firebase initialized', name: 'FCM');
  } catch (e, stackTrace) {
    ErrorHandler.logError('Failed to initialize Firebase',
        error: e, stackTrace: stackTrace);
  }

  // ✅ STEP 2: Register background handler BEFORE anything else
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ STEP 3: Request permission + fetch FCM token
  try {
    final messaging = FirebaseMessaging.instance;

    // Request permission (Android 13+ and iOS require this)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    developer.log(
      '🔔 Notification permission: ${settings.authorizationStatus}',
      name: 'FCM',
    );

    // ✅ Force fetch token — this is what was missing
    final fcmToken = await messaging.getToken();
    developer.log('🔥🔥🔥 FCM TOKEN: $fcmToken', name: 'FCM');

    if (fcmToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', fcmToken);
      developer.log('✅ FCM token saved to prefs', name: 'FCM');
      // Try sending to backend (will skip if not logged in yet)
      await _sendFcmTokenToBackend(fcmToken);
    } else {
      developer.log(
          '❌ FCM token is NULL — check Google Play Services & notification permission',
          name: 'FCM');
    }

    // ✅ Keep token fresh when it refreshes
    messaging.onTokenRefresh.listen((newToken) async {
      developer.log('🔄 FCM token refreshed: $newToken', name: 'FCM');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', newToken);
      await _sendFcmTokenToBackend(newToken);
    });
  } catch (e) {
    developer.log('❌ FCM setup error: $e', name: 'FCM');
    ErrorHandler.logError('FCM token setup failed', error: e);
  }

  // ✅ STEP 4: Initialize local notification service (no duplicate permission/background handler inside)
  final notificationService = NotificationService();
  try {
    await notificationService.initialize();
    developer.log('✅ NotificationService initialized', name: 'FCM');
  } catch (e, stackTrace) {
    ErrorHandler.logError('Failed to initialize NotificationService',
        error: e, stackTrace: stackTrace);
  }

  // ✅ STEP 5: Wire notification tap handler
  final notificationHandler = NotificationHandler();
  notificationService.onNotificationTapped = (data) {
    notificationHandler.handleNotificationTap(data);
  };

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0f2027),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

// ─────────────────────────────────────────────────────────────────────────────

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final UserProvider _userProvider = UserProvider();
  final AuthService _authService = AuthService();

  bool _initialized = false;
  bool _showSplash = true;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
    _setupForegroundNotificationHandler();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ Foreground: app open hone pe local notification show karo
  void _setupForegroundNotificationHandler() {
    // App foreground mein hai — local notification show karo
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log(
        '📲 Foreground notification: ${message.notification?.title}',
        name: 'FCM-FG',
      );
      if (message.notification != null) {
        NotificationService().showLocalNotification(
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
          payload: jsonEncode(message.data),
        );
      }
    });

    // App background mein thi — user ne notification tap kiya
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('📲 Notification opened from background',
          name: 'FCM-BG-TAP');
      if (message.data.isNotEmpty) {
        NotificationHandler().handleNotificationTap(message.data);
      }
    });

    // App band thi — notification tap karke kholi
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null && message.data.isNotEmpty) {
        developer.log('📲 App opened from terminated via notification',
            name: 'FCM-TERM');
        Future.delayed(const Duration(seconds: 2), () {
          NotificationHandler().handleNotificationTap(message.data);
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      ErrorHandler.logInfo('App resumed');
    }
  }

  Future<void> _initializeApp() async {
    try {
      await _userProvider.initialize();
      await _attemptAutoLogin();
      await Future.delayed(const Duration(milliseconds: 3000));
    } catch (e, stackTrace) {
      ErrorHandler.logError('App initialization failed',
          error: e, stackTrace: stackTrace);
      setState(() {
        _initializationError = 'Failed to initialize app. Please restart.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _initialized = true;
          _showSplash = false;
        });
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        );
      }
    }
  }

  Future<void> _attemptAutoLogin() async {
    try {
      final bool isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        developer.log('✅ User already logged in', name: 'Auth');
        // ✅ Also send FCM token now that we know user is logged in
        final prefs = await SharedPreferences.getInstance();
        final fcmToken = prefs.getString('fcm_token');
        if (fcmToken != null) {
          await _sendFcmTokenToBackend(fcmToken);
        }
        return;
      }

      final userData = await _authService.getUserData();
      final savedPassword = await _authService.getSavedPassword();

      if (userData != null &&
          userData['email'] != null &&
          userData['email'].isNotEmpty &&
          savedPassword != null &&
          savedPassword.isNotEmpty) {
        final result =
            await _authService.login(userData['email'], savedPassword);
        if (result['success']) {
          _userProvider.processLoginData(result['data']);
          developer.log('✅ Auto-login successful', name: 'Auth');
        }
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('Auto-login failed',
          error: e, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializationError != null) {
      return MaterialApp(
        title: EnvironmentConfig.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner:
            EnvironmentConfig.getFeatureFlag('showDebugBanner'),
        home: _ErrorScreen(message: _initializationError!),
      );
    }

    if (_showSplash || !_initialized) {
      return MaterialApp(
        title: EnvironmentConfig.appName,
        theme: AppTheme.lightTheme,
        home: const AnugamiSplashScreen(),
        debugShowCheckedModeBanner:
            EnvironmentConfig.getFeatureFlag('showDebugBanner'),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider.value(value: _userProvider),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => OptimizedProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ],
      child: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          return MaterialApp.router(
            title: EnvironmentConfig.appName,
            debugShowCheckedModeBanner:
                EnvironmentConfig.getFeatureFlag('showDebugBanner'),
            theme: AppTheme.lightTheme,
            routerConfig: AppRoutes.createRouter(
              isLoggedIn: userProvider.isLoggedIn,
              refreshListenable: userProvider,
            ),
            scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor:
                      MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.3),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                Text(
                  'Oops!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart App'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
