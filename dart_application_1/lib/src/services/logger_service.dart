import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import '../enums/action_type.dart';
import '../errors/exceptions.dart';

class LoggerService {
  LoggerService(this.fileName);

  final String fileName;
  SendPort? _sendPort;
  Isolate? _isolate;

  Future<void> start() async {
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_loggerIsolate, [
      receivePort.sendPort,
      fileName,
    ]);
    _sendPort = await receivePort.first as SendPort;
  }

  void log(ActionType type, String message) {
    final port = _sendPort;
    if (port == null) {
      print('Предупреждение: логгер еще не запущен');
      return;
    }
    port.send([actionName(type), message]);
  }

  Future<List<String>> getLastLines(int count) async {
    try {
      final file = File(fileName);
      if (!await file.exists()) {
        return <String>[];
      }

      final lines = <String>[];
      final stream = file
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final line in stream) {
        lines.add(line);
        if (lines.length > count) {
          lines.removeAt(0);
        }
      }
      return lines;
    } on Object catch (error) {
      throw LogFileException('Не удалось прочитать лог: $error');
    }
  }

  Future<void> stop() async {
    _sendPort?.send('close');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _isolate?.kill(priority: Isolate.immediate);
  }
}

void _loggerIsolate(List<Object> args) {
  final mainPort = args[0] as SendPort;
  final fileName = args[1] as String;
  final receivePort = ReceivePort();
  mainPort.send(receivePort.sendPort);

  receivePort.listen((message) async {
    if (message == 'close') {
      receivePort.close();
      return;
    }

    try {
      final list = message as List<Object?>;
      final action = list[0] as String;
      final text = list[1] as String;
      final line = '[${_timeText()}] [$action] $text\n';
      File(
        fileName,
      ).writeAsStringSync(line, mode: FileMode.append, encoding: utf8);
    } on Object catch (error) {
      print('Ошибка записи лога: $error');
    }
  });
}

String _timeText() {
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)} '
      '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
}
