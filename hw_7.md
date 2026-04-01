# 7. Секционирование/Шардирование
## 1. Секционирование: RANGE / LIST / HASH. Для каждого типа выбрать запрос и дать ответы:
a. есть ли partition pruning
b. сколько партиций участвует в плане
c. используется ли индекс

### Cоздаем тестовые таблицы с разными типами секционирования:
```
-- 1.1 RANGE-секционирование (по дате регистрации)
DROP TABLE IF EXISTS student_course_range CASCADE;

CREATE TABLE student_course_range (
    enrollment_id INTEGER NOT NULL,
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    teacher_id INTEGER NOT NULL,
    enroll_date DATE NOT NULL,
    progress_percent INTEGER DEFAULT 0,
    course_status VARCHAR(30) NOT NULL,
    payment_amount INTEGER DEFAULT 0,
    comment TEXT,
    PRIMARY KEY (enrollment_id, enroll_date)
) PARTITION BY RANGE (enroll_date);

-- Создаем диапазонные секции
CREATE TABLE student_course_2026_01 PARTITION OF student_course_range
FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE student_course_2026_02 PARTITION OF student_course_range
FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

CREATE TABLE student_course_2026_03 PARTITION OF student_course_range
FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE TABLE student_course_future PARTITION OF student_course_range
FOR VALUES FROM ('2026-04-01') TO (MAXVALUE);

-- Добавляем тестовые данные
INSERT INTO student_course_range VALUES
(1, 101, 501, 11, '2026-01-10', 20, 'активен', 1200, 'first'),
(2, 102, 502, 12, '2026-01-25', 45, 'активен', 1500, 'second'),
(3, 103, 503, 13, '2026-02-15', 70, 'завершен', 1800, 'third'),
(4, 104, 504, 14, '2026-03-05', 10, 'новый', 900, 'fourth');

-- Создаем индексы на секционированной таблице 
CREATE INDEX idx_student_course_range_date
ON student_course_range(enroll_date);

CREATE INDEX idx_student_course_range_student
ON student_course_range(student_id);


-- 1.2 Секционирование по LIST (по статусу заказа)
LIST-секционирование (по статусу курса)
DROP TABLE IF EXISTS student_course_list CASCADE;

CREATE TABLE student_course_list (
    enrollment_id INTEGER NOT NULL,
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    teacher_id INTEGER NOT NULL,
    enroll_date DATE NOT NULL,
    progress_percent INTEGER,
    course_status VARCHAR(30) NOT NULL,
    payment_amount INTEGER,
    comment TEXT,
    PRIMARY KEY (enrollment_id, course_status)
) PARTITION BY LIST (course_status);

-- Создаем LIST-секции
CREATE TABLE student_course_active PARTITION OF student_course_list
FOR VALUES IN ('активен');

CREATE TABLE student_course_finished PARTITION OF student_course_list
FOR VALUES IN ('завершен');

CREATE TABLE student_course_new PARTITION OF student_course_list
FOR VALUES IN ('новый');

CREATE TABLE student_course_cancelled PARTITION OF student_course_list
FOR VALUES IN ('отменен');

-- Заполняем данными
INSERT INTO student_course_list
SELECT *
FROM student_course_range;

-- Создаем индексы
CREATE INDEX idx_student_course_list_status
ON student_course_list(course_status);

CREATE INDEX idx_student_course_list_student
ON student_course_list(student_id);


-- 1.3 HASH-секционирование (по student_id)
DROP TABLE IF EXISTS student_course_hash CASCADE;

CREATE TABLE student_course_hash (
    enrollment_id INTEGER NOT NULL,
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    teacher_id INTEGER NOT NULL,
    enroll_date DATE NOT NULL,
    progress_percent INTEGER,
    course_status VARCHAR(30),
    payment_amount INTEGER,
    comment TEXT,
    PRIMARY KEY (enrollment_id, student_id)
) PARTITION BY HASH (student_id);

-- Создаем 4 хеш-секции
CREATE TABLE student_course_hash_0 PARTITION OF student_course_hash
FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE student_course_hash_1 PARTITION OF student_course_hash
FOR VALUES WITH (MODULUS 4, REMAINDER 1);

CREATE TABLE student_course_hash_2 PARTITION OF student_course_hash
FOR VALUES WITH (MODULUS 4, REMAINDER 2);

CREATE TABLE student_course_hash_3 PARTITION OF student_course_hash
FOR VALUES WITH (MODULUS 4, REMAINDER 3);

-- Добавляем данные
INSERT INTO student_course_hash
SELECT *
FROM student_course_range;

-- Создаем индексы
CREATE INDEX idx_student_course_hash_student
ON student_course_hash(student_id);

CREATE INDEX idx_student_course_hash_date
ON student_course_hash(enroll_date);```
### Анализ запросов:
```
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM student_course_range
WHERE enroll_date BETWEEN '2026-01-15' AND '2026-02-20';
```





a. partition pruning есть
b. 2 партиции 
Участвующие секции:
- student_course_2026_01 (диапазон: 2026-01-01 до 2026-02-01)
- student_course_2026_02 (диапазон: 2026-02-01 до 2026-03-01)
c. Индекс не используется, вместо Index Scan используется Seq Scan.


```
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM student_course_list
WHERE course_status = 'завершен';
```





a. partition pruning есть
b. 1 партиция
Участвующая секция:
- student_course_finished (хранит заказы со статусом 'выполнен')
c. Индекс НЕ используется. Выполняется Seq Scan on client_order_completed.


```
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM student_course_hash
WHERE student_id = 103;
```






a. partition pruning есть
b. 1 партиция
Участвующая секция:
- student_course_hash_3 (где MODULUS 4, REMAINDER 0)
c. Индекс ИСПОЛЬЗУЕТСЯ
- Bitmap Index Scan  — используется индекс
- Bitmap Heap Scan — чтение таблицы по битовой карте от индекса

## 2. Секционирование и физическая репликация
### Создаем тестовую секционированную таблицу на мастере:
```
CREATE TABLE lesson_archive (
    lesson_id SERIAL,
    lesson_date DATE,
    lesson_topic TEXT
) PARTITION BY RANGE (lesson_date);

-- Создаем секцию
CREATE TABLE lesson_archive_2026_01
PARTITION OF lesson_archive
FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

-- Добавляем данные
INSERT INTO lesson_archive (lesson_date, lesson_topic)
VALUES ('2026-01-12', 'PostgreSQL MVCC');
```

### Проверяем, что секционирование есть на репликах:

```
SELECT *
FROM pg_class
WHERE relname LIKE 'lesson_archive%';
```




Вывод

На физической реплике секционированная структура полностью сохраняется:

- родительская таблица
- дочерние секции
- метаданные PostgreSQL

Это происходит потому, что физическая репликация копирует WAL-записи поблочно.

## 3. Логическая репликация и секционирование publish_via_partition_root = on / off
### Создаем тестовые таблицы на мастере:
```
CREATE TABLE webinar_partition (
    webinar_id SERIAL,
    webinar_date DATE NOT NULL,
    webinar_topic TEXT,
    city VARCHAR(50),
    PRIMARY KEY (webinar_id, webinar_date)
) PARTITION BY RANGE (webinar_date);


-- Создаем секции по месяцам
CREATE TABLE webinar_2026_01 PARTITION OF webinar_partition
FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE webinar_2026_02 PARTITION OF webinar_partition
FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

CREATE TABLE webinar_default PARTITION OF webinar_partition DEFAULT;


-- Добавляем немного данных
INSERT INTO test_partition_root (created_date, data, region) VALUES
  ('2026-01-15', 'Data for January', 'Moscow'),
  ('2026-01-20', 'Another January data', 'SPB'),
  ('2026-02-10', 'February data', 'Kazan'),
  ('2026-02-25', 'Another February', 'Moscow'),
  ('2026-03-05', 'March data', 'Novosibirsk');

-- Проверяем, что данные распределились по секциям
SELECT '2026_01' as partition, COUNT(*) FROM test_partition_2026_01
UNION ALL
SELECT '2026_02', COUNT(*) FROM test_partition_2026_02
UNION ALL
SELECT '2026_03', COUNT(*) FROM test_partition_2026_03
UNION ALL
SELECT 'DEFAULT', COUNT(*) FROM test_partition_default;
```


###  publish_via_partition_root = false (по умолчанию)
```
-- Создаем публикацию с явным указанием false
DROP PUBLICATION IF EXISTS webinar_pub_off;

CREATE PUBLICATION webinar_pub_off
FOR TABLE webinar_partition
WITH (publish_via_partition_root = false);

-- Проверяем публикацию
SELECT 
  p.pubname,
  pt.schemaname,
  pt.tablename
FROM pg_publication p
JOIN pg_publication_tables pt ON p.pubname = pt.pubname;
```




###  publish_via_partition_root = true (по умолчанию)
```
-- Создаем публикацию с параметром true
DROP PUBLICATION IF EXISTS webinar_pub_on;

CREATE PUBLICATION webinar_pub_on
FOR TABLE webinar_partition
WITH (publish_via_partition_root = true);

-- Смотрим список публикаций
SELECT pubname, puballtables FROM pg_publication;
```







## 4. Шардирование через postgres_fdw
### Настройка 2 шардов и 1 роутера
```
-- Создаем два шарда
CREATE SCHEMA edu_shard1;
CREATE SCHEMA edu_shard2;
Таблица первого шарда
CREATE TABLE edu_shard1.student_payments (
    id SERIAL PRIMARY KEY,
    student_id INTEGER,
    payment_data TEXT,
    shard_key INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount INTEGER
);

-- Таблица второго шарда
CREATE TABLE edu_shard2.student_payments (
    id SERIAL PRIMARY KEY,
    student_id INTEGER,
    payment_data TEXT,
    shard_key INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount INTEGER
);

-- Подключаем postgres_fdw
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Создаем FDW-серверы
CREATE SERVER edu_shard1_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'education-postgres', port '5432', dbname 'education');
CREATE SERVER edu_shard2_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'education-postgres', port '5432', dbname 'education');
```


``` sql
-- Внешние таблицы
CREATE FOREIGN TABLE fdw_student_payments_1 (
    id INTEGER,
    student_id INTEGER,
    payment_data TEXT,
    shard_key INTEGER,
    created_at TIMESTAMP,
    amount INTEGER
)

SERVER edu_shard1_server
OPTIONS (schema_name 'edu_shard1', table_name 'student_payments');
CREATE FOREIGN TABLE fdw_student_payments_2 (
    id INTEGER,
    student_id INTEGER,
    payment_data TEXT,
    shard_key INTEGER,
    created_at TIMESTAMP,
    amount INTEGER
)

SERVER edu_shard2_server
OPTIONS (schema_name 'edu_shard2', table_name 'student_payments');

-- Таблица-роутер
CREATE TABLE payment_router (
    id INTEGER,
    student_id INTEGER,
    payment_data TEXT,
    shard_key INTEGER,
    created_at TIMESTAMP,
    amount INTEGER
) PARTITION BY LIST (shard_key);


-- Подключаем шарды
ALTER TABLE payment_router
ATTACH PARTITION fdw_student_payments_1
FOR VALUES IN (0, 1);

ALTER TABLE payment_router
ATTACH PARTITION fdw_student_payments_2
FOR VALUES IN (2, 3);
```

# Анализ запросов
## Запрос ко всем шардам
``` sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*), SUM(amount)
FROM payment_router;
```

## Результат

Сканируются оба шарда.

## Запрос к одному шарду
``` sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*), SUM(amount)
FROM payment_router
WHERE shard_key = 0;
```
## Результат

Работает только один шард благодаря partition pruning.

##Запрос к нескольким шардам
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*), SUM(amount)
FROM payment_router
WHERE shard_key IN (1, 2);
```
##Результат

Сканируются два шарда.

## Запрос без shard key
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM payment_router
WHERE student_id = 100;
```
## Результат

PostgreSQL не может определить нужный шард заранее, поэтому выполняется сканирование всех шардов.

