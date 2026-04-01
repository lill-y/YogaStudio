# Практическая контрольная работа — вариант 2
## Задание 1. Оптимизация простого запроса
### 1 
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, shop_id, total_sum, sold_at
FROM store_checks
WHERE shop_id = 77
  AND sold_at >= TIMESTAMP '2025-02-14 00:00:00'
  AND sold_at < TIMESTAMP '2025-02-15 00:00:00';
  <img width="1121" height="188" alt="image" src="https://github.com/user-attachments/assets/7ceaafde-cfae-4f76-8679-972504bc4943" />

забыла изначальный скрин сделать :(
### 2
Тип сканирования: Seq Scan

Какие индексы не помогают: payment_type и total_sum не используются, так как не участвуют в условиях WHERE.
Почему выбран такой план: Планировщик выбирает последовательное сканирование, потому что отсутствует индекс по shop_id и sold_at

### 3 составной индекс

CREATE INDEX idx_store_checks_shop_date
ON store_checks (shop_id, sold_at);

### 4 План после изменений
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, shop_id, total_sum, sold_at
FROM store_checks
WHERE shop_id = 77
  AND sold_at >= TIMESTAMP '2025-02-14 00:00:00'
  AND sold_at < TIMESTAMP '2025-02-15 00:00:00';
<img width="1177" height="140" alt="image" src="https://github.com/user-attachments/assets/c48cf228-420e-48e0-87ee-1d49d9a9fef2" />

### 5 
После создания индекса план изменился с Seq Scan на Index Scan
В этом случае у нас индекс по shop_id и sold_at, что позволяет отфильтровать нужные строки без полного сканирования таблицы

### 6 

Да, чтобы обновить статистику таблицы.
Это помогает планировщику выбрать более оптимальный план выполнения запроса


## Задание 2. Анализ и улучшение JOIN-запроса
### 1 
EXPLAIN (ANALYZE, BUFFERS)
SELECT m.id, m.member_level, v.spend, v.visit_at
FROM club_members m
JOIN club_visits v ON v.member_id = m.id
WHERE m.member_level = 'premium'
  AND v.visit_at >= TIMESTAMP '2025-02-01 00:00:00'
  AND v.visit_at < TIMESTAMP '2025-02-10 00:00:00';

  
### 2 

Используется Hash Join

### 3
Соединение по равенству без подходящих индексов, поэтому хеширование дешевле полного перебора

### 4
Индекс по full_name не используется, индекс по visit_at не покрывает соединение

### 5

CREATE INDEX idx_club_visits_member_date
ON club_visits (member_id, visit_at);

### 6
EXPLAIN (ANALYZE, BUFFERS)
SELECT m.id, m.member_level, v.spend, v.visit_at
FROM club_members m
JOIN club_visits v ON v.member_id = m.id
WHERE m.member_level = 'premium'
  AND v.visit_at >= TIMESTAMP '2025-02-01 00:00:00'
  AND v.visit_at < TIMESTAMP '2025-02-10 00:00:00';
<img width="1127" height="387" alt="image" src="https://github.com/user-attachments/assets/de521f01-c0c0-4318-8008-34932346782c" />

### 7 !!!!!!X!!!!!!!!!!

### 8

shared hit означает, что данные были прочитаны из памяти оп, без заглядывания в диск
shared read означает чтение с диска 

## Задание 3. MVCC и очистка

<img width="391" height="493" alt="image" src="https://github.com/user-attachments/assets/b08a8938-708f-483b-82c3-f919e4906361" />

### 1

вообще должна создаваться новая версия строки, а старая помечается через xmax, но у меня не пометилось :(

### 2 
Обеспечивает параллельность и изоляцию транзакций без блокировки чтения

### 3
Строка становится невидимой, но физически не удаляется сразу.
### 4
VACUUM: удаляет мёртвые строки логически.
autovacuum: Автоматический VACUUM (обновляет analyze)
VACUUM FULL: Переписывает таблицу и блокирует её
### 5
VACUUM FULL
## Задание 4. Блокировки строк
<img width="876" height="294" alt="image" src="https://github.com/user-attachments/assets/b86cd556-faf2-4808-94b4-7e227516093f" />

1. DELETE зависает и не дает удалить, UPDATE выполняется сразу
2. 
3. 
4.
