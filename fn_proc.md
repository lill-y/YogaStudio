# Хранимые процедуры и функции
## Процедуры
1. Процедура добавления нового клиента
```sql
CREATE OR REPLACE PROCEDURE add_new_client(
    p_firstname VARCHAR(50),
    p_lastname VARCHAR(50),
    p_phone VARCHAR(20),
    p_studio_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO Client (FirstName, LastName, Phone, YogaStudioID)
    VALUES (p_firstname, p_lastname, p_phone, p_studio_id);
    
    RAISE NOTICE 'Клиент % % успешно добавлен в студию ID %', 
        p_firstname, p_lastname, p_studio_id;
END;
$$;
```
2. Процедура обновления статуса членства
```sql
CREATE OR REPLACE PROCEDURE update_membership_status(
    p_membership_id INT,
    p_new_status VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Membership 
    SET Status = p_new_status 
    WHERE MembershipID = p_membership_id;
    
    IF FOUND THEN
        RAISE NOTICE 'Статус членства % обновлен на %', 
            p_membership_id, p_new_status;
    ELSE
        RAISE NOTICE 'Членство с ID % не найдено', p_membership_id;
    END IF;
END;
$$;
```
3. Процедура переноса клиента в другую студию
```sql
CREATE OR REPLACE PROCEDURE transfer_client_to_studio(
    p_client_id INT,
    p_new_studio_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    old_studio_name VARCHAR(100);
    new_studio_name VARCHAR(100);
BEGIN
    -- Получаем названия студий
    SELECT Name INTO old_studio_name 
    FROM YogaStudio ys 
    JOIN Client c ON ys.YogaStudioID = c.YogaStudioID 
    WHERE c.ClientID = p_client_id;
    
    SELECT Name INTO new_studio_name 
    FROM YogaStudio 
    WHERE YogaStudioID = p_new_studio_id;
    
    -- Обновляем студию клиента
    UPDATE Client 
    SET YogaStudioID = p_new_studio_id 
    WHERE ClientID = p_client_id;
    
    RAISE NOTICE 'Клиент % перенесен из студии "%" в студию "%"', 
        p_client_id, old_studio_name, new_studio_name;
END;
$$;
```
### Запрос просмотра всех процедур
```sql
SELECT 
    routine_name as procedure_name,
    routine_definition as definition
FROM information_schema.routines 
WHERE routine_type = 'PROCEDURE' 
AND specific_schema = 'public'
ORDER BY routine_name;
```
## Функции
1. Функция расчета среднего рейтинга клиента
sql
CREATE OR REPLACE FUNCTION get_client_avg_rating(p_client_id INT)
RETURNS DECIMAL(3,2)
LANGUAGE plpgsql
AS $$
DECLARE
    avg_rating DECIMAL(3,2);
BEGIN
    SELECT AVG(Rating) INTO avg_rating
    FROM Review 
    WHERE ClientID = p_client_id;
    
    RETURN COALESCE(avg_rating, 0);
END;
$$;
```
2. Функция подсчета клиентов в студии
```sql
CREATE OR REPLACE FUNCTION count_clients_in_studio(p_studio_id INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    client_count INT;
BEGIN
    SELECT COUNT(*) INTO client_count
    FROM Client 
    WHERE YogaStudioID = p_studio_id;
    
    RETURN client_count;
END;
$$;
```
3. Функция проверки активного членства
```sql
CREATE OR REPLACE FUNCTION is_active_membership(p_client_id INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    active_count INT;
BEGIN
    SELECT COUNT(*) INTO active_count
    FROM Membership 
    WHERE ClientID = p_client_id 
    AND Status = 'active' 
    AND EndDate >= CURRENT_DATE;
    
    RETURN active_count > 0;
END;
$$;
```
## Функции с переменными
1. Функция с переменными - информация о клиенте
```sql
CREATE OR REPLACE FUNCTION get_client_info(p_client_id INT)
RETURNS TABLE(
    client_name VARCHAR(100),
    studio_name VARCHAR(100),
    membership_type VARCHAR(50),
    avg_rating DECIMAL(3,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.FirstName || ' ' || c.LastName as client_name,
        ys.Name as studio_name,
        m.Type as membership_type,
        COALESCE(AVG(r.Rating), 0) as avg_rating
    FROM Client c
    LEFT JOIN YogaStudio ys ON c.YogaStudioID = ys.YogaStudioID
    LEFT JOIN Membership m ON c.ClientID = m.ClientID AND m.Status = 'active'
    LEFT JOIN Review r ON c.ClientID = r.ClientID
    WHERE c.ClientID = p_client_id
    GROUP BY c.ClientID, c.FirstName, c.LastName, ys.Name, m.Type;
END;
$$;
```
2. Функция с переменными - статистика студии
```sql
CREATE OR REPLACE FUNCTION get_studio_stats(p_studio_id INT)
RETURNS TABLE(
    total_clients INT,
    total_instructors INT,
    total_classes INT,
    avg_rating DECIMAL(3,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT c.ClientID) as total_clients,
        COUNT(DISTINCT s.StaffID) as total_instructors,
        COUNT(DISTINCT cl.ClassID) as total_classes,
        COALESCE(AVG(r.Rating), 0) as avg_rating
    FROM YogaStudio ys
    LEFT JOIN Client c ON ys.YogaStudioID = c.YogaStudioID
    LEFT JOIN Staff s ON ys.YogaStudioID = s.YogaStudioID AND s.Role = 'Инструктор'
    LEFT JOIN Class cl ON ys.YogaStudioID = (SELECT YogaStudioID FROM Room WHERE RoomID = cl.RoomID)
    LEFT JOIN Review r ON c.ClientID = r.ClientID
    WHERE ys.YogaStudioID = p_studio_id
    GROUP BY ys.YogaStudioID;
END;
$$;
```
3. Функция с переменными - финансовый отчет
```sql
CREATE OR REPLACE FUNCTION get_financial_report(p_year INT)
RETURNS TABLE(
    month INT,
    month_name TEXT,
    total_income DECIMAL(10,2),
    payment_count INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        EXTRACT(MONTH FROM p.Date) as month,
        CASE EXTRACT(MONTH FROM p.Date)
            WHEN 1 THEN 'Январь'
            WHEN 2 THEN 'Февраль'
            WHEN 3 THEN 'Март'
            WHEN 4 THEN 'Апрель'
            WHEN 5 THEN 'Май'
            WHEN 6 THEN 'Июнь'
            WHEN 7 THEN 'Июль'
            WHEN 8 THEN 'Август'
            WHEN 9 THEN 'Сентябрь'
            WHEN 10 THEN 'Октябрь'
            WHEN 11 THEN 'Ноябрь'
            WHEN 12 THEN 'Декабрь'
        END as month_name,
        SUM(p.Amount) as total_income,
        COUNT(p.PaymentID) as payment_count
    FROM Payment p
    WHERE EXTRACT(YEAR FROM p.Date) = p_year
    GROUP BY EXTRACT(MONTH FROM p.Date)
    ORDER BY month;
END;
$$;
```
### Запрос просмотра всех функций
```sql
SELECT 
    routine_name as function_name,
    routine_definition as definition
FROM information_schema.routines 
WHERE routine_type = 'FUNCTION' 
AND specific_schema = 'public'
ORDER BY routine_name;
```
## Блок DO
1. DO блок для массового обновления
```sql
DO $$
DECLARE
    updated_count INT;
BEGIN
    UPDATE Membership 
    SET Status = 'inactive' 
    WHERE EndDate < CURRENT_DATE 
    AND Status = 'active';
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    RAISE NOTICE 'Обновлено % просроченных членств', updated_count;
END $$;
```
2. DO блок для генерации тестовых данных
```sql
DO $$
BEGIN
    -- Добавляем тестовые отзывы для клиентов без отзывов
    INSERT INTO Review (ReviewID, ClientID, Rating, Comment)
    SELECT 
        (SELECT COALESCE(MAX(ReviewID), 0) FROM Review) + row_number() over (),
        c.ClientID,
        4,
        'Автоматически сгенерированный отзыв'
    FROM Client c
    WHERE NOT EXISTS (
        SELECT 1 FROM Review r WHERE r.ClientID = c.ClientID
    )
    LIMIT 5;
    
    RAISE NOTICE 'Добавлены тестовые отзывы для клиентов без отзывов';
END $$;
```
3. DO блок для анализа данных
```sql
DO $$
DECLARE
    total_clients INT;
    active_memberships INT;
    avg_rating DECIMAL(3,2);
BEGIN
    SELECT COUNT(*) INTO total_clients FROM Client;
    SELECT COUNT(*) INTO active_memberships FROM Membership WHERE Status = 'active';
    SELECT AVG(Rating) INTO avg_rating FROM Review;
    
    RAISE NOTICE 'Статистика йога-центра:';
    RAISE NOTICE 'Всего клиентов: %', total_clients;
    RAISE NOTICE 'Активных членств: %', active_memberships;
    RAISE NOTICE 'Средний рейтинг: %', COALESCE(avg_rating, 0);
END $$;
```
## IF
1. Блок с условиями IF
```sql
DO $$
DECLARE
    client_count INT;
    studio_name VARCHAR(100);
BEGIN
    SELECT Name INTO studio_name FROM YogaStudio WHERE YogaStudioID = 1;
    SELECT COUNT(*) INTO client_count FROM Client WHERE YogaStudioID = 1;
    
    IF client_count = 0 THEN
        RAISE NOTICE 'В студии "%" нет клиентов', studio_name;
    ELSIF client_count < 5 THEN
        RAISE NOTICE 'В студии "%" мало клиентов: %', studio_name, client_count;
    ELSIF client_count < 10 THEN
        RAISE NOTICE 'В студии "%" среднее количество клиентов: %', studio_name, client_count;
    ELSE
        RAISE NOTICE 'В студии "%" много клиентов: %', studio_name, client_count;
    END IF;
END $$;
```
## CASE
1. Блок с CASE
```sql
DO $$
DECLARE
    instructor_name TEXT;
    experience_level TEXT;
    instructor_record RECORD;
BEGIN
    FOR instructor_record IN 
        SELECT s.FirstName, s.LastName, i.ExperienceYears
        FROM Instructor i
        JOIN Staff s ON i.StaffID = s.StaffID
    LOOP
        experience_level := CASE 
            WHEN instructor_record.ExperienceYears < 2 THEN 'Начинающий'
            WHEN instructor_record.ExperienceYears BETWEEN 2 AND 5 THEN 'Опытный'
            WHEN instructor_record.ExperienceYears BETWEEN 6 AND 10 THEN 'Профессионал'
            ELSE 'Эксперт'
        END;
        
        RAISE NOTICE 'Инструктор % %: % лет опыта (% уровень)',
            instructor_record.FirstName,
            instructor_record.LastName,
            instructor_record.ExperienceYears,
            experience_level;
    END LOOP;
END $$;
```
## WHILE
1. WHILE цикл для создания тестовых платежей
```sql
DO $$
DECLARE
    i INT := 1;
    max_id INT;
BEGIN
    SELECT COALESCE(MAX(PaymentID), 0) INTO max_id FROM Payment;
    
    WHILE i <= 3 LOOP
        INSERT INTO Payment (PaymentID, MembershipID, Date, Amount)
        VALUES (max_id + i, 1, CURRENT_DATE - (i * 30), 5000.00 + (i * 1000));
        
        i := i + 1;
    END LOOP;
    
    RAISE NOTICE 'Добавлено % тестовых платежей', i - 1;
END $$;
```
2. WHILE цикл с условием
```sql
DO $$
DECLARE
    counter INT := 1;
    total_instructors INT;
BEGIN
    SELECT COUNT(*) INTO total_instructors FROM Instructor;
    
    WHILE counter <= total_instructors LOOP
        RAISE NOTICE 'Обработка инструктора % из %', counter, total_instructors;
        
        -- Имитация обработки
        PERFORM pg_sleep(0.1);
        
        counter := counter + 1;
    END LOOP;
    
    RAISE NOTICE 'Обработка всех инструкторов завершена';
END $$;
```
## EXCEPTION
1. Обработка исключения при дубликате
```sql
DO $$
BEGIN
    BEGIN
        INSERT INTO Client (ClientID, FirstName, LastName, YogaStudioID)
        VALUES (1, 'Дубликат', 'Тест', 1);
        
        RAISE NOTICE 'Клиент успешно добавлен';
    EXCEPTION 
        WHEN unique_violation THEN
            RAISE NOTICE 'Ошибка: Клиент с таким ID уже существует';
        WHEN OTHERS THEN
            RAISE NOTICE 'Неизвестная ошибка: %', SQLERRM;
    END;
END $$;
```
2. Обработка исключения при нарушении ограничений
```sql
DO $$
BEGIN
    BEGIN
        INSERT INTO Review (ReviewID, ClientID, Rating, Comment)
        VALUES (100, 1, 10, 'Некорректный рейтинг'); -- Рейтинг > 5
        
        RAISE NOTICE 'Отзыв добавлен';
    EXCEPTION 
        WHEN check_violation THEN
            RAISE NOTICE 'Ошибка: Рейтинг должен быть от 1 до 5';
        WHEN OTHERS THEN
            RAISE NOTICE 'Ошибка: %', SQLERRM;
    END;
END $$;
```
## RAISE
1. RAISE с разными уровнями сообщений
```sql
DO $$
DECLARE
    client_count INT;
BEGIN
    SELECT COUNT(*) INTO client_count FROM Client;
    
    RAISE DEBUG 'Отладочная информация: всего клиентов - %', client_count;
    RAISE LOG 'Логирование: количество клиентов - %', client_count;
    RAISE INFO 'Информация: в базе % клиентов', client_count;
    RAISE NOTICE 'Уведомление: обработано % клиентов', client_count;
    RAISE WARNING 'Предупреждение: мало клиентов (%)', client_count;
    
    IF client_count < 5 THEN
        RAISE EXCEPTION 'Критическая ошибка: слишком мало клиентов (%)', client_count;
    END IF;
END $$;
```
2. RAISE с параметрами
```sql
DO $$
DECLARE
    avg_rating DECIMAL;
    max_rating INT;
    min_rating INT;
BEGIN
    SELECT AVG(Rating), MAX(Rating), MIN(Rating) 
    INTO avg_rating, max_rating, min_rating
    FROM Review;
    
    RAISE NOTICE 'Статистика отзывов:';
    RAISE NOTICE 'Средний рейтинг: %', avg_rating;
    RAISE NOTICE 'Максимальный рейтинг: %', max_rating;
    RAISE NOTICE 'Минимальный рейтинг: %', min_rating;
    RAISE NOTICE 'Всего отзывов: %', (SELECT COUNT(*) FROM Review);
    
    IF avg_rating < 3.0 THEN
        RAISE WARNING 'Низкий средний рейтинг: %', avg_rating;
    END IF;
END $$;
```
