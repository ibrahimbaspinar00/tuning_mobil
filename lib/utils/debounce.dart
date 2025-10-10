import 'dart:async';

class Debounce {
  final int milliseconds;
  Timer? _timer;

  Debounce({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class Throttle {
  final int milliseconds;
  Timer? _timer;
  bool _isThrottled = false;

  Throttle({required this.milliseconds});

  void run(VoidCallback action) {
    if (_isThrottled) return;
    
    _isThrottled = true;
    action();
    
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), () {
      _isThrottled = false;
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}

typedef VoidCallback = void Function();
