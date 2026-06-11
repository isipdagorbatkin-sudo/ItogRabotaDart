import '../errors/exceptions.dart';
import '../models/food_order.dart';
import '../repositories/repository.dart';
import '../storage/binary_storage.dart';

class OrderService {
  OrderService(this.repository, this.storage);

  final Repository<FoodOrder> repository;
  final BinaryStorage<FoodOrder> storage;

  Future<void> load() async {
    final items = await storage.load();
    repository.setAll(items);
  }

  Future<void> save() async {
    await storage.save(repository.getAll());
  }

  Future<FoodOrder> addOrder({
    required String customerName,
    required String restaurantName,
    required double totalPrice,
    required int itemCount,
    required bool paid,
    required OrderStatus status,
    required DeliveryType deliveryType,
    String? comment,
  }) async {
    _checkText(customerName, 'Имя клиента');
    _checkText(restaurantName, 'Название ресторана');
    if (totalPrice <= 0) {
      throw ValidationException('Сумма заказа должна быть больше 0');
    }
    if (itemCount <= 0) {
      throw ValidationException('Количество блюд должно быть больше 0');
    }

    final order = FoodOrder(
      id: repository.lastId + 1,
      customerName: customerName,
      restaurantName: restaurantName,
      totalPrice: totalPrice,
      itemCount: itemCount,
      paid: paid,
      status: status,
      deliveryType: deliveryType,
      comment: comment,
    );
    repository.add(order);
    await save();
    return order;
  }

  Future<void> deleteOrder(int id) async {
    repository.remove(id);
    await save();
  }

  Future<FoodOrder> editOrder({
    required int id,
    required String customerName,
    required String restaurantName,
    required double totalPrice,
    required int itemCount,
    required bool paid,
    required OrderStatus status,
    required DeliveryType deliveryType,
    String? comment,
  }) async {
    repository.getById(id);
    final order = FoodOrder(
      id: id,
      customerName: customerName,
      restaurantName: restaurantName,
      totalPrice: totalPrice,
      itemCount: itemCount,
      paid: paid,
      status: status,
      deliveryType: deliveryType,
      comment: comment,
    );
    repository.update(order);
    await save();
    return order;
  }

  List<FoodOrder> search(String text) {
    final query = text.toLowerCase();
    return repository.getAll().where((order) {
      return order.customerName.toLowerCase().contains(query) ||
          order.restaurantName.toLowerCase().contains(query) ||
          (order.comment ?? '').toLowerCase().contains(query);
    }).toList();
  }

  List<FoodOrder> getAllSorted() {
    final orders = repository.getAll();
    orders.sort((a, b) => a.id.compareTo(b.id));
    return orders;
  }

  String stats() {
    final orders = repository.getAll();
    if (orders.isEmpty) {
      return 'Заказов пока нет.';
    }

    var sum = 0.0;
    var paidCount = 0;
    for (final order in orders) {
      sum += order.totalPrice;
      if (order.paid) {
        paidCount++;
      }
    }
    return 'Всего заказов: ${orders.length}\n'
        'Общая сумма: ${sum.toStringAsFixed(2)} руб.\n'
        'Оплачено заказов: $paidCount\n'
        'Средний чек: ${(sum / orders.length).toStringAsFixed(2)} руб.';
  }

  Future<void> fillTestDataIfEmpty() async {
    if (repository.count > 0) {
      return;
    }

    final testOrders = <FoodOrder>[
      FoodOrder(
        id: 1,
        customerName: 'Иван',
        restaurantName: 'Пицца Дом',
        totalPrice: 890,
        itemCount: 2,
        paid: true,
        status: OrderStatus.delivering,
        deliveryType: DeliveryType.courier,
        comment: 'Без лука',
      ),
      FoodOrder(
        id: 2,
        customerName: 'Анна',
        restaurantName: 'Суши Маркет',
        totalPrice: 1240,
        itemCount: 3,
        paid: false,
        status: OrderStatus.cooking,
        deliveryType: DeliveryType.express,
      ),
      FoodOrder(
        id: 3,
        customerName: 'Петр',
        restaurantName: 'Бургерная',
        totalPrice: 610,
        itemCount: 1,
        paid: true,
        status: OrderStatus.done,
        deliveryType: DeliveryType.pickup,
        comment: 'Позвонить заранее',
      ),
      FoodOrder(
        id: 4,
        customerName: 'Ольга',
        restaurantName: 'Вкусный обед',
        totalPrice: 470,
        itemCount: 2,
        paid: false,
        status: OrderStatus.newOrder,
        deliveryType: DeliveryType.courier,
      ),
      FoodOrder(
        id: 5,
        customerName: 'Сергей',
        restaurantName: 'Шашлык 24',
        totalPrice: 1580,
        itemCount: 4,
        paid: true,
        status: OrderStatus.done,
        deliveryType: DeliveryType.express,
        comment: 'Острый соус отдельно',
      ),
    ];

    repository.setAll(testOrders);
    await save();
  }

  void _checkText(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw ValidationException('$fieldName не может быть пустым');
    }
  }
}
