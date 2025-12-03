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
Результат: Обе записи успешно добавлены в базу данных. Транзакция завершена успешно.
<img width="684" height="99" alt="image" src="https://github.com/user-attachments/assets/e99065ec-7a23-4639-8bbe-ebe2fd203982" />
<img width="694" height="92" alt="image" src="https://github.com/user-attachments/assets/ed4d13cf-a3cb-4fed-82b4-aa0d49bf8942" />

  Запрос 2: Обновление клиента и создание отзыва
```sql
BEGIN;
UPDATE Client SET Phone = '+79997654321' WHERE ClientID = 1;
INSERT INTO Review (ReviewID, ClientID, Rating, Comment)
VALUES (25, 1, 5, 'Отличный сервис после обновления!');
COMMIT;
```
Результат: Обе записи успешно обновлены в базе данных. Транзакция завершена успешно.
<img width="592" height="87" alt="image" src="https://github.com/user-attachments/assets/ca713f3b-5638-411e-a2f1-b5877339524c" />

2. Транзакция с ROLLBACK
```sql
BEGIN;

INSERT INTO Client (ClientID, FirstName, LastName, Phone, DateOfBirth, YogaStudioID) 
VALUES (16, 'Дарья', 'Ковалева', '+79997776655', '1993-09-12', 1);

INSERT INTO Membership (MembershipID, ClientID, Type, StartDate, EndDate, Status)
VALUES (16, 16, 'Безлимитный', '2024-11-20', '2024-12-20', 'active');

ROLLBACK;
```
После ROLLBACK запись с ClientID = 16 отсутствует в базе данных. Все изменения откачены.
<img width="627" height="78" alt="image" src="https://github.com/user-attachments/assets/9298583e-1599-44c2-b31b-2426bf1eab3f" />
<img width="773" height="55" alt="image" src="https://github.com/user-attachments/assets/24a4cc37-c5c6-44b5-8a89-d9c50e594403" />

```sql
BEGIN;
UPDATE Client SET Phone = '+78888888888' WHERE ClientID = 1;
INSERT INTO Review (ReviewID, ClientID, Rating, Comment)
VALUES (25, 1, 5, 'Отличный сервис после обновления!');
ROLLBACK;
```
<img width="592" height="87" alt="image" src="https://github.com/user-attachments/assets/ca713f3b-5638-411e-a2f1-b5877339524c" />
3. Транзакция с ошибкой
Запрос 1: Ошибка деления на ноль

```sql
BEGIN;
INSERT INTO Client (ClientID, FirstName, LastName, YogaStudioID) 
VALUES (27, 'Ошибка', 'Тест', 1);
SELECT 1/0;
INSERT INTO Review (ReviewID, ClientID, Rating) VALUES (27, 27, 5);
COMMIT;
```
Результат: PostgreSQL автоматически откатывает всю транзакцию при возникновении ошибки.
<img width="831" height="45" alt="image" src="https://github.com/user-attachments/assets/c7745018-6c34-412b-9000-c693f41a10e8" />

Запрос 2: Ошибка нарушения ограничения

```sql
BEGIN;
INSERT INTO Review (ReviewID, ClientID, Rating) VALUES (28, 1, 10); -- Rating > 5
INSERT INTO Client (ClientID, FirstName, LastName, YogaStudioID) 
VALUES (28, 'После', 'Ошибки', 1);
COMMIT;
SELECT * FROM Client WHERE ClientID = 28;
```
<img width="522" height="89" alt="image" src="https://github.com/user-attachments/assets/dec6d407-9a39-4315-9d14-1fe5cc755da7" />

## Уровни изоляции
4. READ UNCOMMITTED / READ COMMITTED
   
Запрос 1: Проверка грязного чтения в READ COMMITTED

```sql
BEGIN;
UPDATE Client SET LastName = 'Незакоммитено' WHERE ClientID = 3;

BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT LastName FROM Client WHERE ClientID = 3; 
COMMIT;

ROLLBACK;
```
Результат: В READ COMMITTED режиме вторая транзакция не видит незакоммиченных изменений. Грязное чтение невозможно.
<img width="555" height="95" alt="image" src="https://github.com/user-attachments/assets/ba73bc9a-5792-408f-963a-2a94af8f3c72" />

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
Результат: В READ COMMITTED режиме вторая транзакция не видит незакоммиченных изменений. Грязное чтение невозможно.
<img width="642" height="311" alt="image" src="https://github.com/user-attachments/assets/8b8cd309-a3d1-41a3-afc6-bee40cbfdab6" />

5. READ COMMITTED: Неповторяющееся чтение 
Запрос 1: Демонстрация неповторяющегося чтения

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT Phone FROM Client WHERE ClientID = 1;

BEGIN;
UPDATE Client SET Phone = '+79998888881' WHERE ClientID = 1;
COMMIT; 

SELECT Phone FROM Client WHERE ClientID = 1; 
COMMIT;
```
Результат: Вторая транзакция видит разные значения при повторном чтении. Неповторяющееся чтение присутствует.
<img width="521" height="226" alt="image" src="https://github.com/user-attachments/assets/996d8672-9213-471c-b21f-40db7a3f10b0" />

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
Результат: Вторая транзакция видит разные значения при повторном чтении. Неповторяющееся чтение присутствует.
<img width="545" height="224" alt="image" src="https://github.com/user-attachments/assets/8fdae1a2-1745-45b7-a953-c49eb319564d" />

6. REPEATABLE READ (2 запроса)
Запрос 1: Защита от неповторяющегося чтения

```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT FirstName FROM Client WHERE ClientID = 2;

BEGIN;
UPDATE Client SET FirstName = 'ИЗМЕНЕНО' WHERE ClientID = 2;
COMMIT;

SELECT FirstName FROM Client WHERE ClientID = 2; 
COMMIT;
```
Результат: Первая транзакция видит одинаковые значения при обоих чтениях. Неповторяющееся чтение предотвращено.
<img width="564" height="233" alt="image" src="https://github.com/user-attachments/assets/6c1d82de-e18f-4524-8b8d-fe553da873a7" />

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
Результат: Первая транзакция видит одинаковые значения при обоих чтениях. Неповторяющееся чтение предотвращено.
<img width="675" height="204" alt="image" src="https://github.com/user-attachments/assets/ea4ab1dc-dc79-4039-adf1-6f28e124fe24" />

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
Результат: зависает постргрес, ошибки не выдает
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
Результат: зависает постргрес, ошибки не выдает
<img width="602" height="231" alt="image" src="https://github.com/user-attachments/assets/0c0f3bd6-853e-41ed-b9f0-d54ed6960fb4" />

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
<img width="598" height="481" alt="image" src="https://github.com/user-attachments/assets/ba0a48a0-2b4c-450b-8940-54a99f7019b5" />

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
SELECT FirstName FROM Client WHERE ClientID IN (1,2,3); 
ROLLBACK TO sp1;
SELECT FirstName FROM Client WHERE ClientID IN (1,2,3); 
COMMIT;
```
<img width="598" height="481" alt="image" src="https://github.com/user-attachments/assets/c8d0572f-0f58-4e07-96e3-6b027695f458" />
