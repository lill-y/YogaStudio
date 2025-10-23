# Агрегатные функции и операторы GROUP BY, HAVING

## 1. Avg

### 1.1. Рассчитать средний рейтинг всех отзывов
```sql
SELECT AVG(Rating) AS AverageRating
FROM Review;
```

### 1.2. Рассчитать средний опыт работы инструкторов по специализациям
```sql
SELECT Specialty, AVG(ExperienceYears) AS AvgExperience
FROM Instructor
GROUP BY Specialty;
```

## 2. Count

### 2.1. Посчитать общее количество клиентов
```sql
SELECT COUNT(*) AS TotalClients
FROM Client;
```


### 2.2. Посчитать количество классов у каждого инструктора
```sql
SELECT 
    s.FirstName,
    s.LastName,
    COUNT(c.ClassID) AS NumberOfClasses
FROM Instructor i
JOIN Staff s ON i.StaffID = s.StaffID
LEFT JOIN Class c ON i.InstructorID = c.InstructorID
GROUP BY s.FirstName, s.LastName;
```


## 3. Min и Max

### 3.1. Найти самый старый и самый молодой возраст клиентов
```sql
SELECT 
    MIN(EXTRACT(YEAR FROM AGE(CURRENT_DATE, DateOfBirth))) AS MinAge,
    MAX(EXTRACT(YEAR FROM AGE(CURRENT_DATE, DateOfBirth))) AS MaxAge
FROM Client;
```


### 3.2. Найти самый дорогой и самый дешевый платеж
```sql
SELECT 
    MIN(p.Amount) AS MinPayment,
    MAX(p.Amount) AS MaxPayment
FROM Payment p;
```

## 4. Sum

### 4.1. Посчитать общую выручку по месяцам
```sql
SELECT 
    EXTRACT(YEAR FROM Date) AS Year,
    EXTRACT(MONTH FROM Date) AS Month,
    SUM(Amount) AS MonthlyRevenue
FROM Payment
GROUP BY EXTRACT(YEAR FROM Date), EXTRACT(MONTH FROM Date)
ORDER BY Year, Month;
```


### 4.2. Посчитать общее количество клиентов в каждой студии
```sql
SELECT 
    ys.Name AS StudioName,
    COUNT(c.ClientID) AS TotalClients
FROM YogaStudio ys
LEFT JOIN Client c ON ys.YogaStudioID = c.YogaStudioID
GROUP BY ys.Name;
```

## 5. STRING_AGG

### 5.1. Получить список всех специализаций инструкторов в каждой студии
```sql
SELECT 
    ys.Name AS StudioName,
    STRING_AGG(DISTINCT i.Specialty, ', ') AS Specialties
FROM YogaStudio ys
JOIN Staff s ON ys.YogaStudioID = s.YogaStudioID
JOIN Instructor i ON s.StaffID = i.StaffID
GROUP BY ys.Name;
```


### 5.2. 
```sql

```

## 6. Комбинирование функций

### 6.1. Статистика по классам: количество, средняя вместимость, минимальная и максимальная
```sql
SELECT 
    COUNT(*) AS TotalClasses,
    AVG(MaxCapacity) AS AvgCapacity,
    MIN(MaxCapacity) AS MinCapacity,
    MAX(MaxCapacity) AS MaxCapacity
FROM Class;
```


### 6.2. Статистика по отзывам: количество, средний рейтинг, минимальный и максимальный
```sql
SELECT 
    COUNT(*) AS TotalReviews,
    AVG(Rating) AS AvgRating,
    MIN(Rating) AS MinRating,
    MAX(Rating) AS MaxRating
FROM Review;
```

## 7. GROUP BY

### 7.1. Количество клиентов по студиям
```sql
SELECT 
    ys.Name AS StudioName,
    COUNT(c.ClientID) AS ClientCount
FROM YogaStudio ys
LEFT JOIN Client c ON ys.YogaStudioID = c.YogaStudioID
GROUP BY ys.Name;

```


### 7.2. 
```sql

```

## 8. HAVING

### 8.1. Найти студии с более чем 2 клиентами
```sql
SELECT 
    ys.Name AS StudioName,
    COUNT(c.ClientID) AS ClientCount
FROM YogaStudio ys
JOIN Client c ON ys.YogaStudioID = c.YogaStudioID
GROUP BY ys.Name
HAVING COUNT(c.ClientID) > 2;
```


### 8.2. 
```sql
SELECT 
    m.Type AS MembershipType,
    AVG(r.Rating) AS AvgMembershipRating
Membership m
JOIN Client cl ON m.ClientID = cl.ClientID
JOIN Review r ON cl.ClientID = r.ClientID
GROUP BY m.Type
HAVING AVG(r.Rating) > 4.0;
```

## 9. GROUPING SETS

### 9.1. Анализ платежей по годам и типам членств
```sql
SELECT 
    EXTRACT(YEAR FROM p.Date) AS Year,
    m.Type AS MembershipType,
    SUM(p.Amount) AS TotalAmount
FROM Payment p
JOIN Membership m ON p.MembershipID = m.MembershipID
GROUP BY GROUPING SETS (
    (EXTRACT(YEAR FROM p.Date)),
    (m.Type),
    (EXTRACT(YEAR FROM p.Date), m.Type),
    ()
);
```


### 9.2. Анализ платежей по типам и годам
```sql
SELECT
    type,
    YEAR(date) AS year,
    SUM(amount) AS total
FROM payments
GROUP BY GROUPING SETS ((type, year), (type), (year), ());
```

## 10. ROLLUP

### 10.1. Иерархия по студиям и годам
```sql
SELECT
    studio,
    YEAR(date) AS year,
    SUM(amount) AS total
FROM payments
GROUP BY ROLLUP (studio, year);
```


### 10.2. Клиенты по студиям и статусу
```sql
SELECT
    studio,
    status,
    COUNT(client) AS clients
FROM memberships
GROUP BY ROLLUP (studio, status);
```

## 11. CUBE

### 11.1. Анализ классов
```sql
SELECT
    studio,
    room,
    instructor,
    COUNT(class) AS classes
FROM classes
GROUP BY CUBE (studio, room, instructor);
```


### 11.2. Анализ отзывов
```sql
SELECT
    studio,
    rating,
    COUNT(review) AS reviews
FROM reviews
GROUP BY CUBE (studio, rating);
```
