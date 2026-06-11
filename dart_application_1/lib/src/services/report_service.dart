import 'dart:isolate';

import '../models/food_order.dart';

class ReportService {
  Future<String> makeReport(List<FoodOrder> orders) async {
    final receivePort = ReceivePort();
    final maps = orders.map((order) => order.toMap()).toList();
    await Isolate.spawn(_reportIsolate, [receivePort.sendPort, maps]);
    final result = await receivePort.first as String;
    receivePort.close();
    return result;
  }
}

void _reportIsolate(List<Object> args) {
  final sendPort = args[0] as SendPort;
  final rawOrders = args[1] as List<Object?>;

  var total = 0.0;
  var paid = 0;
  var maxPrice = 0.0;
  var maxRestaurant = '-';

  for (final raw in rawOrders) {
    final map = raw as Map<String, Object?>;
    final price = map['totalPrice'] as double;
    total += price;
    if (map['paid'] as bool) {
      paid++;
    }
    if (price > maxPrice) {
      maxPrice = price;
      maxRestaurant = map['restaurantName'] as String;
    }

    for (var i = 0; i < 100000; i++) {
      total += 0;
    }
  }

  final count = rawOrders.length;
  final average = count == 0 ? 0.0 : total / count;
  final text =
      'Асинхронный отчет\n'
      'Заказов: $count\n'
      'Оплачено: $paid\n'
      'Общая сумма: ${total.toStringAsFixed(2)} руб.\n'
      'Средний чек: ${average.toStringAsFixed(2)} руб.\n'
      'Самый дорогой ресторан: $maxRestaurant';
  sendPort.send(text);
}
