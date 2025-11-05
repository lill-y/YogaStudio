# Подзапросы

## 1. SELECT

### 1.1. Количество классов у каждого инструктора
```sql
SELECT 
    s.FirstName,
    s.LastName,
    (SELECT COUNT(*) FROM Class c WHERE c.InstructorID = i.InstructorID) AS class_count
FROM Instructor i
JOIN Staff s ON i.StaffID = s.StaffID;
```
<img width="322" height="228" alt="image" src="https://github.com/user-attachments/assets/f3f04b05-c162-4b51-bec6-b712303eca44" />

### 1.2. Средний рейтинг для каждого клиента
```sql
SELECT 
    FirstName,
    LastName,
    (SELECT AVG(Rating) FROM Review r WHERE r.ClientID = c.ClientID) AS avg_rating
FROM Client c;
```
<img width="378" height="304" alt="image" src="https://github.com/user-attachments/assets/29222c3b-d08f-47a3-8a89-3e242ae8c9a2" />

### 1.3. Количество клиентов в каждой студии
```sql
SELECT 
    Name,
    (SELECT COUNT(*) FROM Client cl WHERE cl.YogaStudioID = ys.YogaStudioID) AS client_count
FROM YogaStudio ys;
```
<img width="302" height="109" alt="image" src="https://github.com/user-attachments/assets/d53e2a36-9113-4481-849c-d72983bf0d77" />

## 2. FROM

### 2.1. Студии с количеством клиентов больше среднего
```sql
SELECT *
FROM (
    SELECT 
        ys.Name,
        COUNT(c.ClientID) AS client_count
    FROM YogaStudio ys
    LEFT JOIN Client c ON ys.YogaStudioID = c.YogaStudioID
    GROUP BY ys.YogaStudioID, ys.Name
) studio_stats
WHERE client_count > (SELECT AVG(client_count) FROM (
    SELECT COUNT(ClientID) AS client_count
    FROM Client
    GROUP BY YogaStudioID
) avg_stats);
```
![photo_2025-11-05 08 39 35](https://github.com/user-attachments/assets/7d4262fa-ccc4-48bf-8080-c2ae0c204749)

### 2.2. Инструкторы с опытом выше среднего
```sql
SELECT *
FROM (
    SELECT 
        s.FirstName,
        s.LastName,
        i.ExperienceYears
    FROM Instructor i
    JOIN Staff s ON i.StaffID = s.StaffID
) instructor_exp
WHERE ExperienceYears > (SELECT AVG(ExperienceYears) FROM Instructor);
```
<img width="356" height="137" alt="image" src="https://github.com/user-attachments/assets/16c12fa7-c22d-4396-be08-2acbaa641977" />

### 2.3. Классы с заполняемостью выше 60%
```sql
SELECT *
FROM (
    SELECT 
        Name,
        MaxCapacity,
        ROUND((MaxCapacity * 0.8) / MaxCapacity * 100, 2) AS occupancy_rate
    FROM Class
) class_occupancy
WHERE occupancy_rate > 60;
```
<img width="561" height="276" alt="image" src="https://github.com/user-attachments/assets/396a8e6f-82c1-43e1-8b1d-760f82774e16" />

## 3. WHERE

### 3.1. Клиенты с рейтингом выше среднего
```sql
SELECT *
FROM Client c
WHERE c.ClientID IN (
    SELECT ClientID 
    FROM Review 
    GROUP BY ClientID 
    HAVING AVG(Rating) > (SELECT AVG(Rating) FROM Review)
);
```
<img width="690" height="137" alt="image" src="https://github.com/user-attachments/assets/7d402196-fbd8-4a30-80f7-56bca5d58992" />

### 3.2. Инструкторы без классов
```sql
SELECT *
FROM Instructor i
WHERE i.InstructorID NOT IN (
    SELECT DISTINCT InstructorID 
    FROM Class 
    WHERE InstructorID IS NOT NULL
);
```
<img width="656" height="127" alt="image" src="https://github.com/user-attachments/assets/acb581df-4e22-425d-b1ce-1fd15fa8a6c3" />

### 3.3. Студии без отзывов
```sql
SELECT *
FROM YogaStudio ys
WHERE ys.YogaStudioID NOT IN (
    SELECT DISTINCT c.YogaStudioID
    FROM Client c
    JOIN Review r ON c.ClientID = r.ClientID
);
```
![Uploading tg_image_1832966036.png…]()

## 4. HAVING

### 4.1.  Инструкторы с количеством классов больше среднего
```sql
SELECT 
    i.InstructorID,
    COUNT(c.ClassID) AS class_count
FROM Instructor i
LEFT JOIN Class c ON i.InstructorID = c.InstructorID
GROUP BY i.InstructorID
HAVING COUNT(c.ClassID) > (
    SELECT AVG(class_count) 
    FROM (
        SELECT COUNT(ClassID) AS class_count
        FROM Class
        GROUP BY InstructorID
    ) avg_classes
);
```

### 4.2. Клиенты с количеством отзывов больше 1
```sql
SELECT 
    c.ClientID,
    c.FirstName,
    c.LastName,
    COUNT(r.ReviewID) AS review_count
FROM Client c
JOIN Review r ON c.ClientID = r.ClientID
GROUP BY c.ClientID, c.FirstName, c.LastName
HAVING COUNT(r.ReviewID) > (
    SELECT AVG(review_count)
    FROM (
        SELECT COUNT(ReviewID) AS review_count
        FROM Review
        GROUP BY ClientID
    ) client_reviews
);
```

### 4.3. Типы членств с средней стоимостью выше общей средней
```sql
SELECT 
    m.Type,
    AVG(p.Amount) AS avg_amount
FROM Membership m
JOIN Payment p ON m.MembershipID = p.MembershipID
GROUP BY m.Type
HAVING AVG(p.Amount) > (
    SELECT AVG(Amount) 
    FROM Payment
);
```

## 5. ALL

### 5.1. Клиенты старше всех в своей студии
```sql
SELECT *
FROM Client c1
WHERE c1.DateOfBirth < ALL (
    SELECT c2.DateOfBirth
    FROM Client c2
    WHERE c2.YogaStudioID = c1.YogaStudioID
    AND c2.ClientID != c1.ClientID
);
```

### 5.2. Инструкторы с опытом больше всех в своей специализации
```sql
SELECT *
FROM Instructor i1
WHERE i1.ExperienceYears > ALL (
    SELECT i2.ExperienceYears
    FROM Instructor i2
    WHERE i2.Specialty = i1.Specialty
    AND i2.InstructorID != i1.InstructorID
);
```

### 5.3. Классы с вместимостью больше всех в своей студии
```sql
SELECT *
FROM Class c
WHERE c.MaxCapacity > ALL (
    SELECT c2.MaxCapacity
    FROM Class c2
    JOIN Room r ON c2.RoomID = r.RoomID
    WHERE r.YogaStudioID = (
        SELECT YogaStudioID 
        FROM Room 
        WHERE RoomID = c.RoomID
    )
    AND c2.ClassID != c.ClassID
);
```

## 6. IN

### 6.1. Клиенты из студий с более чем 3 клиентами
```sql
SELECT *
FROM Client
WHERE YogaStudioID IN (
    SELECT YogaStudioID
    FROM Client
    GROUP BY YogaStudioID
    HAVING COUNT(*) > 3
);
```

### 6.2. Классы инструкторов с опытом более 5 лет
```sql
SELECT *
FROM Class
WHERE InstructorID IN (
    SELECT InstructorID
    FROM Instructor
    WHERE ExperienceYears > 5
);
```

### 6.3. Отзывы от клиентов с активными членствами
```sql
SELECT *
FROM Review
WHERE ClientID IN (
    SELECT ClientID
    FROM Membership
    WHERE Status = 'active' AND EndDate >= CURRENT_DATE
);
```

## 7. ANY

### 7.1. Клиенты с хотя бы одним отзывом 5 звезд
```sql
SELECT *
FROM Client c
WHERE 5 = ANY (
    SELECT Rating
    FROM Review r
    WHERE r.ClientID = c.ClientID
);
```

### 7.2. Инструкторы с классами любой вместимости больше 15
```sql
SELECT *
FROM Instructor i
WHERE 15 < ANY (
    SELECT MaxCapacity
    FROM Class c
    WHERE c.InstructorID = i.InstructorID
);
```

### 7.3. Студии с клиентами любого возраста до 30 лет
```sql
SELECT *
FROM YogaStudio ys
WHERE 30 > ANY (
    SELECT EXTRACT(YEAR FROM AGE(CURRENT_DATE, DateOfBirth))
    FROM Client c
    WHERE c.YogaStudioID = ys.YogaStudioID
);
```

## 8. EXISTS

### 8.1. Клиенты с отзывами
```sql
SELECT *
FROM Client c
WHERE EXISTS (
    SELECT 1
    FROM Review r
    WHERE r.ClientID = c.ClientID
);
```

### 8.2. Инструкторы с классами в больших помещениях
```sql
SELECT *
FROM Instructor i
WHERE EXISTS (
    SELECT 1
    FROM Class c
    JOIN Room r ON c.RoomID = r.RoomID
    WHERE c.InstructorID = i.InstructorID
    AND r.Capacity > 20
);
```

### 8.3. Студии с платежами за последний месяц
```sql
SELECT *
FROM YogaStudio ys
WHERE EXISTS (
    SELECT 1
    FROM Client c
    JOIN Payment p ON c.ClientID = p.ClientID
    WHERE c.YogaStudioID = ys.YogaStudioID
    AND p.Date >= CURRENT_DATE - INTERVAL '1 month'
);
```

## 9. Сравнение по нескольким столбцам

### 9.1. Клиенты с такими же данными как у определенного клиента
```sql
SELECT *
FROM Client c1
WHERE (c1.FirstName, c1.LastName, c1.YogaStudioID) = (
    SELECT FirstName, LastName, YogaStudioID
    FROM Client c2
    WHERE c2.ClientID = 1
);
```

### 9.2. Найти дубликаты клиентов по имени и фамилии
```sql
SELECT *
FROM Client c1
WHERE EXISTS (
    SELECT 1
    FROM Client c2
    WHERE c2.FirstName = c1.FirstName
    AND c2.LastName = c1.LastName
    AND c2.ClientID != c1.ClientID
);
```

### 9.3. Классы с такими же параметрами как у самого популярного
```sql
SELECT *
FROM Class c1
WHERE (c1.MaxCapacity, c1.RoomID) = (
    SELECT MaxCapacity, RoomID
    FROM Class c2
    WHERE c2.ClassID = (
        SELECT ClassID
        FROM Class
        ORDER BY MaxCapacity DESC
        LIMIT 1
    )
);
```

## 10. Коррелированные подзапросы

### 10.1. Количество отзывов для каждого клиента
```sql
SELECT 
    c.FirstName,
    c.LastName,
    (SELECT COUNT(*) FROM Review r WHERE r.ClientID = c.ClientID) AS review_count
FROM Client c;
```

### 10.2. Средний рейтинг инструктора по отзывам на его классы
```sql
SELECT 
    s.FirstName,
    s.LastName,
    (SELECT AVG(r.Rating) 
     FROM Review r 
     JOIN Class c ON r.ReviewID = c.ClassID 
     WHERE c.InstructorID = i.InstructorID) AS avg_rating
FROM Instructor i
JOIN Staff s ON i.StaffID = s.StaffID;
```

### 10.3. Клиенты с количеством платежей выше среднего по их студии
```sql
SELECT 
    c.FirstName,
    c.LastName,
    (SELECT COUNT(*) FROM Payment p WHERE p.ClientID = c.ClientID) AS payment_count
FROM Client c
WHERE (SELECT COUNT(*) FROM Payment p WHERE p.ClientID = c.ClientID) > (
    SELECT AVG(payment_count)
    FROM (
        SELECT COUNT(*) AS payment_count
        FROM Payment p2
        JOIN Client c2 ON p2.ClientID = c2.ClientID
        WHERE c2.YogaStudioID = c.YogaStudioID
        GROUP BY p2.ClientID
    ) studio_avg
);
```

### 10.4. Инструкторы с опытом выше среднего по их специализации
```sql
SELECT 
    s.FirstName,
    s.LastName,
    i.Specialty,
    i.ExperienceYears
FROM Instructor i
JOIN Staff s ON i.StaffID = s.StaffID
WHERE i.ExperienceYears > (
    SELECT AVG(i2.ExperienceYears)
    FROM Instructor i2
    WHERE i2.Specialty = i.Specialty
);
```

### 10.5. Студии с количеством клиентов больше среднего по всем студиям
```sql
SELECT 
    ys.Name,
    (SELECT COUNT(*) FROM Client c WHERE c.YogaStudioID = ys.YogaStudioID) AS client_count
FROM YogaStudio ys
WHERE (SELECT COUNT(*) FROM Client c WHERE c.YogaStudioID = ys.YogaStudioID) > (
    SELECT AVG(studio_client_count)
    FROM (
        SELECT COUNT(*) AS studio_client_count
        FROM Client
        GROUP BY YogaStudioID
    ) avg_clients
);
```
