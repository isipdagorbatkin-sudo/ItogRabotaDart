import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_application_1/food_delivery.dart';

Future<void> main() async {
  stdout.encoding = utf8;

  final storage = BinaryStorage<FoodOrder>(
    'data.bin',
    (FoodOrder order) => order.toBytes(),
    (Uint8List bytes) => FoodOrder.fromBytes(bytes),
  );
  final repository = Repository<FoodOrder>();
  final service = OrderService(repository, storage);
  final logger = LoggerService('logs.txt');
  final reportService = ReportService();

  await logger.start();
  logger.log(ActionType.start, 'Приложение запущено');

  try {
    await service.load();
  } on StorageException {
    await storage.createEmpty();
    logger.log(ActionType.start, 'Файл data.bin не найден, создан новый');
  }

  await service.fillTestDataIfEmpty();

  var work = true;
  while (work) {
    _printMenu(repository);
    final choice = _readLine('Выберите действие: ');

    try {
      switch (choice) {
        case '1':
          await _addOrder(service, logger);
        case '2':
          await _deleteOrder(service, logger);
        case '3':
          await _editOrder(service, logger);
        case '4':
          _searchOrders(service, logger);
        case '5':
          _listOrders(service, logger);
        case '6':
          _showStats(service, logger);
        case '7':
          await _showLogs(logger);
        case '8':
          await _makeReport(service, repository, reportService, logger);
        case '0':
          logger.log(ActionType.exit, 'Приложение завершено');
          work = false;
        default:
          print('Нет такого пункта меню.');
      }
    } on ValidationException catch (error) {
      logger.log(ActionType.error, error.message);
      print(error.message);
    } on NotFoundException catch (error) {
      logger.log(ActionType.error, error.message);
      print(error.message);
    } on StorageException catch (error) {
      logger.log(ActionType.error, error.message);
      print(error.message);
    } on LogFileException catch (error) {
      print(error.message);
    } on Object catch (error) {
      logger.log(ActionType.error, error.toString());
      print('Ошибка: $error');
    }

    if (work) {
      _pause();
    }
  }

  await logger.stop();
}

void _printMenu(Repository<FoodOrder> repository) {
  print('\n=== Доставка еды из ресторана ===');
  print('1. Добавить объект');
  print('2. Удалить объект (по ID)');
  print('3. Редактировать объект');
  print('4. Поиск объектов');
  print('5. Показать все (с сортировкой)');
  print('6. Статистика');
  print('7. Показать логи');
  print('8. Асинхронный отчет (изолят)');
  print('0. Выход');
  print('Объектов: ${repository.count}, последний ID: ${repository.lastId}');
}

Future<void> _addOrder(OrderService service, LoggerService logger) async {
  final order = await service.addOrder(
    customerName: _readLine('Имя клиента: '),
    restaurantName: _readLine('Название ресторана: '),
    totalPrice: _readDouble('Сумма заказа: '),
    itemCount: _readInt('Количество блюд: '),
    paid: _readBool('Оплачен? (y/n): '),
    status: _readStatus(),
    deliveryType: _readDeliveryType(),
    comment: _readNullable('Комментарий (можно пусто): '),
  );
  logger.log(ActionType.add, 'Добавлен заказ ID=${order.id}');
  print('Заказ добавлен: $order');
}

Future<void> _deleteOrder(OrderService service, LoggerService logger) async {
  final id = _readInt('ID для удаления: ');
  await service.deleteOrder(id);
  logger.log(ActionType.delete, 'Удален заказ ID=$id');
  print('Удалено.');
}

Future<void> _editOrder(OrderService service, LoggerService logger) async {
  final id = _readInt('ID для редактирования: ');
  final old = service.repository.getById(id);
  print('Старые данные: $old');
  final order = await service.editOrder(
    id: id,
    customerName: _readLine('Новое имя клиента: '),
    restaurantName: _readLine('Новый ресторан: '),
    totalPrice: _readDouble('Новая сумма: '),
    itemCount: _readInt('Новое количество блюд: '),
    paid: _readBool('Оплачен? (y/n): '),
    status: _readStatus(),
    deliveryType: _readDeliveryType(),
    comment: _readNullable('Комментарий (можно пусто): '),
  );
  logger.log(ActionType.edit, 'Изменен заказ ID=$id');
  print('Заказ изменен: $order');
}

void _searchOrders(OrderService service, LoggerService logger) {
  final text = _readLine('Введите текст для поиска: ');
  final result = service.search(text);
  logger.log(ActionType.search, 'Поиск: $text, найдено ${result.length}');
  _printOrders(result);
}

void _listOrders(OrderService service, LoggerService logger) {
  final orders = service.getAllSorted();
  logger.log(ActionType.list, 'Показан список заказов');
  _printOrders(orders);
}

void _showStats(OrderService service, LoggerService logger) {
  logger.log(ActionType.stats, 'Показана статистика');
  print(service.stats());
}

Future<void> _showLogs(LoggerService logger) async {
  logger.log(ActionType.viewLogs, 'Показаны последние строки лога');
  final lines = await logger.getLastLines(20);
  if (lines.isEmpty) {
    print('Лог пустой.');
    return;
  }
  for (final line in lines) {
    print(line);
  }
}

Future<void> _makeReport(
  OrderService service,
  Repository<FoodOrder> repository,
  ReportService reportService,
  LoggerService logger,
) async {
  logger.log(ActionType.report, 'Запущен асинхронный отчет');
  print('Отчет генерируется...');
  final report = await reportService.makeReport(repository.getAll());
  print(report);
  await _copyLogFile();
  print('Дополнительно создана копия logs_copy.txt через openRead/openWrite.');
}

Future<void> _copyLogFile() async {
  final source = File('logs.txt');
  if (!await source.exists()) {
    return;
  }

  final target = File('logs_copy.txt');
  final input = source.openRead();
  final output = target.openWrite();
  await input.pipe(output);
}

void _printOrders(List<FoodOrder> orders) {
  if (orders.isEmpty) {
    print('Ничего не найдено.');
    return;
  }

  for (final order in orders) {
    print(order);
  }
}

String _readLine(String message) {
  stdout.write(message);
  return stdin.readLineSync(encoding: utf8) ?? '';
}

String? _readNullable(String message) {
  final value = _readLine(message).trim();
  if (value.isEmpty) {
    return null;
  }
  return value;
}

int _readInt(String message) {
  final value = int.tryParse(_readLine(message));
  if (value == null) {
    throw ValidationException('Нужно ввести целое число');
  }
  return value;
}

double _readDouble(String message) {
  final value = double.tryParse(_readLine(message).replaceAll(',', '.'));
  if (value == null) {
    throw ValidationException('Нужно ввести число');
  }
  return value;
}

bool _readBool(String message) {
  final value = _readLine(message).toLowerCase();
  return value == 'y' || value == 'yes' || value == 'д' || value == 'да';
}

OrderStatus _readStatus() {
  print('Статус:');
  print('1. Новый');
  print('2. Готовится');
  print('3. Доставляется');
  print('4. Завершен');
  print('5. Отменен');
  final value = _readInt('Выберите статус: ');
  if (value < 1 || value > OrderStatus.values.length) {
    throw ValidationException('Неверный статус');
  }
  return OrderStatus.values[value - 1];
}

DeliveryType _readDeliveryType() {
  print('Тип доставки:');
  print('1. Курьер');
  print('2. Самовывоз');
  print('3. Экспресс');
  final value = _readInt('Выберите тип доставки: ');
  if (value < 1 || value > DeliveryType.values.length) {
    throw ValidationException('Неверный тип доставки');
  }
  return DeliveryType.values[value - 1];
}

void _pause() {
  stdout.write('\nНажмите Enter...');
  stdin.readLineSync();
}
