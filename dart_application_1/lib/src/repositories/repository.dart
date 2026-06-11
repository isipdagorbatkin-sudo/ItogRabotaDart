import '../errors/exceptions.dart';
import '../models/identifiable.dart';

class Repository<T extends Identifiable> {
  final Map<int, T> _items = <int, T>{};

  int get count => _items.length;

  int get lastId {
    if (_items.isEmpty) {
      return 0;
    }
    return _items.keys.reduce((a, b) => a > b ? a : b);
  }

  void setAll(List<T> items) {
    _items.clear();
    for (final item in items) {
      _items[item.getId()] = item;
    }
  }

  void add(T item) {
    _items[item.getId()] = item;
  }

  void remove(int id) {
    if (!_items.containsKey(id)) {
      throw NotFoundException('Объект с ID=$id не найден');
    }
    _items.remove(id);
  }

  void update(T item) {
    final id = item.getId();
    if (!_items.containsKey(id)) {
      throw NotFoundException('Объект с ID=$id не найден');
    }
    _items[id] = item;
  }

  T getById(int id) {
    final item = _items[id];
    if (item == null) {
      throw NotFoundException('Объект с ID=$id не найден');
    }
    return item;
  }

  List<T> getAll() {
    return _items.values.toList();
  }
}
