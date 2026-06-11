# Итоговая практическая работа

Тема: **доставка еды из ресторана**.

Программа является консольным приложением на Dart. В приложении можно добавлять,
удалять, редактировать, искать и просматривать заказы еды. Данные сохраняются в
бинарный файл `data.bin`, а действия пользователя пишутся в `logs.txt` через
отдельный изолят.

## 1. Предметная область и сущность

Основная сущность: `FoodOrder` - заказ еды.

Поля сущности:

| Поле | Тип | Назначение |
| --- | --- | --- |
| `id` | `int` | Уникальный автоинкрементный номер заказа |
| `customerName` | `String` | Имя клиента |
| `restaurantName` | `String` | Название ресторана |
| `totalPrice` | `double` | Сумма заказа |
| `itemCount` | `int` | Количество блюд |
| `paid` | `bool` | Оплачен заказ или нет |
| `status` | `OrderStatus` | Статус заказа |
| `deliveryType` | `DeliveryType` | Тип доставки |
| `comment` | `String?` | Комментарий, может быть `null` |

Перечисления:

| Enum | Значения |
| --- | --- |
| `OrderStatus` | `newOrder`, `cooking`, `delivering`, `done`, `canceled` |
| `DeliveryType` | `courier`, `pickup`, `express` |

## 2. Формат файла data.bin

Все числа записываются в big-endian. Строки записываются в UTF-8.

Общая структура файла:

| Смещение | Поле | Тип | Размер |
| --- | --- | --- | --- |
| `0` | `count` | `int32` | 4 байта |
| `4` | `recordLength_1` | `int32` | 4 байта |
| `8` | `record_1` | bytes | `recordLength_1` байт |
| `8 + recordLength_1` | `recordLength_2` | `int32` | 4 байта |
| `12 + recordLength_1` | `record_2` | bytes | `recordLength_2` байт |

Структура одной записи `FoodOrder`:

| Смещение внутри записи | Поле | Тип | Размер |
| --- | --- | --- | --- |
| `0` | `id` | `int32` | 4 байта |
| `4` | `customerNameLength` | `int32` | 4 байта |
| `8` | `customerName` | UTF-8 | `A` байт |
| `8 + A` | `restaurantNameLength` | `int32` | 4 байта |
| `12 + A` | `restaurantName` | UTF-8 | `B` байт |
| `12 + A + B` | `totalPrice` | `float64` | 8 байт |
| `20 + A + B` | `itemCount` | `int32` | 4 байта |
| `24 + A + B` | `paid` | `bool` | 1 байт |
| `25 + A + B` | `status` | enum index | 1 байт |
| `26 + A + B` | `deliveryType` | enum index | 1 байт |
| `27 + A + B` | `commentFlag` | nullable flag | 1 байт |
| `28 + A + B` | `commentLength` | `int32` | 4 байта, если комментарий есть |
| `32 + A + B` | `comment` | UTF-8 | `C` байт, если комментарий есть |

Где:

- `A` - длина `customerName` в байтах.
- `B` - длина `restaurantName` в байтах.
- `C` - длина `comment` в байтах.
- `commentFlag = 0` значит `null`.
- `commentFlag = 1` значит комментарий есть.

## 3. Структура проекта

```text
dart_application_1/
├── bin/
│   └── main.dart
├── lib/
│   ├── food_delivery.dart
│   └── src/
│       ├── enums/
│       │   └── action_type.dart
│       ├── errors/
│       │   └── exceptions.dart
│       ├── models/
│       │   ├── food_order.dart
│       │   └── identifiable.dart
│       ├── repositories/
│       │   └── repository.dart
│       ├── services/
│       │   ├── logger_service.dart
│       │   ├── order_service.dart
│       │   └── report_service.dart
│       ├── storage/
│       │   └── binary_storage.dart
│       └── utils/
│           └── byte_utils.dart
├── data.bin
├── logs.txt
├── logs_copy.txt
├── pubspec.yaml
└── README.md
```

Основные компоненты:

| Компонент | Назначение |
| --- | --- |
| `FoodOrder` | Модель заказа |
| `Repository<T>` | Хранение коллекции в `Map<int, T>` |
| `BinaryStorage<T>` | Сохранение и загрузка `data.bin` |
| `LoggerService` | Асинхронная запись логов через isolate |
| `OrderService` | Бизнес-логика |
| `ReportService` | Асинхронный отчет через isolate |
| `main.dart` | Консольное меню |

## 4. Сборка и запуск

Запуск:

```bash
dart run bin/main.dart
```

Компиляция:

```bash
dart compile exe bin/main.dart -o app
```

При первом запуске файла `data.bin` нет. Программа сама создает пустой файл,
добавляет 5 тестовых заказов и пишет событие в лог.

## 5. Что реализовано

- ООП: классы, абстрактный класс `Identifiable`, наследование, инкапсуляция.
- Сущность с приватными полями, геттерами, сеттерами, `toBytes`,
  `fromBytes`, `toMap`, `fromMap`, `==`, `hashCode`.
- Ручная бинарная сериализация без сторонних пакетов.
- Репозиторий `Repository<T>` с методами `add`, `remove`, `update`,
  `getById`, `getAll`.
- Асинхронное сохранение и загрузка файла.
- Логирование в `logs.txt` через отдельный изолят.
- Чтение последних строк лога через `openRead`.
- Копирование лога в `logs_copy.txt` через `openRead/openWrite`.
- Асинхронный отчет через изолят.
- Обработка ошибок ввода, поиска, хранения и логирования.
