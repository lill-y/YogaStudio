1. CTE - Common Table Expressions
1.1. CTE для анализа клиентов по студиям
```sql
WITH StudioClients AS (
    SELECT 
        ys.Name AS studio_name,
        COUNT(c.ClientID) AS client_count
    FROM YogaStudio ys
    LEFT JOIN Client c ON ys.YogaStudioID = c.YogaStudioID
    GROUP BY ys.YogaStudioID, ys.Name
)
SELECT 
    studio_name,
    client_count,
    ROUND(client_count * 100.0 / (SELECT SUM(client_count) FROM StudioClients), 2) AS percentage
FROM StudioClients
ORDER BY client_count DESC;
```

1.2. CTE для финансового анализа по месяцам
```sql
WITH MonthlyRevenue AS (
    SELECT 
        EXTRACT(YEAR FROM p.Date) AS year,
        EXTRACT(MONTH FROM p.Date) AS month,
        SUM(p.Amount) AS total_revenue,
        COUNT(p.PaymentID) AS payment_count
    FROM Payment p
    GROUP BY EXTRACT(YEAR FROM p.Date), EXTRACT(MONTH FROM p.Date)
)
SELECT 
    year,
    month,
    total_revenue,
    payment_count,
    ROUND(total_revenue / payment_count, 2) AS avg_payment
FROM MonthlyRevenue
ORDER BY year, month;
```
1.3. CTE для анализа инструкторов и их классов
```sql
WITH InstructorStats AS (
    SELECT 
        s.FirstName,
        s.LastName,
        i.Specialty,
        i.ExperienceYears,
        COUNT(c.ClassID) AS class_count,
        AVG(c.MaxCapacity) AS avg_capacity
    FROM Instructor i
    JOIN Staff s ON i.StaffID = s.StaffID
    LEFT JOIN Class c ON i.InstructorID = c.InstructorID
    GROUP BY s.FirstName, s.LastName, i.Specialty, i.ExperienceYears
)
SELECT 
    FirstName,
    LastName,
    Specialty,
    ExperienceYears,
    class_count,
    avg_capacity,
    CASE 
        WHEN class_count > 3 THEN 'Высокая нагрузка'
        WHEN class_count BETWEEN 1 AND 3 THEN 'Средняя нагрузка'
        ELSE 'Низкая нагрузка'
    END AS workload
FROM InstructorStats
ORDER BY class_count DESC;
```
1.4. CTE для анализа отзывов клиентов
```sql
WITH ClientReviews AS (
    SELECT 
        c.ClientID,
        c.FirstName,
        c.LastName,
        COUNT(r.ReviewID) AS review_count,
        AVG(r.Rating) AS avg_rating,
        MIN(r.Rating) AS min_rating,
        MAX(r.Rating) AS max_rating
    FROM Client c
    LEFT JOIN Review r ON c.ClientID = r.ClientID
    GROUP BY c.ClientID, c.FirstName, c.LastName
),
ReviewStats AS (
    SELECT 
        ClientID,
        FirstName,
        LastName,
        review_count,
        avg_rating,
        min_rating,
        max_rating,
        CASE 
            WHEN avg_rating >= 4.5 THEN 'Постоянный клиент'
            WHEN avg_rating >= 3.5 THEN 'Активный клиент'
            WHEN avg_rating IS NOT NULL THEN 'Новый клиент'
            ELSE 'Без отзывов'
        END AS client_type
    FROM ClientReviews
)
SELECT * FROM ReviewStats
ORDER BY avg_rating DESC NULLS LAST;
```
1.5. CTE для анализа занятости помещений
```sql
WITH RoomUtilization AS (
    SELECT 
        r.RoomID,
        r.Name AS room_name,
        ys.Name AS studio_name,
        r.Capacity,
        COUNT(c.ClassID) AS scheduled_classes,
        AVG(c.MaxCapacity) AS avg_class_capacity
    FROM Room r
    JOIN YogaStudio ys ON r.YogaStudioID = ys.YogaStudioID
    LEFT JOIN Class c ON r.RoomID = c.RoomID
    GROUP BY r.RoomID, r.Name, ys.Name, r.Capacity
)
SELECT 
    room_name,
    studio_name,
    Capacity,
    scheduled_classes,
    avg_class_capacity,
    ROUND((avg_class_capacity / Capacity) * 100, 2) AS utilization_percent
FROM RoomUtilization
ORDER BY utilization_percent DESC;
```
2. UNION
2.1. Объединение имен клиентов и сотрудников
```sql
SELECT FirstName, LastName, 'Client' AS type FROM Client
UNION
SELECT FirstName, LastName, 'Staff' AS type FROM Staff
ORDER BY LastName, FirstName;
```
2.2. Объединение всех контактов (клиенты и сотрудники)
```sql
SELECT FirstName, LastName, Phone, 'Client' AS role FROM Client
UNION
SELECT FirstName, LastName, Phone, Role AS role FROM Staff
ORDER BY role, LastName;
```
2.3. Объединение различных типов активностей
```sql
SELECT Name AS activity_name, 'Class' AS type FROM Class
UNION
SELECT Name AS activity_name, 'Room' AS type FROM Room
UNION
SELECT Name AS activity_name, 'Studio' AS type FROM YogaStudio
ORDER BY type, activity_name;
```
3.INTERSECT
3.1. Клиенты, которые также являются сотрудниками (по имени и фамилии)
```sql
SELECT FirstName, LastName FROM Client
INTERSECT
SELECT FirstName, LastName FROM Staff;
```
3.2. Специализации инструкторов, которые есть в нескольких студиях
```sql
SELECT i.Specialty 
FROM Instructor i
JOIN Staff s ON i.StaffID = s.StaffID
JOIN YogaStudio ys ON s.YogaStudioID = ys.YogaStudioID
WHERE ys.Name = 'Йога-центр "Гармония"'
INTERSECT
SELECT i.Specialty 
FROM Instructor i
JOIN Staff s ON i.StaffID = s.StaffID
JOIN YogaStudio ys ON s.YogaStudioID = ys.YogaStudioID
WHERE ys.Name = 'Студия "Дыхание"';
```
3.3. Дни недели, когда есть занятия во всех студиях
```sql
SELECT DayOfWeek FROM Schedule WHERE YogaStudioID = 1
INTERSECT
SELECT DayOfWeek FROM Schedule WHERE YogaStudioID = 2
INTERSECT
SELECT DayOfWeek FROM Schedule WHERE YogaStudioID = 3;
```
4.EXCEPT
4.1. Клиенты без отзывов
```sql
SELECT ClientID, FirstName, LastName FROM Client
EXCEPT
SELECT DISTINCT c.ClientID, c.FirstName, c.LastName 
FROM Client c
JOIN Review r ON c.ClientID = r.ClientID;
```
4.2. Студии без утренних занятий
```sql
SELECT YogaStudioID, Name FROM YogaStudio
EXCEPT
SELECT DISTINCT ys.YogaStudioID, ys.Name
FROM YogaStudio ys
JOIN Schedule s ON ys.YogaStudioID = s.YogaStudioID
WHERE s.StartTime < '12:00:00';
```

4.3. Инструкторы без назначенных классов
```sql
SELECT i.InstructorID, s.FirstName, s.LastName 
FROM Instructor i
JOIN Staff s ON i.StaffID = s.StaffID
EXCEPT
SELECT DISTINCT i.InstructorID, s.FirstName, s.LastName
FROM Instructor i
JOIN Staff s ON i.StaffID = s.StaffID
JOIN Class c ON i.InstructorID = c.InstructorID;
```
Оконные функции
5. PARTITION BY
5.1. Рейтинг клиентов внутри каждой студии
```sql
SELECT 
    ys.Name AS studio_name,
    c.FirstName,
    c.LastName,
    AVG(r.Rating) AS avg_rating,
    RANK() OVER (PARTITION BY ys.YogaStudioID ORDER BY AVG(r.Rating) DESC) AS rank_in_studio
FROM Client c
JOIN YogaStudio ys ON c.YogaStudioID = ys.YogaStudioID
LEFT JOIN Review r ON c.ClientID = r.ClientID
GROUP BY ys.YogaStudioID, ys.Name, c.ClientID, c.FirstName, c.LastName
HAVING COUNT(r.ReviewID) > 0;
```
5.2. Сравнение платежей клиентов с средним по их типу членства
```sql
SELECT 
    c.FirstName,
    c.LastName,
    m.Type AS membership_type,
    p.Amount,
    AVG(p.Amount) OVER (PARTITION BY m.Type) AS avg_for_membership_type,
    p.Amount - AVG(p.Amount) OVER (PARTITION BY m.Type) AS difference_from_avg
FROM Payment p
JOIN Membership m ON p.MembershipID = m.MembershipID
JOIN Client c ON p.ClientID = c.ClientID;
```
6. PARTITION BY + ORDER BY
6.1. Накопительная сумма платежей по клиентам
```sql
SELECT 
    c.FirstName,
    c.LastName,
    p.Date,
    p.Amount,
    SUM(p.Amount) OVER (
        PARTITION BY p.ClientID 
        ORDER BY p.Date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_amount
FROM Payment p
JOIN Client c ON p.ClientID = c.ClientID
ORDER BY c.LastName, p.Date;
```
6.2. Рейтинг инструкторов по опыту внутри специализации
```sql
SELECT 
    s.FirstName,
    s.LastName,
    i.Specialty,
    i.ExperienceYears,
    RANK() OVER (PARTITION BY i.Specialty ORDER BY i.ExperienceYears DESC) AS experience_rank,
    DENSE_RANK() OVER (PARTITION BY i.Specialty ORDER BY i.ExperienceYears DESC) AS dense_experience_rank
FROM Instructor i
JOIN Staff s ON i.StaffID = s.StaffID;
```
7. ROWS
7.1. Скользящее среднее платежей за 3 месяца
```sql
SELECT 
    Date,
    Amount,
    AVG(Amount) OVER (
        ORDER BY Date 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3_months
FROM Payment
ORDER BY Date;
```
7.2. Разница с предыдущим платежом для каждого клиента
```sql
SELECT 
    c.FirstName,
    c.LastName,
    p.Date,
    p.Amount,
    LAG(p.Amount) OVER (
        PARTITION BY p.ClientID 
        ORDER BY p.Date
    ) AS previous_amount,
    p.Amount - LAG(p.Amount) OVER (
        PARTITION BY p.ClientID 
        ORDER BY p.Date
    ) AS amount_difference
FROM Payment p
JOIN Client c ON p.ClientID = c.ClientID
ORDER BY c.LastName, p.Date;
```
8. RANGE
8.1. Сумма платежей за текущий и предыдущий месяц
```sql
SELECT 
    Date,
    Amount,
    SUM(Amount) OVER (
        ORDER BY Date 
        RANGE BETWEEN INTERVAL '1 month' PRECEDING AND CURRENT ROW
    ) AS sum_2_months
FROM Payment
ORDER BY Date;
```
8.2. Средний рейтинг за текущий и следующий месяц
```sql
SELECT 
    r.ReviewID,
    c.FirstName,
    c.LastName,
    r.Rating,
    AVG(r.Rating) OVER (
        ORDER BY (EXTRACT(YEAR FROM CURRENT_DATE) * 12 + EXTRACT(MONTH FROM CURRENT_DATE))
        RANGE BETWEEN CURRENT ROW AND 1 FOLLOWING
    ) AS avg_rating_2_months
FROM Review r
JOIN Client c ON r.ClientID = c.ClientID;
```
9. Ранжирующие функции
9.1. ROW_NUMBER - Нумерация клиентов по дате регистрации
```sql
SELECT 
    ROW_NUMBER() OVER (ORDER BY c.ClientID) AS row_num,
    c.FirstName,
    c.LastName,
    c.DateOfBirth
FROM Client c;
```
9.2. RANK - Ранжирование инструкторов по опыту
```sql
SELECT 
    s.FirstName,
    s.LastName,
    i.ExperienceYears,
    RANK() OVER (ORDER BY i.ExperienceYears DESC) AS experience_rank
FROM Instructor i
JOIN Staff s ON i.StaffID = s.StaffID;
```
9.3. DENSE_RANK - Плотное ранжирование студий по количеству клиентов
```sql
SELECT 
    ys.Name,
    COUNT(c.ClientID) AS client_count,
    DENSE_RANK() OVER (ORDER BY COUNT(c.ClientID) DESC) AS studio_rank
FROM YogaStudio ys
LEFT JOIN Client c ON ys.YogaStudioID = c.YogaStudioID
GROUP BY ys.YogaStudioID, ys.Name;
```

9.4. NTILE - Разделение клиентов на 4 группы по возрасту
```sql
SELECT 
    FirstName,
    LastName,
    DateOfBirth,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, DateOfBirth)) AS age,
    NTILE(4) OVER (ORDER BY EXTRACT(YEAR FROM AGE(CURRENT_DATE, DateOfBirth))) AS age_quartile
FROM Client;
```
9.5. PERCENT_RANK - Процентный ранг платежей
```sql
SELECT 
    p.PaymentID,
    p.Amount,
    PERCENT_RANK() OVER (ORDER BY p.Amount) AS percent_rank
FROM Payment p;
```

9.6. CUME_DIST - Кумулятивное распределение рейтингов
```sql
SELECT 
    r.Rating,
    COUNT(*) AS frequency,
    CUME_DIST() OVER (ORDER BY r.Rating) AS cumulative_distribution
FROM Review r
GROUP BY r.Rating
ORDER BY r.Rating;
```
10. Функции смещения
10.1. LAG - Сравнение с предыдущим платежом
```sql
SELECT 
    c.FirstName,
    c.LastName,
    p.Date,
    p.Amount,
    LAG(p.Amount) OVER (
        PARTITION BY p.ClientID 
        ORDER BY p.Date
    ) AS previous_payment,
    p.Amount - LAG(p.Amount) OVER (
        PARTITION BY p.ClientID 
        ORDER BY p.Date
    ) AS difference
FROM Payment p
JOIN Client c ON p.ClientID = c.ClientID
ORDER BY c.LastName, p.Date;
```
10.2. LEAD - Следующий платеж клиента
```sql
SELECT 
    c.FirstName,
    c.LastName,
    p.Date,
    p.Amount,
    LEAD(p.Date) OVER (
        PARTITION BY p.ClientID 
        ORDER BY p.Date
    ) AS next_payment_date,
    LEAD(p.Amount) OVER (
        PARTITION BY p.ClientID 
        ORDER BY p.Date
    ) AS next_payment_amount
FROM Payment p
JOIN Client c ON p.ClientID = c.ClientID
ORDER BY c.LastName, p.Date;
```
10.3. FIRST_VALUE - Первый платеж каждого клиента
```sql
SELECT 
    c.FirstName,
    c.LastName,
    p.Date,
    p.Amount,
    FIRST_VALUE(p.Amount) OVER (
        PARTITION BY p.ClientID 
        ORDER BY p.Date
    ) AS first_payment_amount,
    FIRST_VALUE(p.Date) OVER (
        PARTITION BY p.ClientID 
        ORDER BY p.Date
    ) AS first_payment_date
FROM Payment p
JOIN Client c ON p.ClientID = c.ClientID
ORDER BY c.LastName, p.Date;
```

10.4. LAST_VALUE - Последний рейтинг каждого клиента
```sql
SELECT 
    c.FirstName,
    c.LastName,
    r.Rating,
    r.Comment,
    LAST_VALUE(r.Rating) OVER (
        PARTITION BY r.ClientID 
        ORDER BY r.ReviewID
        RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_rating
FROM Review r
JOIN Client c ON r.ClientID = c.ClientID
ORDER BY c.LastName, r.ReviewID;
```
