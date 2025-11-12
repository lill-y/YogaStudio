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
<img width="517" height="124" alt="image" src="https://github.com/user-attachments/assets/254bedf7-7284-49a7-813f-f0100eb76964" />

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
<img width="533" height="172" alt="image" src="https://github.com/user-attachments/assets/b70d3b6f-9bb9-41c6-886e-a8fd03d547ed" />

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
<img width="985" height="192" alt="image" src="https://github.com/user-attachments/assets/b76ae56f-0538-46e4-a2dd-2e899b4548a5" />

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
<img width="1022" height="207" alt="image" src="https://github.com/user-attachments/assets/225bc8a7-f680-4209-b1b1-3605142d4e28" />

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
<img width="1051" height="193" alt="image" src="https://github.com/user-attachments/assets/41c2138f-c552-4437-bf2c-7538b1d98770" />

2. UNION
2.1. Объединение имен клиентов и сотрудников
```sql
SELECT FirstName, LastName, 'Client' AS type FROM Client
UNION
SELECT FirstName, LastName, 'Staff' AS type FROM Staff
ORDER BY LastName, FirstName;
```
<img width="276" height="563" alt="image" src="https://github.com/user-attachments/assets/67dab8f9-3ed3-41cf-be8a-2c96b40c93f2" />

2.2. Объединение всех контактов (клиенты и сотрудники)
```sql
SELECT FirstName, LastName, Phone, 'Client' AS role FROM Client
UNION
SELECT FirstName, LastName, Phone, Role AS role FROM Staff
ORDER BY role, LastName;
```
<img width="468" height="561" alt="image" src="https://github.com/user-attachments/assets/5f5aa067-91ce-40cb-baf6-fc912eaa87cf" />

2.3. Объединение различных типов помещений
```sql
SELECT Name AS rooms_name, 'Room' AS type FROM Room
UNION
SELECT Name AS rooms_name, 'Studio' AS type FROM YogaStudio
ORDER BY type, rooms_name;
```
<img width="294" height="291" alt="image" src="https://github.com/user-attachments/assets/510fb31f-7868-4c33-954c-e2d0e704a24d" />

3.INTERSECT
3.1. Клиенты, у которых есть и отзывы и платежи
```sql
SELECT ClientID, FirstName, LastName FROM Client
WHERE ClientID IN (SELECT ClientID FROM Review)
INTERSECT
SELECT ClientID, FirstName, LastName FROM Client
WHERE ClientID IN (SELECT ClientID FROM Payment);
```
<img width="295" height="227" alt="image" src="https://github.com/user-attachments/assets/a3d1e61c-0d15-43f6-b311-1828bb793435" />

3.2. Специализации, которые есть у инструкторов с опытом более 3 лет
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
<img width="142" height="65" alt="image" src="https://github.com/user-attachments/assets/33902e36-308d-469f-8d5a-219b1ac3cf85" />

3.3. Дни недели, когда есть занятия в больших и малых помещениях
```sql
SELECT s.DayOfWeek 
FROM Schedule s
JOIN Class c ON s.ScheduleID = c.ScheduleID
JOIN Room r ON c.RoomID = r.RoomID
WHERE r.Capacity > 20
INTERSECT
SELECT s.DayOfWeek 
FROM Schedule s
JOIN Class c ON s.ScheduleID = c.ScheduleID
JOIN Room r ON c.RoomID = r.RoomID
WHERE r.Capacity <= 20;
```
<img width="100" height="105" alt="image" src="https://github.com/user-attachments/assets/0c768f14-ea53-4505-a878-a291cf9846fe" />

4.EXCEPT
4.1. Клиенты без отзывов
```sql
SELECT ClientID, FirstName, LastName FROM Client
EXCEPT
SELECT DISTINCT c.ClientID, c.FirstName, c.LastName 
FROM Client c
JOIN Review r ON c.ClientID = r.ClientID;
```
<img width="289" height="123" alt="image" src="https://github.com/user-attachments/assets/85b0a234-021a-4af7-87d9-b7b14501e834" />

4.2. Клиенты без платежей
```sql
SELECT ClientID, FirstName, LastName FROM Client
EXCEPT
SELECT DISTINCT m.ClientID, c.FirstName, c.LastName
FROM Membership m
JOIN Payment p ON m.MembershipID = p.MembershipID
JOIN Client c ON m.ClientID = c.ClientID;
```
<img width="302" height="128" alt="image" src="https://github.com/user-attachments/assets/8ba08e19-3da9-4089-8e7e-1f1a7c47bec3" />

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
<img width="332" height="136" alt="image" src="https://github.com/user-attachments/assets/e1beceb3-f56b-48bc-b977-7d1b7bfea6b5" />

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
<img width="706" height="224" alt="image" src="https://github.com/user-attachments/assets/26dc65e2-2557-4610-a845-d3b61b3f2689" />

5.2.  Ранжирование платежей по сумме внутри каждого типа членства
```sql
SELECT 
    m.Type AS membership_type,
    p.Date,
    p.Amount,
    RANK() OVER (PARTITION BY m.Type ORDER BY p.Amount DESC) AS amount_rank
FROM Payment p
JOIN Membership m ON p.MembershipID = m.MembershipID
ORDER BY m.Type, amount_rank;
```
<img width="483" height="281" alt="image" src="https://github.com/user-attachments/assets/ee11c78c-306a-4e75-aad4-1e0f56b67d50" />

6. PARTITION BY + ORDER BY
6.1. Скользящее среднее рейтинга по отзывам
```sql
SELECT 
    r.ReviewID,
    c.FirstName,
    c.LastName,
    r.Rating,
    AVG(r.Rating) OVER (
        ORDER BY r.ReviewID 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_rating
FROM Review r
JOIN Client c ON r.ClientID = c.ClientID
ORDER BY r.ReviewID;
```
<img width="559" height="277" alt="image" src="https://github.com/user-attachments/assets/7d8955d2-efcb-42a1-a35b-483f261a80b4" />

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
<img width="899" height="191" alt="image" src="https://github.com/user-attachments/assets/28eda0d0-65d4-4c0f-b731-a413d2f771c8" />

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
<img width="422" height="275" alt="image" src="https://github.com/user-attachments/assets/e25a3363-ff3a-4e8f-bfac-3361a78d9ca1" />

7.2. Сумма платежей за текущий и предыдущий периоды
```sql
SELECT 
    p.PaymentID,
    p.Date,
    p.Amount,
    SUM(p.Amount) OVER (
        ORDER BY EXTRACT(YEAR FROM p.Date) * 100 + EXTRACT(MONTH FROM p.Date)
        RANGE BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS sum_2_months
FROM Payment p
ORDER BY p.Date;
```
<img width="442" height="278" alt="image" src="https://github.com/user-attachments/assets/890c5f2b-cb03-4a44-8105-ad8e25b920ba" />

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
<img width="337" height="272" alt="image" src="https://github.com/user-attachments/assets/3650347d-9e66-4feb-8d51-354b34e9be47" />

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
<img width="571" height="275" alt="image" src="https://github.com/user-attachments/assets/c81ffd56-3645-4421-819e-0c5574b01f4f" />

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
<img width="413" height="294" alt="image" src="https://github.com/user-attachments/assets/13ebe354-6642-43c3-a81c-e5c34cf785da" />

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
<img width="520" height="247" alt="image" src="https://github.com/user-attachments/assets/0a0a9a02-f89f-4492-b1ec-e3883275857c" />

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
<img width="483" height="120" alt="image" src="https://github.com/user-attachments/assets/30a8405e-8d17-4474-a271-f31dd6fc96dc" />

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
<img width="512" height="300" alt="image" src="https://github.com/user-attachments/assets/67a09072-2e06-48f8-991d-74f2e8194756" />

9.5. PERCENT_RANK - Процентный ранг платежей
```sql
SELECT 
    p.PaymentID,
    p.Amount,
    PERCENT_RANK() OVER (ORDER BY p.Amount) AS percent_rank
FROM Payment p;
```
<img width="391" height="274" alt="image" src="https://github.com/user-attachments/assets/af394e71-c498-4eae-bd22-b946a26bdd9e" />

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
<img width="404" height="86" alt="image" src="https://github.com/user-attachments/assets/f4a32fe8-daa8-481a-9456-6f68178c2e06" />

10. Функции смещения
10.1. LAG - Сравнение опыта инструкторов по специализациям
```sql
SELECT 
    s.FirstName,
    s.LastName,
    i.Specialty,
    i.ExperienceYears,
    LAG(i.ExperienceYears) OVER (
        PARTITION BY i.Specialty 
        ORDER BY i.ExperienceYears DESC
    ) AS previous_instructor_exp
FROM Instructor i
JOIN Staff s ON i.StaffID = s.StaffID
ORDER BY i.Specialty, i.ExperienceYears DESC;
```
<img width="742" height="191" alt="image" src="https://github.com/user-attachments/assets/e6aa32a1-00cf-4109-9fb8-91fcc141461c" />

10.2. LEAD - Следующий класс в расписании помещения
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
<img width="885" height="387" alt="image" src="https://github.com/user-attachments/assets/150ebc12-7bd7-4f04-a84d-1d5707323b4f" />

10.3. FIRST_VALUE - Первый платеж по каждому членству
```sql
SELECT 
    m.MembershipID,
    p.Date,
    p.Amount,
    FIRST_VALUE(p.Amount) OVER (
        PARTITION BY p.MembershipID 
        ORDER BY p.Date
    ) AS first_payment_amount,
    FIRST_VALUE(p.Date) OVER (
        PARTITION BY p.MembershipID 
        ORDER BY p.Date
    ) AS first_payment_date
FROM Payment p
JOIN Membership m ON p.MembershipID = m.MembershipID
ORDER BY m.MembershipID, p.Date;
```
<img width="725" height="275" alt="image" src="https://github.com/user-attachments/assets/009e8cb6-40e1-45ab-8b27-9388e9cae07e" />

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
<img width="1089" height="378" alt="image" src="https://github.com/user-attachments/assets/a81c276b-cb03-4f67-a053-3ca078d51977" />
