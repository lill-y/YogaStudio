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
<img width="674" height="74" alt="image" src="https://github.com/user-attachments/assets/3c572a67-7b0c-4a41-a52f-a5e42e5aacd1" />

## 12. Выбор уникальных элементов столбца

### 12.1. Получить уникальные роли сотрудников
```sql
SELECT DISTINCT Role FROM Staff;
```
<img width="107" height="92" alt="image" src="https://github.com/user-attachments/assets/92b22827-d8a1-4260-a264-51b9acfeb972" />

### 12.2. Получить уникальные типы членств
```sql
SELECT DISTINCT Type FROM Membership;
```
<img width="87" height="92" alt="image" src="https://github.com/user-attachments/assets/3a0c3cee-250d-44eb-b4c9-c09b2b60ef80" />

## 13. Выбор ограниченного количества возвращаемых строк

### 13.1. Получить 2 последних платежа
```sql
SELECT * FROM Payment 
ORDER BY Date DESC 
LIMIT 2;
```
<img width="439" height="91" alt="image" src="https://github.com/user-attachments/assets/77fc0764-92a9-4ada-a823-6c505d4bfc45" />

### 13.2. Получить самого опытного инструктора
```sql
SELECT * FROM Instructor 
ORDER BY ExperienceYears DESC 
LIMIT 1;
```
<img width="631" height="71" alt="image" src="https://github.com/user-attachments/assets/36469ce9-ff65-4083-9b67-b23464449194" />

# JOIN запросы

## 14. Соединение INNER JOIN

### 14.1. Получить информацию о классах с именами инструкторов и названиями комнат
```sql
SELECT 
    c.ClassID,
    c.Name AS ClassName,
    s.FirstName,
    s.LastName,
    r.Name AS RoomName
FROM Class c
INNER JOIN Instructor i ON c.InstructorID = i.InstructorID
INNER JOIN Staff s ON i.StaffID = s.StaffID
INNER JOIN Room r ON c.RoomID = r.RoomID;
```
<img width="575" height="110" alt="image" src="https://github.com/user-attachments/assets/5d75a007-caa9-4065-956f-93a77e7fbde8" />

### 14.2. Получить клиентов с их платежами и типами членств
```sql
SELECT 
    cl.FirstName,
    cl.LastName,
    m.Type AS MembershipType,
    p.Amount,
    p.Date
FROM Client cl
INNER JOIN Membership m ON cl.ClientID = m.ClientID
INNER JOIN Payment p ON m.MembershipID = p.MembershipID;
```
<img width="568" height="109" alt="image" src="https://github.com/user-attachments/assets/f87e98f6-02d8-4e6e-b919-7fb8e8d98ad5" />

## 15. Внешнее соединение LEFT и RIGHT OUTER JOIN

### 15.1. Получить всех клиентов и их отзывы (включая клиентов без отзывов)
```sql
SELECT 
    c.FirstName,
    c.LastName,
    r.Rating,
    r.Comment
FROM Client c
LEFT OUTER JOIN Review r ON c.ClientID = r.ClientID;
```
(тут специально добавила нового клиента для наглядности)
<img width="483" height="124" alt="image" src="https://github.com/user-attachments/assets/a16c2152-741e-4b36-a57f-f43be3fe74ec" />

### 15.2. Получить всех инструкторов и их классы (включая инструкторов без классов)
```sql
SELECT 
    s.FirstName,
    s.LastName,
    i.Specialty,
    c.Name AS ClassName
FROM Instructor i
LEFT OUTER JOIN Class c ON i.InstructorID = c.InstructorID
INNER JOIN Staff s ON i.StaffID = s.StaffID;
```
<img width="515" height="133" alt="image" src="https://github.com/user-attachments/assets/426bd376-8689-4395-8c12-2d219ab76c18" />

## 16. Перекрестное соединение CROSS JOIN

### 16.1. Создать все возможные комбинации типов классов и дней недели для планирования
```sql
SELECT 
    c.Name AS ClassType,
    s.DayOfWeek
FROM Class c
CROSS JOIN Schedule s;
```
<img width="265" height="258" alt="image" src="https://github.com/user-attachments/assets/ce82df99-599f-4e13-821a-f6ef2e033a4a" />

### 16.2. Создать матрицу всех инструкторов и студий для возможного распределения
```sql
SELECT 
    s.FirstName,
    s.LastName,
    y.Name AS StudioName
FROM Instructor i
CROSS JOIN YogaStudio y
JOIN Staff s ON i.StaffID = s.StaffID;
```
<img width="391" height="208" alt="image" src="https://github.com/user-attachments/assets/b5a9c6ad-9b40-45a0-b0cc-e9b7a615875d" />

## 17. Запросы на выборку из нескольких таблиц

### 17.1. Получить полное соответствие между клиентами и отзывами
```sql
SELECT 
    c.FirstName,
    c.LastName,
    r.Rating,
    r.Comment
FROM Client c
FULL OUTER JOIN Review r ON c.ClientID = r.ClientID;
```
<img width="483" height="130" alt="image" src="https://github.com/user-attachments/assets/bbf32c0a-fda5-4970-9fe1-76c1e8df7958" />


### 17.2. Получить все классы и все расписания (полное соответствие)
```sql
SELECT 
    c.Name AS ClassName,
    s.DayOfWeek,
    s.StartTime
FROM Class c
FULL OUTER JOIN Schedule s ON c.ScheduleID = s.ScheduleID;
```
<img width="384" height="117" alt="image" src="https://github.com/user-attachments/assets/009f7fcc-b453-4159-a61e-71237a8b446a" />

