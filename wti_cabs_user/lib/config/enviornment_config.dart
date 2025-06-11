enum EnvironmentType { dev, staging, production }

class EnvironmentConfig {
  static EnvironmentType _environment = EnvironmentType.dev;

  static void setEnvironment(EnvironmentType environment) {
    _environment = environment;
  }

  static String get baseUrl {
    switch (_environment) {
      case EnvironmentType.dev:
        return "https://test.wticabs.com:5001";
      case EnvironmentType.staging:
        return "https://staging.example.com/api";
      case EnvironmentType.production:
        return "https://www.wticabs.com:3001";
    }
  }

  static String get priceBaseUrl {
    switch (_environment) {
      case EnvironmentType.dev:
        return "https://dev.example.com/price";
      case EnvironmentType.staging:
        return "https://staging.example.com/price";
      case EnvironmentType.production:
        return "https://global.wticabs.com:4001/0auth/v1";
    }
  }

  static EnvironmentType get environment => _environment;
}
