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

-- Сессия 2
BEGIN;

-- Блокируем и обновляем заказ с id = 2
UPDATE orders
SET order_status = 'отменен'
WHERE order_id = 2
RETURNING order_id, customer_name, order_status;

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
