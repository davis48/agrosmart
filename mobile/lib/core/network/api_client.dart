import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:agriculture/core/config/environment_config.dart';
import 'package:agriculture/core/services/secure_storage_service.dart';

/// Gestionnaire de Certificate Pinning pour la sécurité SSL
class CertificatePinningManager {
  static final CertificatePinningManager _instance =
      CertificatePinningManager._internal();
  factory CertificatePinningManager() => _instance;
  CertificatePinningManager._internal();

  SecurityContext? _securityContext;
  bool _isInitialized = false;

  /// Initialise le certificate pinning en production
  Future<void> init() async {
    if (_isInitialized || !EnvironmentConfig.isProduction) {
      debugPrint('[SECURITY] 📋 Certificate pinning skipped (not in production)');
      return;
    }

    try {
      // Charger les certificats depuis les assets (à ajouter: assets/certs/api_cert.pem)
      final certData = await rootBundle.load('assets/certs/api_cert.pem');
      _securityContext = SecurityContext()
        ..setTrustedCertificatesBytes(certData.buffer.asUint8List());
      _isInitialized = true;
      debugPrint('[SECURITY] ✅ Certificate pinning initialisé');
    } catch (e) {
      debugPrint('[SECURITY] ⚠️ Certificate pinning non configuré: $e');
      // En prod, on ne veut pas bloquer si le certificat n'est pas disponible
      // mais on devrait logger cet événement
      _isInitialized = false;
    }
  }

  /// Configure l'adaptateur HTTP avec certificate pinning
  void configureHttpClient(Dio dio) {
    if (!EnvironmentConfig.isProduction || _securityContext == null) return;

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient(context: _securityContext);
      // Rejeter les certificats non valides en production
      client.badCertificateCallback = (cert, host, port) => false;
      return client;
    };
  }
}

/// Service singleton pour la gestion du stockage sécurisé dans l'API client
class ApiTokenManager {
  static final ApiTokenManager _instance = ApiTokenManager._internal();
  factory ApiTokenManager() => _instance;
  ApiTokenManager._internal();

  SecureStorageService? _secureStorage;

  void init(SecureStorageService secureStorage) {
    _secureStorage = secureStorage;
  }

  Future<String?> getToken() async {
    return await _secureStorage?.getAccessToken();
  }

  Future<void> saveToken(String token) async {
    await _secureStorage?.saveAccessToken(token);
  }

  Future<void> clearToken() async {
    await _secureStorage?.clearTokens();
  }
}

/// Client Dio configuré avec interception pour l'authentification
late Dio dioClient;

/// Initialise le client Dio avec le stockage sécurisé
Future<void> initDioClient(SecureStorageService secureStorage) async {
  ApiTokenManager().init(secureStorage);

  // Initialiser le certificate pinning en production
  await CertificatePinningManager().init();

  dioClient = Dio(
    BaseOptions(
      baseUrl: EnvironmentConfig.apiBaseUrl,
      connectTimeout: Duration(seconds: EnvironmentConfig.connectionTimeout),
      receiveTimeout: Duration(seconds: EnvironmentConfig.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Configurer le certificate pinning pour le client Dio
  CertificatePinningManager().configureHttpClient(dioClient);

  // Intercepteur pour l'authentification et le logging
  dioClient.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Log seulement en dev/staging
        if (EnvironmentConfig.enableNetworkLogs) {
          debugPrint('[DIO] 🌐 URL: ${options.baseUrl}${options.path}');
          debugPrint('[DIO] 📡 Méthode: ${options.method}');
        }

        // Récupérer le token de manière sécurisée
        final token = await ApiTokenManager().getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          // Debug: Log first 50 chars of token to verify it exists
          debugPrint(
            '[DIO] 🔑 Token: ${token.substring(0, token.length > 50 ? 50 : token.length)}...',
          );
        } else {
          debugPrint('[DIO] ⚠️ NO TOKEN FOUND - Request will be unauthorized');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (EnvironmentConfig.enableNetworkLogs) {
          debugPrint('[DIO] ✅ Response: ${response.statusCode}');
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        if (EnvironmentConfig.enableNetworkLogs) {
          debugPrint('[DIO ERROR] ❌ ${e.type}: ${e.message}');
        }

        // Gérer l'expiration du token (401)
        if (e.response?.statusCode == 401) {
          debugPrint('[DIO] 🔒 Token expiré - refresh nécessaire');
        }

        return handler.next(e);
      },
    ),
  );
}

class ApiClient {
  final Dio dio;

  ApiClient({required this.dio});

  // Getter for baseUrl to help with image resolving if needed elsewhere
  String get baseUrl => dio.options.baseUrl;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await dio.patch(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await dio.delete(path);
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await ApiTokenManager().getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Response> postMultipart(
    String path,
    Map<String, dynamic> fields,
    List<File> files, {
    String fileField = 'images',
  }) async {
    FormData formData = FormData.fromMap(fields);

    for (var file in files) {
      String fileName = file.path.split('/').last;
      formData.files.add(
        MapEntry(
          fileField,
          await MultipartFile.fromFile(file.path, filename: fileName),
        ),
      );
    }

    return await dio.post(path, data: formData);
  }
}
