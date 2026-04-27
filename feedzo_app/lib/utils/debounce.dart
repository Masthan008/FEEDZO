import 'dart:async';

/// Debounce utility for performance optimization
/// Prevents rapid-fire function calls (e.g., search input)
/// 
/// Usage:
/// ```dart
/// final _debouncer = Debouncer(milliseconds: 500);
/// 
/// onSearchChanged(String value) {
///   _debouncer.run(() => performSearch(value));
/// }
/// ```
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void cancel() {
    _timer?.cancel();
  }
}

/// Throttle utility for rate limiting
/// Ensures function is called at most once per interval
/// 
/// Usage:
/// ```dart
/// final _throttler = Throttler(interval: Duration(milliseconds: 1000));
/// 
/// onButtonPressed() {
///   _throttler.run(() => submitOrder());
/// }
/// ```
class Throttler {
  final Duration interval;
  DateTime? _lastExecution;
  Timer? _pendingTimer;

  Throttler({required this.interval});

  void run(VoidCallback action) {
    final now = DateTime.now();
    
    if (_lastExecution == null || 
        now.difference(_lastExecution!) >= interval) {
      _lastExecution = now;
      action();
    } else {
      _pendingTimer?.cancel();
      final remaining = interval - now.difference(_lastExecution!);
      _pendingTimer = Timer(remaining, () {
        _lastExecution = DateTime.now();
        action();
      });
    }
  }

  void cancel() {
    _pendingTimer?.cancel();
  }
}
