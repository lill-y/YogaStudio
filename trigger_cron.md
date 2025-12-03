Триггеры
1. BEFORE INSERT (Row Level) - Проверка данных перед вставкой
Триггер 1: Проверка возраста клиента

sql
CREATE OR REPLACE FUNCTION check_client_age()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.DateOfBirth IS NOT NULL THEN
        IF EXTRACT(YEAR FROM AGE(CURRENT_DATE, NEW.DateOfBirth)) < 16 THEN
            RAISE EXCEPTION 'Клиент должен быть старше 16 лет';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_check_client_age
BEFORE INSERT ON Client
FOR EACH ROW
EXECUTE FUNCTION check_client_age();
Триггер 2: Проверка рейтинга в отзывах

sql
CREATE OR REPLACE FUNCTION check_review_rating()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Rating < 1 OR NEW.Rating > 5 THEN
        NEW.Rating := 3; -- Устанавливаем среднее значение по умолчанию
        RAISE NOTICE 'Рейтинг автоматически установлен на 3 (должен быть от 1 до 5)';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_check_review_rating
BEFORE INSERT ON Review
FOR EACH ROW
EXECUTE FUNCTION check_review_rating();
2. AFTER INSERT (Row Level) - Логирование после вставки
Триггер 3: Логирование нового клиента

sql
CREATE TABLE client_audit (
    audit_id SERIAL PRIMARY KEY,
    client_id INT,
    action VARCHAR(10),
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_name VARCHAR(50) DEFAULT CURRENT_USER
);

CREATE OR REPLACE FUNCTION log_new_client()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO client_audit (client_id, action)
    VALUES (NEW.ClientID, 'INSERT');
    RAISE NOTICE 'Добавлен новый клиент: % % (ID: %)', 
        NEW.FirstName, NEW.LastName, NEW.ClientID;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_log_new_client
AFTER INSERT ON Client
FOR EACH ROW
EXECUTE FUNCTION log_new_client();
Триггер 4: Логирование нового платежа

sql
CREATE TABLE payment_audit (
    audit_id SERIAL PRIMARY KEY,
    payment_id INT,
    amount DECIMAL(10,2),
    action VARCHAR(10),
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_new_payment()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO payment_audit (payment_id, amount, action)
    VALUES (NEW.PaymentID, NEW.Amount, 'INSERT');
    RAISE NOTICE 'Зарегистрирован новый платеж: % руб. (ID: %)', 
        NEW.Amount, NEW.PaymentID;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_log_new_payment
AFTER INSERT ON Payment
FOR EACH ROW
EXECUTE FUNCTION log_new_payment();
3. BEFORE UPDATE (Row Level) - Валидация перед обновлением
Триггер 5: Проверка дат членства

sql
CREATE OR REPLACE FUNCTION validate_membership_dates()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.EndDate <= NEW.StartDate THEN
        RAISE EXCEPTION 'Дата окончания членства должна быть позже даты начала';
    END IF;
    
    IF NEW.EndDate < CURRENT_DATE AND NEW.Status = 'active' THEN
        NEW.Status := 'inactive';
        RAISE NOTICE 'Статус членства автоматически изменен на inactive (просрочено)';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_validate_membership_dates
BEFORE UPDATE ON Membership
FOR EACH ROW
EXECUTE FUNCTION validate_membership_dates();
Триггер 6: Обновление времени модификации

sql
-- Добавим поле last_updated в таблицу Client
ALTER TABLE Client ADD COLUMN last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_client_timestamp
BEFORE UPDATE ON Client
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();
4. AFTER UPDATE (Row Level) - Отслеживание изменений
Триггер 7: Аудит изменений клиента

sql
CREATE TABLE client_changes_audit (
    change_id SERIAL PRIMARY KEY,
    client_id INT,
    changed_column VARCHAR(50),
    old_value TEXT,
    new_value TEXT,
    change_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION audit_client_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.FirstName != NEW.FirstName THEN
        INSERT INTO client_changes_audit (client_id, changed_column, old_value, new_value)
        VALUES (NEW.ClientID, 'FirstName', OLD.FirstName, NEW.FirstName);
    END IF;
    
    IF OLD.LastName != NEW.LastName THEN
        INSERT INTO client_changes_audit (client_id, changed_column, old_value, new_value)
        VALUES (NEW.ClientID, 'LastName', OLD.LastName, NEW.LastName);
    END IF;
    
    IF OLD.Phone != NEW.Phone THEN
        INSERT INTO client_changes_audit (client_id, changed_column, old_value, new_value)
        VALUES (NEW.ClientID, 'Phone', OLD.Phone, NEW.Phone);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_audit_client_changes
AFTER UPDATE ON Client
FOR EACH ROW
EXECUTE FUNCTION audit_client_changes();
Триггер 8: Обновление статистики при изменении платежа

sql
CREATE OR REPLACE FUNCTION update_payment_stats()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Платеж ID % обновлен. Старая сумма: %, Новая сумма: %', 
        NEW.PaymentID, OLD.Amount, NEW.Amount;
    
    -- Можно добавить дополнительную логику, например, обновление кэшированных сумм
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_payment_stats
AFTER UPDATE ON Payment
FOR EACH ROW
EXECUTE FUNCTION update_payment_stats();
5. BEFORE DELETE (Row Level) - Предотвращение удаления
Триггер 9: Предотвращение удаления клиента с активным членством

sql
CREATE OR REPLACE FUNCTION prevent_client_deletion()
RETURNS TRIGGER AS $$
DECLARE
    active_memberships INT;
BEGIN
    SELECT COUNT(*) INTO active_memberships
    FROM Membership 
    WHERE ClientID = OLD.ClientID 
    AND Status = 'active' 
    AND EndDate >= CURRENT_DATE;
    
    IF active_memberships > 0 THEN
        RAISE EXCEPTION 'Нельзя удалить клиента с активным членством. ID клиента: %', 
            OLD.ClientID;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_prevent_client_deletion
BEFORE DELETE ON Client
FOR EACH ROW
EXECUTE FUNCTION prevent_client_deletion();
Триггер 10: Архивирование удаляемого отзыва

sql
CREATE TABLE review_archive (
    review_id INT PRIMARY KEY,
    client_id INT,
    rating INT,
    comment TEXT,
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION archive_deleted_review()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO review_archive (review_id, client_id, rating, comment)
    VALUES (OLD.ReviewID, OLD.ClientID, OLD.Rating, OLD.Comment);
    
    RAISE NOTICE 'Отзыв ID % перемещен в архив', OLD.ReviewID;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_archive_deleted_review
BEFORE DELETE ON Review
FOR EACH ROW
EXECUTE FUNCTION archive_deleted_review();
6. AFTER DELETE (Row Level) - Логирование удаления
Триггер 11: Логирование удаления записи

sql
CREATE OR REPLACE FUNCTION log_deletion()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO client_audit (client_id, action)
    VALUES (OLD.ClientID, 'DELETE');
    
    RAISE NOTICE 'Клиент удален: % % (ID: %)', 
        OLD.FirstName, OLD.LastName, OLD.ClientID;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_log_deletion
AFTER DELETE ON Client
FOR EACH ROW
EXECUTE FUNCTION log_deletion();
Триггер 12: Обновление счетчиков после удаления

sql
CREATE OR REPLACE FUNCTION update_counters_after_delete()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Запись удалена. Можно обновить связанные счетчики или статистику';
    -- Здесь можно обновить кэшированные данные или счетчики
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_counters_after_delete
AFTER DELETE ON Membership
FOR EACH ROW
EXECUTE FUNCTION update_counters_after_delete();
7. Statement Level Triggers
Триггер 13: BEFORE STATEMENT - Логирование начала операции

sql
CREATE OR REPLACE FUNCTION log_before_statement()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Начало операции на таблице %', TG_TABLE_NAME;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_log_before_statement
BEFORE INSERT OR UPDATE OR DELETE ON Payment
FOR EACH STATEMENT
EXECUTE FUNCTION log_before_statement();
Триггер 14: AFTER STATEMENT - Логирование завершения операции

sql
CREATE OR REPLACE FUNCTION log_after_statement()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Завершение операции на таблице %', TG_TABLE_NAME;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_log_after_statement
AFTER INSERT OR UPDATE OR DELETE ON Payment
FOR EACH STATEMENT
EXECUTE FUNCTION log_after_statement();
8. INSTEAD OF Triggers (для представлений)
Создадим представление и триггер для него:

sql
CREATE VIEW client_membership_view AS
SELECT 
    c.ClientID,
    c.FirstName,
    c.LastName,
    m.Type AS membership_type,
    m.Status AS membership_status
FROM Client c
LEFT JOIN Membership m ON c.ClientID = m.ClientID;

CREATE OR REPLACE FUNCTION update_client_membership_view()
RETURNS TRIGGER AS $$
BEGIN
    -- Обновляем только таблицу Client, так как это простой пример
    UPDATE Client 
    SET FirstName = NEW.FirstName,
        LastName = NEW.LastName
    WHERE ClientID = NEW.ClientID;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_update_client_membership_view
INSTEAD OF UPDATE ON client_membership_view
FOR EACH ROW
EXECUTE FUNCTION update_client_membership_view();
Запрос для отображения всех триггеров
sql
SELECT 
    tgname AS trigger_name,
    relname AS table_name,
    tgtype AS trigger_type,
    tgenabled AS is_enabled,
    proname AS function_name
FROM pg_trigger
JOIN pg_class ON pg_trigger.tgrelid = pg_class.oid
JOIN pg_proc ON pg_trigger.tgfoid = pg_proc.oid
WHERE pg_trigger.tgisinternal = false
ORDER BY table_name, trigger_name;
Cron задачи (pg_cron)
Установка расширения pg_cron
sql
-- Если расширение не установлено
CREATE EXTENSION IF NOT EXISTS pg_cron;
1. Cron задача: Ежедневное обновление статусов членств
sql
SELECT cron.schedule(
    'update-membership-status',
    '0 2 * * *', -- Каждый день в 2:00 ночи
    $$
    UPDATE Membership 
    SET Status = 'inactive' 
    WHERE EndDate < CURRENT_DATE 
    AND Status = 'active';
    
    INSERT INTO cron_log (job_name, executed_at, rows_affected)
    VALUES ('update-membership-status', NOW(), (SELECT COUNT(*) FROM Membership WHERE EndDate < CURRENT_DATE AND Status = 'active'));
    $$
);
2. Cron задача: Еженедельная статистика
sql
SELECT cron.schedule(
    'weekly-stats-report',
    '0 3 * * 1', -- Каждый понедельник в 3:00
    $$
    INSERT INTO weekly_stats (
        week_start,
        total_clients,
        new_clients_this_week,
        total_revenue,
        avg_rating
    )
    SELECT 
        DATE_TRUNC('week', CURRENT_DATE) AS week_start,
        COUNT(DISTINCT c.ClientID) AS total_clients,
        COUNT(DISTINCT CASE WHEN c.ClientID > (SELECT MAX(ClientID) FROM Client) - 7 THEN c.ClientID END) AS new_clients_this_week,
        COALESCE(SUM(p.Amount), 0) AS total_revenue,
        COALESCE(AVG(r.Rating), 0) AS avg_rating
    FROM Client c
    LEFT JOIN Payment p ON c.ClientID = p.ClientID
    LEFT JOIN Review r ON c.ClientID = r.ClientID
    WHERE p.Date >= CURRENT_DATE - INTERVAL '7 days';
    $$
);
3. Cron задача: Ежемесячная архивация старых данных
sql
SELECT cron.schedule(
    'monthly-data-archive',
    '0 4 1 * *', -- Первое число каждого месяца в 4:00
    $$
    -- Архивируем платежи старше 1 года
    INSERT INTO payment_archive
    SELECT *, NOW() AS archived_at
    FROM Payment 
    WHERE Date < CURRENT_DATE - INTERVAL '1 year';
    
    -- Удаляем архивированные платежи
    DELETE FROM Payment 
    WHERE Date < CURRENT_DATE - INTERVAL '1 year';
    
    RAISE LOG 'Ежемесячная архивация завершена: % платежей архивировано', (SELECT COUNT(*) FROM payment_archive WHERE archived_at::date = CURRENT_DATE);
    $$
);
Создание таблиц для логирования cron задач
sql
CREATE TABLE cron_log (
    log_id SERIAL PRIMARY KEY,
    job_name VARCHAR(100),
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    rows_affected INT,
    status VARCHAR(20) DEFAULT 'success'
);

CREATE TABLE weekly_stats (
    stat_id SERIAL PRIMARY KEY,
    week_start DATE,
    total_clients INT,
    new_clients_this_week INT,
    total_revenue DECIMAL(10,2),
    avg_rating DECIMAL(3,2),
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payment_archive (
    payment_id INT PRIMARY KEY,
    client_id INT,
    membership_id INT,
    date DATE,
    amount DECIMAL(10,2),
    archived_at TIMESTAMP
);
Запрос для просмотра всех cron задач
sql
SELECT 
    jobid,
    schedule,
    command,
    database,
    username,
    active
FROM cron.job
ORDER BY jobid;
Запрос для просмотра выполнения cron задач
sql
SELECT 
    log_id,
    job_name,
    executed_at,
    rows_affected,
    status
FROM cron_log
ORDER BY executed_at DESC
LIMIT 50;
