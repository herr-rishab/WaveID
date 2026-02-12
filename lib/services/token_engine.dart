class TokenEngine {
  const TokenEngine({
    this.windowSeconds = 15,
    this.length = 4,
  });

  final int windowSeconds;
  final int length;

  int currentWindow([DateTime? now]) {
    final DateTime timestamp = now ?? DateTime.now();
    final int seconds = timestamp.millisecondsSinceEpoch ~/ 1000;
    return seconds ~/ windowSeconds;
  }

  String tokenForSeed(int seed, int window) {
    final int maxValue = _pow10(length);
    final int value = (seed + window) % maxValue;
    return value.toString().padLeft(length, '0');
  }

  String currentToken(int seed, [DateTime? now]) {
    return tokenForSeed(seed, currentWindow(now));
  }

  bool isTokenValid(String token, int seed, [DateTime? now]) {
    final int window = currentWindow(now);
    return token == tokenForSeed(seed, window) || token == tokenForSeed(seed, window - 1);
  }

  int _pow10(int exponent) {
    int value = 1;
    for (int i = 0; i < exponent; i++) {
      value *= 10;
    }
    return value;
  }
}
