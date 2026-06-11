// ignore_for_file: unnecessary_getters_setters

import 'dart:typed_data';

import '../utils/byte_utils.dart';
import 'identifiable.dart';

enum OrderStatus { newOrder, cooking, delivering, done, canceled }

enum DeliveryType { courier, pickup, express }

class FoodOrder extends Identifiable {
  FoodOrder({
    required int id,
    required String customerName,
    required String restaurantName,
    required double totalPrice,
    required int itemCount,
    required bool paid,
    required OrderStatus status,
    required DeliveryType deliveryType,
    String? comment,
  }) : _id = id,
       _customerName = customerName,
       _restaurantName = restaurantName,
       _totalPrice = totalPrice,
       _itemCount = itemCount,
       _paid = paid,
       _status = status,
       _deliveryType = deliveryType,
       _comment = comment;

  int _id;
  String _customerName;
  String _restaurantName;
  double _totalPrice;
  int _itemCount;
  bool _paid;
  OrderStatus _status;
  DeliveryType _deliveryType;
  String? _comment;

  int get id => _id;
  String get customerName => _customerName;
  String get restaurantName => _restaurantName;
  double get totalPrice => _totalPrice;
  int get itemCount => _itemCount;
  bool get paid => _paid;
  OrderStatus get status => _status;
  DeliveryType get deliveryType => _deliveryType;
  String? get comment => _comment;

  set customerName(String value) => _customerName = value;
  set restaurantName(String value) => _restaurantName = value;
  set totalPrice(double value) => _totalPrice = value;
  set itemCount(int value) => _itemCount = value;
  set paid(bool value) => _paid = value;
  set status(OrderStatus value) => _status = value;
  set deliveryType(DeliveryType value) => _deliveryType = value;
  set comment(String? value) => _comment = value;

  @override
  int getId() {
    return _id;
  }

  Uint8List toBytes() {
    final writer = ByteWriter();
    writer.writeInt(_id);
    writer.writeString(_customerName);
    writer.writeString(_restaurantName);
    writer.writeDouble(_totalPrice);
    writer.writeInt(_itemCount);
    writer.writeBool(_paid);
    writer.writeEnum(_status.index);
    writer.writeEnum(_deliveryType.index);
    writer.writeNullableString(_comment);
    return writer.toBytes();
  }

  factory FoodOrder.fromBytes(Uint8List bytes) {
    final reader = ByteReader(bytes);
    return FoodOrder(
      id: reader.readInt(),
      customerName: reader.readString(),
      restaurantName: reader.readString(),
      totalPrice: reader.readDouble(),
      itemCount: reader.readInt(),
      paid: reader.readBool(),
      status: OrderStatus.values[reader.readEnum()],
      deliveryType: DeliveryType.values[reader.readEnum()],
      comment: reader.readNullableString(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': _id,
      'customerName': _customerName,
      'restaurantName': _restaurantName,
      'totalPrice': _totalPrice,
      'itemCount': _itemCount,
      'paid': _paid,
      'status': _status.index,
      'deliveryType': _deliveryType.index,
      'comment': _comment,
    };
  }

  factory FoodOrder.fromMap(Map<String, Object?> map) {
    return FoodOrder(
      id: map['id'] as int,
      customerName: map['customerName'] as String,
      restaurantName: map['restaurantName'] as String,
      totalPrice: map['totalPrice'] as double,
      itemCount: map['itemCount'] as int,
      paid: map['paid'] as bool,
      status: OrderStatus.values[map['status'] as int],
      deliveryType: DeliveryType.values[map['deliveryType'] as int],
      comment: map['comment'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FoodOrder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    final payText = paid ? 'оплачен' : 'не оплачен';
    final commentText = comment == null || comment!.isEmpty ? '-' : comment;
    return 'ID=$id | $customerName | $restaurantName | '
        '${totalPrice.toStringAsFixed(2)} руб. | блюд: $itemCount | '
        '$payText | ${statusText(status)} | ${deliveryTypeText(deliveryType)} | '
        'комментарий: $commentText';
  }
}

String statusText(OrderStatus status) {
  switch (status) {
    case OrderStatus.newOrder:
      return 'новый';
    case OrderStatus.cooking:
      return 'готовится';
    case OrderStatus.delivering:
      return 'доставляется';
    case OrderStatus.done:
      return 'завершен';
    case OrderStatus.canceled:
      return 'отменен';
  }
}

String deliveryTypeText(DeliveryType type) {
  switch (type) {
    case DeliveryType.courier:
      return 'курьер';
    case DeliveryType.pickup:
      return 'самовывоз';
    case DeliveryType.express:
      return 'экспресс';
  }
}
