# SELECT запросы

## 1. Выборка всех данных из таблицы

### 1.1. Получить все данные о студиях йоги
```sql
SELECT * FROM YogaStudio;
```
![telegram-cloud-photo-size-2-5438300840625568654-y](https://github.com/user-attachments/assets/70eda30b-d33c-4321-8f1c-675717c05a51)

### 1.2. Получить все данные о клиентах
```sql
SELECT * FROM Client;
```
![telegram-cloud-photo-size-2-5438300840625568659-y](https://github.com/user-attachments/assets/1097b604-506f-46c4-ab39-73f3deee5afd)

## 2. Выборка отдельных столбцов

### 2.1. Получить имена и телефоны сотрудников
```sql
SELECT FirstName, LastName, Phone FROM Staff;
```
![telegram-cloud-photo-size-2-5438300840625568660-y](https://github.com/user-attachments/assets/ef4f12e7-ecb7-48d1-91b8-a1eeb7a2bc16)

### 2.2. Получить названия классов и их максимальную вместимость
```sql
SELECT Name, MaxCapacity FROM Class;
```

## 3. Присвоение новых имен столбцам при формировании выборки

### 3.1. Получить информацию о клиентах с русскими названиями столбцов
```sql
SELECT 
    FirstName AS Имя,
    LastName AS Фамилия,
    Phone AS Телефон,
    DateOfBirth AS Дата_рождения
FROM Client;
```

### 3.2. Получить расписание с понятными названиями и временем
```sql
SELECT 
    DayOfWeek AS День_недели,
    StartTime AS Начало,
    EndTime AS Окончание
FROM Schedule;
```

## 4. Рассчитать, сколько дней осталось до окончания действия абонемента

### 4.1. 
```sql
SELECT 
    MembershipID,
    Type,
    StartDate,
    EndDate,
    (EndDate - CURRENT_DATE) AS DaysUntilExpiry
FROM Membership
WHERE Status = 'active';
```

### 4.2. Рассчитать общую выручку по платежам

```sql
SELECT 
    SUM(Amount) AS TotalRevenue
FROM Payment;
```

## 5. Выборка данных, вычисляемые столбцы, математические функции

### 5.1. Рассчитать предполагаемый доход от класса при полной заполняемости
```sql
SELECT 
    ClassID,
    Name,
    MaxCapacity,
    (MaxCapacity * 500) AS PotentialRevenue
FROM Class;
```

### 5.2. Рассчитать бонусы для инструкторов на основе опыта
```sql
SELECT 
    InstructorID,
    ExperienceYears,
    ExperienceYears * 1000 AS ExperienceBonus
FROM Instructor;
```

## 6. Выборка данных, вычисляемые столбцы, логические функции 

### 6.1. Определить статус членства клиента
```sql
SELECT 
    ClientID,
    Type,
    StartDate,
    EndDate,
    CASE 
        WHEN Status = 'active' AND EndDate >= CURRENT_DATE THEN 'Действителен'
        ELSE 'Недействителен'
    END AS MembershipStatus
FROM Membership;
```

### 6.2. Классифицировать инструкторов по опыту работы
```sql
SELECT 
    InstructorID,
    ExperienceYears,
    CASE 
        WHEN ExperienceYears < 2 THEN 'Начинающий'
        WHEN ExperienceYears BETWEEN 2 AND 5 THEN 'Опытный'
        ELSE 'Эксперт'
    END AS ExperienceLevel
FROM Instructor;
```

## 7. Выборка данных по условию 

### 7.1. Найти активные членства
```sql
SELECT * FROM Membership 
WHERE Status = 'active';
```

### 7.2. Найти инструкторов с сертификацией по йога-терапии
```sql
SELECT * FROM Instructor 
WHERE Certifications LIKE '%йога-терапия%';
```

## 8. Выборка данных, логические операции

### 8.1. 
```sql

```

### 8.2. Найти помещения на 1 этаже с вместимостью более 15 человек
```sql
SELECT * FROM Room 
WHERE Floor = 1 AND Capacity > 15;
```

## 9. Выборка данных, операторы BETWEEN, IN

### 9.1. Найти платежи за последний месяц
```sql
SELECT * FROM Payment 
WHERE Date BETWEEN CURRENT_DATE - INTERVAL '1 month' AND CURRENT_DATE;
```

### 9.2. Найти инструкторов с определенными специализациями
```sql
SELECT * FROM Instructor 
WHERE Specialty IN ('Hatha Yoga', 'Vinyasa Yoga');
```

## 10. Выборка данных с сортировкой

### 10.1. Отсортировать клиентов по фамилии
```sql
SELECT * FROM Client 
ORDER BY LastName ASC;
```

### 10.2. Отсортировать отзывы по рейтингу (от высокого к низкому)
```sql
SELECT * FROM Review 
ORDER BY Rating DESC;
```

## 11. Выборка данных, оператор LIKE

### 11.1. Найти клиентов с фамилией, начинающейся на "S"
```sql
SELECT * FROM Client 
WHERE LastName LIKE 'S%';
```

### 11.2. Найти классы с названием, содержащим "Yoga"
```sql
SELECT * FROM Class 
WHERE Name LIKE '%Yoga%';
```

## 12. Выбор уникальных элементов столбца

### 12.1. Получить уникальные роли сотрудников
```sql
SELECT DISTINCT Role FROM Staff;
```

### 12.2. Получить уникальные типы членств
```sql
SELECT DISTINCT Type FROM Membership;
```

## 13. Выбор ограниченного количества возвращаемых строк

### 13.1. Получить 2 последних платежа
```sql
SELECT * FROM Payment 
ORDER BY Date DESC 
LIMIT 2;
```
### 13.2. Получить самого опытного инструктора
```sql
SELECT * FROM Instructor 
ORDER BY ExperienceYears DESC 
LIMIT 1;
```

# JOIN запросы

## 14. Соединение INNER JOIN

### 14.1. Классификация книг по цене
```sql

```

### 14.2. Классификация книг по цене
```sql

```

## 15. Внешнее соединение LEFT и RIGHT OUTER JOIN

### 15.1. Классификация книг по цене
```sql

```

### 15.2. Классификация книг по цене
```sql

```

## 16. Перекрестное соединение CROSS JOIN

### 16.1. Классификация книг по цене
```sql

```

### 16.2. Классификация книг по цене
```sql

```

## 17. Запросы на выборку из нескольких таблиц

### 17.1. Классификация книг по цене
```sql

```

### 17.2. Классификация книг по цене
```sql
