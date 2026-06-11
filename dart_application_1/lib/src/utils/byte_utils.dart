import 'dart:convert';
import 'dart:typed_data';

class ByteWriter {
  final BytesBuilder _builder = BytesBuilder();

  Uint8List toBytes() {
    return _builder.toBytes();
  }

  void writeInt(int value) {
    final data = ByteData(4);
    data.setInt32(0, value, Endian.big);
    _builder.add(data.buffer.asUint8List());
  }

  void writeDouble(double value) {
    final data = ByteData(8);
    data.setFloat64(0, value, Endian.big);
    _builder.add(data.buffer.asUint8List());
  }

  void writeBool(bool value) {
    _builder.addByte(value ? 1 : 0);
  }

  void writeEnum(int index) {
    _builder.addByte(index);
  }

  void writeString(String value) {
    final bytes = utf8.encode(value);
    writeInt(bytes.length);
    _builder.add(bytes);
  }

  void writeNullableString(String? value) {
    if (value == null) {
      _builder.addByte(0);
    } else {
      _builder.addByte(1);
      writeString(value);
    }
  }
}

class ByteReader {
  ByteReader(Uint8List bytes) : _data = ByteData.sublistView(bytes);

  final ByteData _data;
  int _offset = 0;

  int readInt() {
    final value = _data.getInt32(_offset, Endian.big);
    _offset += 4;
    return value;
  }

  double readDouble() {
    final value = _data.getFloat64(_offset, Endian.big);
    _offset += 8;
    return value;
  }

  bool readBool() {
    final value = _data.getUint8(_offset) == 1;
    _offset += 1;
    return value;
  }

  int readEnum() {
    final value = _data.getUint8(_offset);
    _offset += 1;
    return value;
  }

  String readString() {
    final length = readInt();
    final bytes = _data.buffer.asUint8List(
      _data.offsetInBytes + _offset,
      length,
    );
    _offset += length;
    return utf8.decode(bytes);
  }

  String? readNullableString() {
    final flag = _data.getUint8(_offset);
    _offset += 1;
    if (flag == 0) {
      return null;
    }
    return readString();
  }
}
