import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class AppConfig {
  static String get airKey {
    return dotenv.env['AIR_API_KEY'] ?? '';
  }

  static String get weatherKey {
    return dotenv.env['WEATHER_API_KEY'] ?? '';
  }

  static String get geolocationKey {
    return dotenv.env['GEOLOCATION_API_KEY'] ?? '';
  }

  static Level get logLevel {
    final logLevelString = dotenv.env['LOG_LEVEL'] ?? 'info';

    return Level.values.firstWhere(
      (level) => level.name.toLowerCase() == logLevelString.toLowerCase(),
      orElse: () => Level.info,
    );
  }
}
