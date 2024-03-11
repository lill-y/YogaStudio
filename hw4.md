### 1.1 Создадим тестовую таблицу и данные
sql
-- Подключаемся к базе
docker exec -it pg_demo psql -U demo -d demo

-- Создаем тестовую таблицу
CREATE TABLE test_tx (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    value INT
);

-- Добавляем данные
INSERT INTO test_tx (name, value) VALUES 
    ('First', 100),
    ('Second', 200),
    ('Third', 300);

-- Посмотрим системные столбцы
SELECT 
    ctid,           -- физическое расположение строки
    xmin,           -- ID транзакции, которая создала строку
    xmax,           -- ID транзакции, которая удалила/обновила строку
    id, name, value
FROM test_tx;
### 1.2 Просмотр t_infomask через расширение
sql
-- Устанавливаем расширение для просмотра t_infomask
CREATE EXTENSION IF NOT EXISTS pageinspect;

-- Посмотрим информацию о страницах
SELECT * FROM heap_page_items(get_raw_page('test_tx', 0));

-- Более детально с t_infomask
SELECT 
    lp as tuple_id,
    lp_off as offset,
    lp_len as length,
    t_xmin,
    t_xmax,
    t_infomask,
    t_infomask2
FROM heap_page_items(get_raw_page('test_tx', 0));
### 1.3 Что хранится в t_infomask
sql
-- Флаги t_infomask (битовые маски)
-- Бит | Значение
-- 0x0001 | HEAP_HASNULL - есть NULL значения
-- 0x0002 | HEAP_HASVARWIDTH - есть поля переменной длины
-- 0x0004 | HEAP_HASEXTERNAL - есть TOAST данные
-- 0x0008 | HEAP_HASOID - есть OID
-- 0x0010 | HEAP_XMAX_KEYSHR_LOCK - XMAX является ключевым шар-локом
-- 0x0020 | HEAP_COMBOCID - используется combo CID
-- 0x0040 | HEAP_XMAX_EXCL_LOCK - XMAX является эксклюзивной блокировкой
-- 0x0080 | HEAP_XMAX_SHARED_LOCK - XMAX является разделяемой блокировкой
-- 0x0100 | HEAP_XMIN_COMMITTED - xmin подтверждена
-- 0x0200 | HEAP_XMIN_INVALID - xmin недействительна
-- 0x0400 | HEAP_XMAX_COMMITTED - xmax подтверждена
-- 0x0800 | HEAP_XMAX_INVALID - xmax недействительна
-- 0x1000 | HEAP_UPDATED - строка обновлена
-- 0x2000 | HEAP_MOVED_OFF - строка перемещена (для VACUUM FULL)
-- 0x4000 | HEAP_MOVED_IN - строка перемещена (для VACUUM FULL)
-- 0x8000 | HEAP_HOT_UPDATED - HOT обновление
1.4 Изменение данных и наблюдение за xmin/xmax
sql
-- Начнем транзакцию и посмотрим на xmin
BEGIN;
INSERT INTO test_tx (name, value) VALUES ('New Row', 500);

-- Посмотрим xmin текущей транзакции
SELECT 
    ctid, xmin, xmax, 
    txid_current() as current_txid,
    name, value
FROM test_tx 
WHERE name = 'New Row';

-- COMMIT транзакции
COMMIT;

-- После COMMIT снова посмотрим
SELECT 
    ctid, xmin, xmax, 
    name, value
FROM test_tx 
WHERE name = 'New Row';
1.5 Наблюдение за xmax при UPDATE
sql
-- Сначала посмотрим текущее состояние
SELECT ctid, xmin, xmax, id, name, value FROM test_tx WHERE id = 1;

-- Обновляем строку
UPDATE test_tx SET value = 150 WHERE id = 1;

-- Посмотрим, что произошло с xmax
SELECT ctid, xmin, xmax, id, name, value FROM test_tx WHERE id = 1;

-- Старая версия строки (xmax заполнен)
SELECT ctid, xmin, xmax, id, name, value 
FROM test_tx 
WHERE ctid = '(0,1)'::tid;  -- старый ctid может быть другим
1.6 Наблюдение за xmax при DELETE
sql
-- Создаем строку для удаления
INSERT INTO test_tx (name, value) VALUES ('To Delete', 999);

-- Посмотрим перед удалением
SELECT ctid, xmin, xmax, name, value FROM test_tx WHERE name = 'To Delete';

-- Удаляем
DELETE FROM test_tx WHERE name = 'To Delete';

-- Строка физически не удалена, xmax установлен
SELECT ctid, xmin, xmax, name, value FROM test_tx WHERE name = 'To Delete';
1.7 Параметры в разных транзакциях
Сессия 1:

sql
BEGIN;
UPDATE test_tx SET value = 999 WHERE id = 1;
-- не COMMIT
SELECT txid_current(), pg_backend_pid();
Сессия 2:

sql
-- Посмотрим xmax из другой сессии
SELECT ctid, xmin, xmax, id, value FROM test_tx WHERE id = 1;
Сессия 1:

sql
COMMIT;
Сессия 2:

sql
SELECT ctid, xmin, xmax, id, value FROM test_tx WHERE id = 1;
Часть 2: Дедлоки
2.1 Смоделируем дедлок
Сессия 1:

sql
-- Начинаем транзакцию
BEGIN;

-- Блокируем строку id=1
UPDATE test_tx SET value = 10 WHERE id = 1;

-- Не COMMIT, ждем
Сессия 2:

sql
-- Начинаем другую транзакцию
BEGIN;

-- Блокируем строку id=2
UPDATE test_tx SET value = 20 WHERE id = 2;

-- Не COMMIT
Сессия 1:

sql
-- Пытаемся обновить строку, которую заблокировала сессия 2
UPDATE test_tx SET value = 11 WHERE id = 2;
-- Зависает в ожидании
Сессия 2:

sql
-- Пытаемся обновить строку, которую заблокировала сессия 1
UPDATE test_tx SET value = 21 WHERE id = 1;
-- Произойдет дедлок!
Результат:

text
ERROR:  deadlock detected
DETAIL:  Process 1234 waits for ShareLock on transaction 5678; blocked by process 5678.
Process 5678 waits for ShareLock on transaction 1234; blocked by process 1234.
HINT:  See server log for query details.
Очистка:

sql
-- В сессии 1
ROLLBACK;

-- В сессии 2
ROLLBACK;
2.2 Просмотр информации о блокировках
sql
-- В любой момент можно посмотреть активные блокировки
SELECT 
    locktype,
    relation::regclass,
    transactionid,
    mode,
    granted,
    pid,
    query
FROM pg_locks
LEFT JOIN pg_stat_activity ON pg_locks.pid = pg_stat_activity.pid
WHERE NOT granted;
Часть 3: Явные блокировки
3.1 Блокировки на уровне таблицы
sql
-- Создаем тестовую таблицу
CREATE TABLE lock_test (
    id SERIAL PRIMARY KEY,
    data TEXT
);

INSERT INTO lock_test (data) SELECT 'data' || i FROM generate_series(1, 100) i;

-- ACCESS SHARE - автоматически при SELECT
BEGIN;
SELECT * FROM lock_test WHERE id = 1;
SELECT locktype, relation::regclass, mode, granted FROM pg_locks WHERE relation = 'lock_test'::regclass;
COMMIT;

-- ROW SHARE - при SELECT FOR UPDATE
BEGIN;
SELECT * FROM lock_test WHERE id = 1 FOR UPDATE;
SELECT locktype, relation::regclass, mode, granted FROM pg_locks WHERE relation = 'lock_test'::regclass;
COMMIT;

-- ACCESS EXCLUSIVE - при ALTER TABLE
BEGIN;
ALTER TABLE lock_test ADD COLUMN new_col TEXT;
SELECT locktype, relation::regclass, mode, granted FROM pg_locks WHERE relation = 'lock_test'::regclass;
COMMIT;
3.2 Явная блокировка таблицы
sql
-- LOCK TABLE вручную
BEGIN;
LOCK TABLE lock_test IN SHARE MODE;
SELECT locktype, relation::regclass, mode, granted FROM pg_locks WHERE relation = 'lock_test'::regclass;
COMMIT;

-- Конфликт блокировок
-- Сессия 1:
BEGIN;
LOCK TABLE lock_test IN ACCESS EXCLUSIVE MODE;
-- не COMMIT

-- Сессия 2:
BEGIN;
SELECT * FROM lock_test LIMIT 1; -- зависнет в ожидании
Часть 4: Блокировки на уровне строк
4.1 Различные режимы блокировок строк
sql
-- Очистим таблицу
TRUNCATE lock_test;
INSERT INTO lock_test (data) SELECT 'row_' || i FROM generate_series(1, 10) i;

-- Сессия 1: FOR UPDATE (эксклюзивная блокировка)
BEGIN;
SELECT * FROM lock_test WHERE id = 1 FOR UPDATE;
SELECT locktype, relation::regclass, mode, granted FROM pg_locks WHERE relation = 'lock_test'::regclass;
-- не COMMIT
Сессия 2:

sql
-- Попытка FOR UPDATE (конфликт)
BEGIN;
SELECT * FROM lock_test WHERE id = 1 FOR UPDATE;
-- зависнет

-- Попытка FOR SHARE (тоже конфликт)
BEGIN;
SELECT * FROM lock_test WHERE id = 1 FOR SHARE;
-- зависнет

-- Простой SELECT (работает)
BEGIN;
SELECT * FROM lock_test WHERE id = 1;
-- работает
COMMIT;
4.2 FOR UPDATE vs FOR SHARE
Сессия 1:

sql
BEGIN;
SELECT * FROM lock_test WHERE id = 2 FOR SHARE;
-- не COMMIT
Сессия 2:

sql
-- FOR SHARE (совместимо)
BEGIN;
SELECT * FROM lock_test WHERE id = 2 FOR SHARE;
-- работает, не блокирует
COMMIT;

-- FOR UPDATE (не совместимо)
BEGIN;
SELECT * FROM lock_test WHERE id = 2 FOR UPDATE;
-- зависнет
4.3 Просмотр конфликтов строк
sql
-- Создаем представление для просмотра блокировок
CREATE VIEW locks_view AS
SELECT 
    l.pid,
    l.locktype,
    l.mode,
    l.granted,
    l.relation::regclass as table_name,
    a.query,
    a.state,
    a.wait_event_type,
    a.wait_event
FROM pg_locks l
LEFT JOIN pg_stat_activity a ON l.pid = a.pid
WHERE l.relation IS NOT NULL
ORDER BY l.pid, l.granted DESC;

-- Смотрим активные блокировки
SELECT * FROM locks_view;
4.4 SKIP LOCKED
sql
-- Добавляем много строк
TRUNCATE lock_test;
INSERT INTO lock_test (data) SELECT 'row_' || i FROM generate_series(1, 100) i;

-- Сессия 1: блокируем несколько строк
BEGIN;
SELECT * FROM lock_test WHERE id IN (1,2,3) FOR UPDATE;
-- не COMMIT
Сессия 2:

sql
-- Обычный FOR UPDATE - ждет
BEGIN;
SELECT * FROM lock_test WHERE id < 10 FOR UPDATE;
-- ждет строки 1,2,3

-- SKIP LOCKED - пропускает заблокированные
BEGIN;
SELECT * FROM lock_test WHERE id < 10 FOR UPDATE SKIP LOCKED;
-- получает строки 4,5,6,7,8,9
COMMIT;
Часть 5: Очистка данных (VACUUM)
5.1 Просмотр мертвых строк
sql
-- Статистика по таблице
SELECT 
    relname,
    n_live_tup as live_rows,
    n_dead_tup as dead_rows,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE relname = 'test_tx';

-- После множества UPDATE/DELETE
UPDATE test_tx SET value = value + 1 WHERE id < 1000;
DELETE FROM test_tx WHERE id > 500;

-- Снова смотрим
SELECT 
    relname,
    n_live_tup,
    n_dead_tup
FROM pg_stat_user_tables
WHERE relname = 'test_tx';
5.2 Ручной VACUUM
sql
-- VACUUM (не освобождает место ОС, только помечает как свободное)
VACUUM test_tx;

-- Снова статистика
SELECT relname, n_live_tup, n_dead_tup
FROM pg_stat_user_tables
WHERE relname = 'test_tx';

-- VACUUM FULL (освобождает место, но блокирует таблицу)
VACUUM FULL test_tx;

-- ANALYZE (обновляет статистику для планировщика)
ANALYZE test_tx;
5.3 Очистка после всех экспериментов
sql
-- Удаляем тестовые таблицы
DROP TABLE IF EXISTS test_tx CASCADE;
DROP TABLE IF EXISTS lock_test CASCADE;
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS documents CASCADE;
DROP TABLE IF EXISTS locations CASCADE;

-- Вакуум всей базы
VACUUM FULL ANALYZE;

-- Проверяем размер
SELECT pg_database_size(current_database()) / 1024 / 1024 || ' MB' as db_size;

