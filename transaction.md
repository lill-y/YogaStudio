## Базовые операции с транзакциями
1.  READ UNCOMMITTED / READ COMMITTED
   Запрос 1: Добавление клиента и платежа
```sql
BEGIN;

INSERT INTO Client (ClientID, FirstName, LastName, Phone, DateOfBirth, YogaStudioID) 
VALUES (15, 'Дарья', 'Ковалева', '+79997776655', '1993-09-12', 1);

INSERT INTO Membership (MembershipID, ClientID, Type, StartDate, EndDate, Status)
VALUES (15, 15, 'Безлимитный', '2024-11-20', '2024-12-20', 'active');

COMMIT;
```
  Запрос 2: Обновление клиента и создание отзыва
```sql
BEGIN;
UPDATE Client SET Phone = '+79997654321' WHERE ClientID = 1;
INSERT INTO Review (ReviewID, ClientID, Rating, Comment)
VALUES (25, 1, 5, 'Отличный сервис после обновления!');
COMMIT;
```

2. Транзакция с ROLLBACK
```sql
BEGIN;

INSERT INTO Client (ClientID, FirstName, LastName, Phone, DateOfBirth, YogaStudioID) 
VALUES (15, 'Дарья', 'Ковалева', '+79997776655', '1993-09-12', 1);

INSERT INTO Membership (MembershipID, ClientID, Type, StartDate, EndDate, Status)
VALUES (15, 15, 'Безлимитный', '2024-11-20', '2024-12-20', 'active');

ROLLBACK;

-- Проверяем, что клиент удален после ROLLBACK
SELECT * FROM Client WHERE ClientID = 16;
```

```sql
BEGIN;
UPDATE Client SET Phone = '+79997654321' WHERE ClientID = 1;
INSERT INTO Review (ReviewID, ClientID, Rating, Comment)
VALUES (25, 1, 5, 'Отличный сервис после обновления!');
ROLLBACK;

-- Проверяем, что изменения удалены после ROLLBACK
SELECT FirstName FROM Client WHERE ClientID = 2;
```

3. Транзакция с ошибкой
Запрос 1: Ошибка деления на ноль

```sql
BEGIN;
INSERT INTO Client (ClientID, FirstName, LastName, YogaStudioID) 
VALUES (27, 'Ошибка', 'Тест', 1);
SELECT 1/0;
INSERT INTO Review (ReviewID, ClientID, Rating) VALUES (27, 27, 5);
COMMIT;

SELECT * FROM Client WHERE ClientID = 27; 
```

Запрос 2: Ошибка нарушения ограничения

```sql
BEGIN;
INSERT INTO Review (ReviewID, ClientID, Rating) VALUES (28, 1, 10); -- Rating > 5
INSERT INTO Client (ClientID, FirstName, LastName, YogaStudioID) 
VALUES (28, 'После', 'Ошибки', 1);
COMMIT;
SELECT * FROM Client WHERE ClientID = 28;
```

## Уровни изоляции
4. READ UNCOMMITTED / READ COMMITTED
   
Запрос 1: Проверка грязного чтения в READ COMMITTED

```sql
BEGIN;
UPDATE Client SET LastName = 'НЕЗАКОММИТЕНО' WHERE ClientID = 3;

BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT LastName FROM Client WHERE ClientID = 3; 
COMMIT;

ROLLBACK;

SELECT Phone FROM Client WHERE ClientID = 1;
```

```sql
BEGIN;
UPDATE Membership SET Type = 'ПРЕМИУМ' WHERE MembershipID = 1;

BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT Type FROM Membership WHERE MembershipID = 1;
COMMIT;

ROLLBACK;

SELECT Type FROM Membership WHERE MembershipID = 1;
```

5. READ COMMITTED: Неповторяющееся чтение (2 запроса)
Запрос 1: Демонстрация неповторяющегося чтения

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT Phone FROM Client WHERE ClientID = 1;

BEGIN;
UPDATE Client SET Phone = '+79990000001' WHERE ClientID = 1;
COMMIT; 

SELECT Phone FROM Client WHERE ClientID = 1; 
COMMIT;
```
Запрос 2: Изменение данных между чтениями

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT Amount FROM Payment WHERE PaymentID = 1;

BEGIN;
UPDATE Payment SET Amount = Amount + 1000 WHERE PaymentID = 1;
COMMIT;

SELECT Amount FROM Payment WHERE PaymentID = 1;
COMMIT;
```

6. REPEATABLE READ (2 запроса)
Запрос 1: Защита от неповторяющегося чтения

```sql
-- Сессия 1
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT FirstName FROM Client WHERE ClientID = 2;
-- Пауза
SELECT FirstName FROM Client WHERE ClientID = 2; -- То же значение
COMMIT;

-- Сессия 2
BEGIN;
UPDATE Client SET FirstName = 'ИЗМЕНЕНО' WHERE ClientID = 2;
COMMIT;
```
Запрос 2: Снимок данных на начало транзакции

```sql
-- Сессия 1
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT COUNT(*) FROM Client WHERE YogaStudioID = 1;

BEGIN;
INSERT INTO Client (ClientID, FirstName, LastName, YogaStudioID) 
VALUES (29, 'Новый', 'Клиент', 1);
COMMIT;

SELECT COUNT(*) FROM Client WHERE YogaStudioID = 1; -- То же количество
COMMIT;
```
7. SERIALIZABLE (2 запроса)
Запрос 1: Конфликт сериализации при вставке

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
INSERT INTO Review (ReviewID, ClientID, Rating, Comment)
VALUES (30, 1, 5, 'Комментарий 1');

BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
INSERT INTO Review (ReviewID, ClientID, Rating, Comment)
VALUES (31, 1, 4, 'Комментарий 2');
COMMIT;

COMMIT;
```

Запрос 2: Конфликт при обновлении одних данных
```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE Payment SET Amount = Amount + 500 WHERE PaymentID = 1;

BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE Payment SET Amount = Amount + 1000 WHERE PaymentID = 1;
COMMIT;

COMMIT;
```
8. SAVEPOINT 
Запрос 1: Базовое использование SAVEPOINT

```sql
BEGIN;
INSERT INTO Client (ClientID, FirstName, LastName, YogaStudioID) 
VALUES (30, 'До', 'Точки', 1);
SAVEPOINT my_savepoint;
INSERT INTO Client (ClientID, FirstName, LastName, YogaStudioID) 
VALUES (31, 'После', 'Точки', 2);
SELECT COUNT(*) FROM Client WHERE ClientID IN (30, 31);
ROLLBACK TO my_savepoint;
SELECT COUNT(*) FROM Client WHERE ClientID IN (30, 31); 
COMMIT;
```
Запрос 2: Множественные SAVEPOINT

```sql
BEGIN;
SAVEPOINT sp1;
UPDATE Client SET FirstName = 'ШАГ1' WHERE ClientID = 1;
SAVEPOINT sp2;
UPDATE Client SET FirstName = 'ШАГ2' WHERE ClientID = 2;
SAVEPOINT sp3;
UPDATE Client SET FirstName = 'ШАГ3' WHERE ClientID = 3;
SELECT FirstName FROM Client WHERE ClientID IN (1,2,3);
ROLLBACK TO sp2;
SELECT FirstName FROM Client WHERE ClientID IN (1,2,3); -- Откат к sp2
ROLLBACK TO sp1;
SELECT FirstName FROM Client WHERE ClientID IN (1,2,3); -- Откат к sp1
COMMIT;
```
