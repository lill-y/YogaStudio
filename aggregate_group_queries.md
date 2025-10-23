# Агрегатные функции и операторы GROUP BY, HAVING

## 1. Avg

### 1.1. Рассчитать средний рейтинг всех отзывов
```sql
SELECT AVG(Rating) AS AverageRating
FROM Review;
```
<img width="181" height="75" alt="image" src="https://github.com/user-attachments/assets/cf50fc91-7d77-4aad-8f86-38907f049a8a" />

### 1.2. Рассчитать средний опыт работы инструкторов по специализациям
```sql
SELECT Specialty, AVG(ExperienceYears) AS AvgExperience
FROM Instructor
GROUP BY Specialty;
```
<img width="334" height="115" alt="image" src="https://github.com/user-attachments/assets/9d8f1df5-cc24-4ec4-960e-05a951420cf9" />

## 2. Count

### 2.1. Посчитать общее количество клиентов
```sql
SELECT COUNT(*) AS TotalClients
FROM Client;
```
<img width="132" height="78" alt="image" src="https://github.com/user-attachments/assets/66cf0688-fac0-44ef-b45a-153d8fed527a" />

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
<img width="351" height="122" alt="image" src="https://github.com/user-attachments/assets/73e4a564-ea41-4f71-a9c9-94d4eb5e129e" />


## 3. Min и Max

### 3.1. Найти самый старый и самый молодой возраст клиентов
```sql
SELECT 
    MIN(EXTRACT(YEAR FROM AGE(CURRENT_DATE, DateOfBirth))) AS MinAge,
    MAX(EXTRACT(YEAR FROM AGE(CURRENT_DATE, DateOfBirth))) AS MaxAge
FROM Client;
```
<img width="152" height="75" alt="image" src="https://github.com/user-attachments/assets/d564915d-b358-4d16-8d71-615d9de23198" />


### 3.2. Найти самый дорогой и самый дешевый платеж
```sql
SELECT 
    MIN(p.Amount) AS MinPayment,
    MAX(p.Amount) AS MaxPayment
FROM Payment p;
```
<img width="222" height="70" alt="image" src="https://github.com/user-attachments/assets/0fa3539d-214c-4185-85ce-9272e8eb9e3e" />

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
<img width="278" height="176" alt="image" src="https://github.com/user-attachments/assets/c05f5092-166b-4f10-861f-ff20bc88770f" />


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
<img width="445" height="118" alt="image" src="https://github.com/user-attachments/assets/79f0d805-31b3-4123-a9c9-7ba733e22ed6" />


### 5.2. Дни недели занятий по классам
```sql
SELECT
    c.Name AS class,
    STRING_AGG(sch.DayOfWeek, ', ') AS days
FROM Class c
JOIN Schedule sch ON c.ScheduleID = sch.ScheduleID
GROUP BY c.Name;
```
<img width="410" height="262" alt="image" src="https://github.com/user-attachments/assets/ebe5951a-f6bc-46f1-97c5-9f15d318c602" />

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
<img width="571" height="79" alt="image" src="https://github.com/user-attachments/assets/b2664eb4-390a-4775-a65f-117dc1ed6d69" />

### 6.2. Статистика по отзывам: количество, средний рейтинг, минимальный и максимальный
```sql
SELECT 
    COUNT(*) AS TotalReviews,
    AVG(Rating) AS AvgRating,
    MIN(Rating) AS MinRating,
    MAX(Rating) AS MaxRating
FROM Review;
```
<img width="523" height="72" alt="image" src="https://github.com/user-attachments/assets/bb81afb6-ac70-41a3-af8e-c6faec895ef3" />

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
<img width="297" height="107" alt="image" src="https://github.com/user-attachments/assets/c4d22f71-0f62-4a7c-bbbe-2133368a6ffe" />

### 7.2. Классы по инструкторам
```sql
SELECT
    s.FirstName || ' ' || s.LastName AS instructor,
    COUNT(cl.ClassID) AS classes
FROM Instructor i
JOIN Staff s ON i.StaffID = s.StaffID
JOIN Class cl ON i.InstructorID = cl.InstructorID
GROUP BY s.FirstName, s.LastName;
```
<img width="220" height="134" alt="image" src="https://github.com/user-attachments/assets/623b939a-d423-4e38-9b27-f8c3f47e46db" />

## 8. HAVING

### 8.1. Найти студии с более чем 5 клиентами
```sql
SELECT 
    ys.Name AS StudioName,
    COUNT(c.ClientID) AS ClientCount
FROM YogaStudio ys
JOIN Client c ON ys.YogaStudioID = c.YogaStudioID
GROUP BY ys.Name
HAVING COUNT(c.ClientID) > 5;
```
<img width="296" height="71" alt="image" src="https://github.com/user-attachments/assets/fa6cc01f-d6fa-4ce8-ba60-f91ab62a7911" />

### 8.2. Найти абонементы с рейтингом больше 4
```sql
SELECT 
    m.Type AS MembershipType,
    AVG(r.Rating) AS AvgMembershipRating
FROM Membership m
JOIN Client cl ON m.ClientID = cl.ClientID
JOIN Review r ON cl.ClientID = r.ClientID
GROUP BY m.Type
HAVING AVG(r.Rating) > 4.0;
```
<img width="337" height="75" alt="image" src="https://github.com/user-attachments/assets/3f0ec773-c0a9-4663-a323-253513391908" />

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
<img width="330" height="193" alt="image" src="https://github.com/user-attachments/assets/94113efd-c599-42ba-87d0-0dde627a584d" />


### 9.2. Анализ отзывов по рейтингам и студиям
```sql
SELECT
    r.Rating,
    ys.Name,
    COUNT(r.ReviewID) AS review_count
FROM Review r
JOIN Client c ON r.ClientID = c.ClientID
JOIN YogaStudio ys ON c.YogaStudioID = ys.YogaStudioID
GROUP BY GROUPING SETS ((r.Rating, ys.Name), (r.Rating), (ys.Name), ());
```
<img width="381" height="264" alt="image" src="https://github.com/user-attachments/assets/812ffcbc-09da-4bcd-887d-2ba89a40c337" />

## 10. ROLLUP

### 10.1. Клиенты по студиям и годам рождения
```sql
SELECT
    ys.Name,
    EXTRACT(YEAR FROM c.DateOfBirth) AS birth_year,
    COUNT(c.ClientID) AS client_count
FROM Client c
JOIN YogaStudio ys ON c.YogaStudioID = ys.YogaStudioID
GROUP BY ROLLUP (ys.Name, EXTRACT(YEAR FROM c.DateOfBirth));
```
<img width="409" height="370" alt="image" src="https://github.com/user-attachments/assets/e4497e79-0abb-4edc-9b4c-9c0d757a59e1" />


### 10.2. Платежи по студиям и месяцам
```sql
SELECT
    ys.Name,
    EXTRACT(MONTH FROM p.Date) AS month,
    SUM(p.Amount) AS total_amount
FROM Payment p
JOIN Membership m ON p.MembershipID = m.MembershipID
JOIN Client c ON m.ClientID = c.ClientID
JOIN YogaStudio ys ON c.YogaStudioID = ys.YogaStudioID
GROUP BY ROLLUP (ys.Name, EXTRACT(MONTH FROM p.Date));
```
<img width="393" height="275" alt="image" src="https://github.com/user-attachments/assets/3706ae63-4c57-4951-9459-d23da3b06fbb" />

## 11. CUBE

### 11.1. Анализ классов по инструкторам и помещениям
```sql
SELECT
    s.FirstName || ' ' || s.LastName AS instructor,
    r.Name AS room,
    COUNT(c.ClassID) AS class_count
FROM Class c
JOIN Instructor i ON c.InstructorID = i.InstructorID
JOIN Staff s ON i.StaffID = s.StaffID
JOIN Room r ON c.RoomID = r.RoomID
GROUP BY CUBE (instructor, room);
```
<img width="388" height="377" alt="image" src="https://github.com/user-attachments/assets/a160be21-ac96-4f12-b1fb-f04d80953d6b" />


### 11.2. Анализ членств по типам и статусам
```sql
SELECT
    m.Type,
    m.Status,
    COUNT(m.MembershipID) AS membership_count
FROM Membership m
GROUP BY CUBE (m.Type, m.Status);
```
<img width="343" height="210" alt="image" src="https://github.com/user-attachments/assets/d8362974-9863-42fe-be23-0f39d8a6c49e" />


