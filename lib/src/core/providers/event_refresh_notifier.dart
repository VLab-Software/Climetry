import 'package:flutter/foundation.dart';

/// Notificador para atualizar listas de eventos entre diferentes telas
class EventRefreshNotifier extends ChangeNotifier {
  int _refreshCount = 0;

  int get refreshCount => _refreshCount;

  /// Notifica que os eventos foram atualizados (adição, edição ou remoção)
  void notifyEventsChanged() {
    _refreshCount++;
    notifyListeners();
  }

  /// Reseta o contador (usado para debugging)
  void reset() {
    _refreshCount = 0;
    notifyListeners();
  }
}
