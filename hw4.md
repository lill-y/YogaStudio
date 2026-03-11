## 1. Смоделировать обновление данных и посмотреть на параметры xmin, xmax, ctid, t_infomask
Посмотрим несколько записей в таблице employee:
```sql
SELECT
    ctid,
    xmin::text,
    xmax::text,
    order_id,
    customer_name,
    order_status
FROM orders
LIMIT 3;
```
<img width="908" height="190" alt="telegram-cloud-photo-size-2-5217763637303384730-y" src="https://github.com/user-attachments/assets/64531900-84ad-4888-9ab5-3f87cc48311b" />

Обновляем сотрудника и возвращаем системные поля:
```sql
UPDATE orders
SET order_status = 'завершен'
WHERE order_id = 1
RETURNING
    ctid,
    xmin::text,
    xmax::text,
    order_id,
    customer_name,
    order_status;
```
<img width="926" height="180" alt="telegram-cloud-photo-size-2-5217763637303384731-y" src="https://github.com/user-attachments/assets/83b5d9ae-6d5f-49c2-87e2-42e7b6459a81" />


Смотрим на t_infomask через pageinspect:
```sql
CREATE EXTENSION IF NOT EXISTS pageinspect;

-- Находим физическое расположение обновленной строки
SELECT ctid
FROM orders
WHERE order_id = 1;

SELECT
    lp,
    t_infomask::integer,
    to_hex(t_infomask) AS t_infomask_hex
FROM heap_page_items(get_raw_page('orders', 0))
WHERE lp = 1; 
```

<img width="518" height="124" alt="telegram-cloud-photo-size-2-5217763637303384732-x" src="https://github.com/user-attachments/assets/05b32778-a423-415d-bf8e-15b9df8ecc79" />

### Вывод:
После обновления записи PostgreSQL создал новую версию строки.

Изменения системных полей:

- ctid изменился, потому что строка физически переместилась
- xmin стал содержать ID новой транзакции
- xmax = 0, так как новая версия строки является актуальной

Поле t_infomask содержит набор битовых флагов, описывающих состояние кортежа.


## 2. Понять что хранится в t_infomask
**t_infomask** — специальная битовая маска в заголовке строки PostgreSQL.

Она используется системой MVCC для хранения информации о состоянии версии строки.

В t_infomask могут храниться флаги:

- наличие NULL-полей
- наличие полей переменной длины
- статус блокировки строки
- признаки удаления или обновления строки
- информация о видимости версии строки

Например:

- HEAP_HASNULL — строка содержит NULL
- HEAP_HASVARWIDTH — есть поля переменной длины
- HEAP_XMIN_COMMITTED — транзакция создания подтверждена
- HEAP_XMAX_INVALID — строка не удалена

## 3. Посмотреть на параметры из п1 в разных транзакциях
3.1. Чтение во время незавершённого обновления
``` sql
-- Сессия 1
BEGIN;

SELECT txid_current() AS transaction_id_1;

UPDATE orders
SET order_status = 'возврат'
WHERE order_id = 3
RETURNING
    order_id,
    customer_name,
    order_status,
    ctid,
    xmin::text,
    xmax::text;
```
<img width="908" height="270" alt="telegram-cloud-photo-size-2-5217763637303384735-y" src="https://github.com/user-attachments/assets/b3637e0f-c15c-4296-955f-48fb2159629b" />

``` sql
-- Сессия 2
BEGIN;

SELECT
    order_id,
    customer_name,
    order_status,
    ctid,
    xmin::text,
    xmax::text
FROM orders
WHERE order_id = 3;
```
<img width="926" height="128" alt="telegram-cloud-photo-size-2-5217763637303384736-y" src="https://github.com/user-attachments/assets/18c7c767-6785-4aea-a931-e1aa073ed03c" />

``` sql
-- Сессия 1
COMMIT;

-- Сессия 2
-- Снова читаем того же сотрудника 
SELECT
    order_id,
    customer_name,
    order_status,
    ctid,
    xmin::text,
    xmax::text
FROM orders
WHERE order_id = 3;

COMMIT;
```
<img width="896" height="132" alt="telegram-cloud-photo-size-2-5217763637303384738-y" src="https://github.com/user-attachments/assets/b17769e4-1de5-443e-99c5-7ce4b518d5ac" />

Вывод

Пока первая транзакция не завершилась:

вторая сессия видела старую версию строки
старая версия содержала xmax, равный ID активной транзакции

После COMMIT:

- стала доступна новая версия строки
- изменился ctid
- обновился xmin
- xmax снова стал равен 0

Это демонстрирует механизм MVCC: PostgreSQL хранит несколько версий одной строки одновременно.

## 4. Смоделировать дедлок, описать результаты
```sql
-- Сессия 1
BEGIN;

UPDATE orders
SET order_status = 'проверка'
WHERE order_id = 1
RETURNING order_id, customer_name, order_status;
```
<img width="301" height="89" alt="image" src="https://github.com/user-attachments/assets/22363805-c8c7-4bf1-9e9f-475bef43a3be" />
``` sql
-- Сессия 2
BEGIN;

-- Блокируем и обновляем заказ с id = 2
UPDATE orders
SET order_status = 'отменен'
WHERE order_id = 2
RETURNING order_id, customer_name, order_status;
```
<img width="350" height="101" alt="image" src="https://github.com/user-attachments/assets/2f31a5ed-e00c-4520-a0cf-3ec26c3bc786" />
```sql
-- Сессия 1
-- Пытаемся обновить заказ с id = 2 (который заблокирован сессией 2)
UPDATE orders
SET order_status = 'архив'
WHERE order_id = 2
RETURNING order_id, customer_name, order_status;

-- Сессия 2
-- Пытаемся обновить заказ с id = 1 (который заблокирован сессией 1)
UPDATE orders
SET order_status = 'обработка'
WHERE order_id = 1
RETURNING order_id, customer_name, order_status;
```
<img width="543" height="92" alt="image" src="https://github.com/user-attachments/assets/da1e5bf6-fcbf-401e-a7f7-310c439d1fa3" />
Результат

Возникает deadlock:

первая транзакция ожидает строку, удерживаемую второй
вторая ожидает строку, удерживаемую первой

PostgreSQL автоматически обнаруживает цикл ожидания и завершает одну из транзакций ошибкой:

ERROR: deadlock detected
Как MVCC связан с дедлоком

При обновлении строки PostgreSQL:

создает новую версию строки
помечает старую через xmax
устанавливает блокировку на запись

Если две транзакции удерживают блокировки и одновременно ждут друг друга, появляется взаимоблокировка.
