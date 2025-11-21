import 'package:flutter/foundation.dart';

/// Configuração centralizada do aplicativo
class Config {
  // URLs da API
  static const String _apiUrlDev = 'http://localhost:8000';
  static const String _apiUrlProd = 'https://portfolio-api-docker.onrender.com';

  // Detecção automática de ambiente
  static bool get isProduction => kReleaseMode;
  static bool get isDevelopment => !isProduction;

  // URL da API baseada no ambiente
  static String get apiUrl => isProduction ? _apiUrlProd : _apiUrlDev;

  // Nome do ambiente
  static String get environmentName => isProduction ? 'PROD' : 'DEV';

  // Configurações de timeout
  static const Duration defaultTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(seconds: 30);

  // Configurações de debug
  static bool get showDebugInfo => isDevelopment;

  /// Imprime informações de configuração no console
  static void printConfig() {
    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════');
      print('🚀 CONFIGURAÇÃO DO APP');
      print('═══════════════════════════════════════════════════════');
      print('📱 Ambiente: $environmentName');
      print('🌐 API URL: $apiUrl');
      print('⏱️  Timeout padrão: ${defaultTimeout.inSeconds}s');
      print('🐛 Debug mode: $isDevelopment');
      print('═══════════════════════════════════════════════════════');
    }
  }
}
