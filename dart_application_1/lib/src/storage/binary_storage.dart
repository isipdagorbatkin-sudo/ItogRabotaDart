import 'dart:io';
import 'dart:typed_data';

import '../errors/exceptions.dart';
import '../models/identifiable.dart';

typedef ToBytes<T> = Uint8List Function(T item);
typedef FromBytes<T> = T Function(Uint8List bytes);

class BinaryStorage<T extends Identifiable> {
  BinaryStorage(this.fileName, this.toBytes, this.fromBytes);

  final String fileName;
  final ToBytes<T> toBytes;
  final FromBytes<T> fromBytes;

  Future<void> save(List<T> items) async {
    try {
      final builder = BytesBuilder();
      final countData = ByteData(4);
      countData.setInt32(0, items.length, Endian.big);
      builder.add(countData.buffer.asUint8List());

      for (final item in items) {
        final bytes = toBytes(item);
        final lengthData = ByteData(4);
        lengthData.setInt32(0, bytes.length, Endian.big);
        builder.add(lengthData.buffer.asUint8List());
        builder.add(bytes);
      }

      await File(fileName).writeAsBytes(builder.toBytes());
    } on Object catch (error) {
      throw StorageException('Ошибка сохранения файла: $error');
    }
  }

  Future<List<T>> load() async {
    final file = File(fileName);
    if (!await file.exists()) {
      throw StorageException('Файл $fileName не найден');
    }

    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return <T>[];
      }

      final data = ByteData.sublistView(bytes);
      var offset = 0;
      final count = data.getInt32(offset, Endian.big);
      offset += 4;

      final result = <T>[];
      for (var i = 0; i < count; i++) {
        final length = data.getInt32(offset, Endian.big);
        offset += 4;
        final itemBytes = bytes.sublist(offset, offset + length);
        offset += length;
        result.add(fromBytes(Uint8List.fromList(itemBytes)));
      }
      return result;
    } on Object catch (error) {
      throw StorageException('Ошибка чтения файла: $error');
    }
  }

  Future<void> createEmpty() async {
    await save(<T>[]);
  }
}
