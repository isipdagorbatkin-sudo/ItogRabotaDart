class ValidationException implements Exception {
  ValidationException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}

class NotFoundException implements Exception {
  NotFoundException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}

class StorageException implements Exception {
  StorageException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}

class LogFileException implements Exception {
  LogFileException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
