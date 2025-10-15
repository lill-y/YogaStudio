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
![telegram-cloud-photo-size-2-5438300840625568662-y](https://github.com/user-attachments/assets/6a527eff-a6fc-446d-a13f-aef7a25890f8)

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
<img width="439" height="105" alt="image" src="https://github.com/user-attachments/assets/27ea5de4-0c03-4a1d-b9b1-463ccbd211d8" />

### 3.2. Получить расписание с понятными названиями и временем
```sql
SELECT 
    DayOfWeek AS День_недели,
    StartTime AS Начало,
    EndTime AS Окончание
FROM Schedule;
```
<img width="325" height="109" alt="image" src="https://github.com/user-attachments/assets/9e35126a-e2a3-49cb-a9cb-0b017a495cfc" />

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
<img width="609" height="72" alt="image" src="https://github.com/user-attachments/assets/9c2c09a8-13f1-4d4e-82c3-1074e6185fed" />

### 4.2. Рассчитать общую выручку по платежам

```sql
SELECT 
    SUM(Amount) AS TotalRevenue
FROM Payment;
```
<img width="135" height="77" alt="image" src="https://github.com/user-attachments/assets/5522e813-5e4c-4466-9b0d-cd04b27fa36b" />

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
<img width="536" height="102" alt="image" src="https://github.com/user-attachments/assets/7940bef9-b64b-4097-ae56-cc42f2bd593e" />

### 5.2. Рассчитать бонусы для инструкторов на основе опыта
```sql
SELECT 
    InstructorID,
    ExperienceYears,
    ExperienceYears * 1000 AS ExperienceBonus
FROM Instructor;
```
<img width="443" height="107" alt="image" src="https://github.com/user-attachments/assets/a115fea4-adb9-4f8b-8bfa-5c739005bf5b" />

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
<img width="583" height="88" alt="image" src="https://github.com/user-attachments/assets/81f74be2-7067-4a7f-9925-b901ed968b99" />

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
<img width="447" height="106" alt="image" src="https://github.com/user-attachments/assets/9bb1dd70-223b-4eb2-b6f0-c63875376d0a" />

## 7. Выборка данных по условию 

### 7.1. Найти активные членства
```sql
SELECT * FROM Membership 
WHERE Status = 'active';
```
<img width="628" height="70" alt="image" src="https://github.com/user-attachments/assets/6bb75b85-e953-4b52-952f-368744c67272" />

### 7.2. Найти инструкторов со специальностью в хатха йога
```sql
SELECT * FROM Instructor 
WHERE specialty LIKE 'Hatha Yoga';
```
<img width="627" height="93" alt="image" src="https://github.com/user-attachments/assets/e49b0262-1a63-4874-b14d-49a1c1140c0d" />

## 8. Найти всех адммином с фамилией на B

### 8.1. 
```sql
SELECT * FROM Staff 
WHERE LastName LIKE 'B%' AND Role = 'Admin';
```
<img width="620" height="76" alt="image" src="https://github.com/user-attachments/assets/59cf6900-9cce-4abc-bba7-7b1ec77d3462" />

### 8.2. Найти помещения на 1 этаже с вместимостью более 15 человек
```sql
SELECT * FROM Room 
WHERE Floor = 1 AND Capacity > 15;
```
<img width="422" height="73" alt="image" src="https://github.com/user-attachments/assets/88c6fde1-0262-453a-8cd1-e86df5c19cfc" />

## 9. Выборка данных, операторы BETWEEN, IN

### 9.1. Найти платежи за последний месяц
```sql
SELECT * FROM Payment 
WHERE Date BETWEEN CURRENT_DATE - INTERVAL '1 month' AND CURRENT_DATE;
```
<img width="443" height="71" alt="image" src="https://github.com/user-attachments/assets/e6103a06-5309-4ab9-bc72-09fc396cbb5b" />

### 9.2. Найти инструкторов с определенными специализациями
```sql
SELECT * FROM Instructor 
WHERE Specialty IN ('Hatha Yoga', 'Vinyasa Yoga');
```
<img width="638" height="108" alt="image" src="https://github.com/user-attachments/assets/1ddcf07c-3361-4171-bc15-c4dc23b5dce7" />

## 10. Выборка данных с сортировкой

### 10.1. Отсортировать клиентов по фамилии
```sql
SELECT * FROM Client 
ORDER BY LastName ASC;
```
<img width="687" height="108" alt="image" src="https://github.com/user-attachments/assets/ad07e89d-f7d9-4d82-8e10-e326eedecb8c" />

### 10.2. Отсортировать отзывы по рейтингу (от высокого к низкому)
```sql
SELECT * FROM Review 
ORDER BY Rating DESC;
```
<img width="473" height="110" alt="image" src="https://github.com/user-attachments/assets/48003fe8-66d1-4aed-ba89-56824cb40184" />

## 11. Выборка данных, оператор LIKE

### 11.1. Найти клиентов с фамилией, начинающейся на "S"
```sql
SELECT * FROM Client 
WHERE LastName LIKE 'S%';
```
<img width="697" height="76" alt="image" src="https://github.com/user-attachments/assets/93873ba7-4b0a-4129-8838-0d96a3e201b8" />

### 11.2. Найти классы с названием, содержащим "Weekend"
```sql
SELECT * FROM Class 
WHERE Name LIKE '%Weekend%';
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
