class TokenService {
  static const int windowSeconds = 30;

  static int currentWindow([DateTime? now]) {
    final DateTime timestamp = now ?? DateTime.now();
    final int seconds = timestamp.millisecondsSinceEpoch ~/ 1000;
    return seconds ~/ windowSeconds;
  }

  static String tokenForWindow(int window) {
    final int value = window % 10000;
    return value.toString().padLeft(4, '0');
  }

  static String currentToken([DateTime? now]) {
    return tokenForWindow(currentWindow(now));
  }

  static bool isValidToken(String token, [DateTime? now]) {
    final int window = currentWindow(now);
    return token == tokenForWindow(window) || token == tokenForWindow(window - 1);
  }
}
