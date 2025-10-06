import 'package:flutter/foundation.dart';

class EventRefreshNotifier extends ChangeNotifier {
  int _refreshCount = 0;

  int get refreshCount => _refreshCount;

  void notifyEventsChanged() {
    _refreshCount++;
    notifyListeners();
  }

  void reset() {
    _refreshCount = 0;
    notifyListeners();
  }
}
