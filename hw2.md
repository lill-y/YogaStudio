 ![telegram-cloud-photo-size-2-5298672931305100597-y](https://github.com/user-attachments/assets/3e11b182-dd5a-45ee-9d45-c144441a8786)

## 1. Запрос с оператором ">"
### 1.1 Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM payments 
WHERE amount > 15000;
```
 
 ![telegram-cloud-photo-size-2-5298672931305100620-y](https://github.com/user-attachments/assets/40a26ae0-6dd9-419a-a903-9eab2dc43fc9)
### 1.2. С B-tree индексом
```sql
CREATE INDEX idx_payments_amount_btree ON payments(amount);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM payments 
WHERE amount > 15000;
```
![telegram-cloud-photo-size-2-5298672931305100621-y](https://github.com/user-attachments/assets/e6e59242-b6f2-4fa3-a2ee-1dadd64da878)

### 1.3. С Hash индексом
```sql
CREATE INDEX idx_payments_amount_hash ON payments USING HASH (amount);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM payments 
WHERE amount > 15000;
```
 ![telegram-cloud-photo-size-2-5298672931305100622-y](https://github.com/user-attachments/assets/58d04f24-d7dc-4377-bed4-24b2ebc948cd)

## 2. Запрос с оператором "<"

### 2.1 Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM memberships 
WHERE price < 5000;
```
 ![telegram-cloud-photo-size-2-5298672931305100623-y](https://github.com/user-attachments/assets/af1b0fb5-7c2a-4500-9461-cbf69a77d375)

### 2.2. С B-tree индексом
```sql
CREATE INDEX idx_memberships_price_btree ON memberships(price);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM memberships 
WHERE price < 5000;
```
![telegram-cloud-photo-size-2-5298672931305100624-y](https://github.com/user-attachments/assets/96c26969-b36d-40e4-8829-c884286e0ce7)


### 2.3. С Hash индексом
```sql
CREATE INDEX idx_payments_amount_hash ON payments USING HASH (amount);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM payments 
WHERE amount > 15000;
```
 ![telegram-cloud-photo-size-2-5298672931305100625-y](https://github.com/user-attachments/assets/dfd8db28-ffd9-434d-9849-84abc411577d)


## 3. Запрос с оператором "="
### 3.1 Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM clients 
WHERE email = 'user123456@example.com';
```
![telegram-cloud-photo-size-2-5298672931305100626-y](https://github.com/user-attachments/assets/14acc8fa-6c99-48db-8c8b-4bc8e6557d40)

### 3.2. С B-tree индексом
```sql
CREATE INDEX idx_clients_email_btree ON clients(email);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM clients 
WHERE email = 'user123456@example.com';
```
![telegram-cloud-photo-size-2-5298672931305100627-y](https://github.com/user-attachments/assets/70b886c4-19a2-43c0-934b-eb4e8532c42a)


### 3.3. С Hash индексом
```sql
CREATE INDEX idx_clients_email_hash ON clients USING HASH (email);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM clients 
WHERE email = 'user123456@example.com';
```
 ![telegram-cloud-photo-size-2-5298672931305100633-y](https://github.com/user-attachments/assets/3cf99fd8-f578-41f8-9a00-b47f28812edf)

## 4. Запрос с оператором "%like"
### 4.1 Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM clients 
WHERE first_name LIKE 'Ан%';
```
![telegram-cloud-photo-size-2-5298672931305100634-y](https://github.com/user-attachments/assets/42ce168d-549f-41a8-8d18-929a45b76bc3)

### 4.2. С B-tree индексом
```sql
CREATE INDEX idx_clients_first_name_btree ON clients(first_name text_pattern_ops);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM clients 
WHERE first_name LIKE 'Ан%';
```
![telegram-cloud-photo-size-2-5298672931305100635-y](https://github.com/user-attachments/assets/a9c8474a-64f3-47ba-a28a-2126a1957438)


### 4.3. С Hash индексом
```sql
CREATE INDEX idx_clients_first_name_hash ON clients USING HASH (first_name);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM clients 
WHERE first_name LIKE 'Ан%';
```
 ![telegram-cloud-photo-size-2-5298672931305100636-y](https://github.com/user-attachments/assets/9563a184-3743-4385-9723-1c03926ce7b3)

## 5. Запрос с оператором "IN"

### 5.1 Без индекса

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM payments 
WHERE status IN ('pending', 'failed', 'refunded');
```
![telegram-cloud-photo-size-2-5298672931305100638-y](https://github.com/user-attachments/assets/b43924f3-e341-4792-918c-6506a50c4c94)

### 5.2. С B-tree индексом
```sql
CREATE INDEX idx_payments_status_btree ON payments(status);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM payments 
WHERE status IN ('pending', 'failed', 'refunded');
```
![telegram-cloud-photo-size-2-5298672931305100642-y](https://github.com/user-attachments/assets/6a11e17b-6364-4ee5-abf5-a0951ef34e87)

### 5.3. С Hash индексом
```sql
CREATE INDEX idx_payments_status_hash ON payments USING HASH (status);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM payments 
WHERE status IN ('pending', 'failed', 'refunded');
```
![telegram-cloud-photo-size-2-5298672931305100644-y](https://github.com/user-attachments/assets/254238f6-e90e-456f-bc3a-69c39f34fdc7)

# Вывод
Hash индекс сработал лучше, чем B-tree индекс только в случае =, в остальных же случаях лучше использовать B-tree
