## 1. GIN индексы 
для них создаю тестовую таблицу
```sql
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    title TEXT,
    content TEXT,
    tags TEXT[],
    metadata JSONB
);
```
и заполняю данными

### Запрос 1: Поиск по массиву
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM documents WHERE 'yoga' = ANY(tags);

-- Создаем GIN индекс
CREATE INDEX idx_documents_tags_gin ON documents USING GIN (tags);

-- Тот же запрос с индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM documents WHERE 'yoga' = ANY(tags);
```
<img width="774" height="154" alt="image" src="https://github.com/user-attachments/assets/50492835-b92c-49a6-888e-d92188f0d929" />

<img width="810" height="191" alt="image" src="https://github.com/user-attachments/assets/bb135e11-bfeb-4f06-8e68-fc6b6e23d2df" />


### Запрос 2: Поиск по нескольким тегам
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM documents WHERE tags @> ARRAY['yoga', 'health'];
```
<img width="983" height="190" alt="image" src="https://github.com/user-attachments/assets/3b40b5c3-c3af-4d6b-8fb7-ce839e87be9b" />

### Запрос 3: Полнотекстовый поиск (создадим индекс)
```sql
CREATE INDEX idx_documents_content_gin ON documents USING GIN (to_tsvector('english', content));

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM documents 
WHERE to_tsvector('english', content) @@ to_tsquery('english', 'yoga & meditation');
```
<img width="953" height="264" alt="image" src="https://github.com/user-attachments/assets/00474646-306f-4a23-bdb4-dcb17c76cdbb" />

### Запрос 4: Поиск по JSONB
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM documents WHERE metadata @> '{"author": "Author 42"}';

-- Создаем GIN индекс на JSONB
CREATE INDEX idx_documents_metadata_gin ON documents USING GIN (metadata);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM documents WHERE metadata @> '{"author": "Author 42"}';
```
<img width="765" height="163" alt="image" src="https://github.com/user-attachments/assets/fc554525-7449-4791-b67e-b294263babe7" />

<img width="949" height="277" alt="image" src="https://github.com/user-attachments/assets/bd2d31eb-d9ec-4a37-a192-a5c297998b1d" />

### Запрос 5: Поиск по вхождению строки
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM documents WHERE content LIKE '%yoga%';

-- Для LIKE нужен триграммный индекс
CREATE INDEX idx_documents_content_trgm ON documents USING GIN (content gin_trgm_ops);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM documents WHERE content LIKE '%yoga%';
```
<img width="786" height="166" alt="image" src="https://github.com/user-attachments/assets/911bea5c-8e9d-4802-9222-620676480209" />

<img width="976" height="273" alt="image" src="https://github.com/user-attachments/assets/ecbef9c7-f296-4f08-b1ce-ae42e43ff0dd" />

## 2. GiST индексы

также создаю тест таблицу с теми данными, что работают с GiST
```sql
CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    coordinates POINT,
    location_area CIRCLE,
    event_time_range TSRANGE,
    description TEXT
);
```

### Запрос 1: Поиск ближайших точек
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM locations 
ORDER BY coordinates <-> POINT(55.75, 37.55) 
LIMIT 10;

CREATE INDEX idx_locations_coordinates_gist ON locations USING GIST (coordinates);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM locations 
ORDER BY coordinates <-> POINT(55.75, 37.55) 
LIMIT 10;
```
<img width="906" height="274" alt="image" src="https://github.com/user-attachments/assets/912fc8fa-1745-4bde-b5fc-2bfd40d20a21" />

<img width="1124" height="170" alt="image" src="https://github.com/user-attachments/assets/255db688-9d09-417c-b4d7-b84570ca863e" />

### Запрос 2: Поиск точек внутри круга
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM locations 
WHERE coordinates <@ CIRCLE(POINT(55.75, 37.55), 0.1);
```
<img width="1063" height="244" alt="image" src="https://github.com/user-attachments/assets/72d3290a-5093-4bd3-a9e8-6fd7086c7dae" />

### Запрос 3: Поиск по диапазону времени
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM locations 
WHERE event_time_range @> TIMESTAMP '2024-02-01 11:00:00';

CREATE INDEX idx_locations_time_range_gist ON locations USING GIST (event_time_range);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM locations 
WHERE event_time_range @> TIMESTAMP '2024-02-01 11:00:00';
```
<img width="728" height="175" alt="image" src="https://github.com/user-attachments/assets/69416a7f-b86d-4c49-9ee8-0a7722cc7914" />

<img width="982" height="232" alt="image" src="https://github.com/user-attachments/assets/d468d3a3-2b80-4882-a6b0-b675b37a4039" />


### Запрос 4: Пересечение диапазонов
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM locations 
WHERE event_time_range && TSRANGE(
    TIMESTAMP '2024-02-01 10:00:00', 
    TIMESTAMP '2024-02-02 10:00:00'
);
```
<img width="984" height="229" alt="image" src="https://github.com/user-attachments/assets/958ae2ef-0e73-47f7-ba67-a40489db8d5e" />

### Запрос 5: Поиск по расстоянию и времени (составной)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM locations 
WHERE coordinates <@ CIRCLE(POINT(55.75, 37.55), 0.1)
  AND event_time_range @> TIMESTAMP '2024-02-01 11:00:00'
ORDER BY coordinates <-> POINT(55.75, 37.55);
```
<img width="1033" height="259" alt="image" src="https://github.com/user-attachments/assets/543238c6-9e11-46a4-b2bb-fc1cced0266a" />

## JOIN запросы
### Запрос 1: Nested Loop Join (для маленького количества данных)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.first_name, c.last_name, m.membership_type, m.price
FROM clients c
JOIN memberships m ON c.client_id = m.client_id
WHERE c.client_id < 100; 
```
<img width="1078" height="325" alt="image" src="https://github.com/user-attachments/assets/e4034499-e176-40b5-abc9-0b1b73a31712" />


### Запрос 2: Hash Join (для больших несортированных данных)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.first_name, c.last_name, p.amount, p.payment_date
FROM clients c
JOIN payments p ON c.client_id = p.client_id
WHERE p.amount > 10000;
```
<img width="1075" height="388" alt="image" src="https://github.com/user-attachments/assets/2fc0753e-61ae-4ca9-aacc-a3ac9264701f" />

### Запрос 3: Merge Join (для отсортированных данных)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.first_name, c.last_name, m.membership_type, m.start_date
FROM clients c
JOIN memberships m ON c.client_id = m.client_id
ORDER BY c.client_id, m.start_date;
```
<img width="1082" height="451" alt="image" src="https://github.com/user-attachments/assets/e637bfdb-3d24-4315-925e-f2a2749a39b3" />

### Запрос 4: Тройной JOIN (смешанные типы)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.first_name, c.last_name, 
       s.name as studio_name,
       COUNT(p.payment_id) as payments_count,
       SUM(p.amount) as total_spent
FROM clients c
JOIN studios s ON c.studio_id = s.studio_id
LEFT JOIN payments p ON c.client_id = p.client_id
GROUP BY c.client_id, c.first_name, c.last_name, s.name
ORDER BY total_spent DESC NULLS LAST
LIMIT 20;
```
<img width="1176" height="775" alt="image" src="https://github.com/user-attachments/assets/0c929e83-3f3e-4a90-8ba3-df0f9483793f" />

### Запрос 5: JOIN с подзапросом (может дать Hash Semi Join)
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.first_name, c.last_name, c.email
FROM clients c
WHERE EXISTS (
    SELECT 1
    FROM payments p
    WHERE p.client_id = c.client_id
    AND p.amount > 20000
);
```
<img width="1111" height="311" alt="image" src="https://github.com/user-attachments/assets/7570b6fc-75b3-40ed-98a8-caab11052e5f" />



