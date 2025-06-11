import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvVariables {
  static String get googlePlacesApiKey => dotenv.env['googlePlacesApiKey'] ?? '';
}
