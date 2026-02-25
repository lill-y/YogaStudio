-- Настройка прав для ролей
GRANT SELECT ON ALL TABLES IN SCHEMA public TO yoga_analyst;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO yoga_manager;
GRANT SELECT ON studios, classes TO yoga_instructor;

-- Проверка от имени аналитика
-- Подключение: psql -U yoga_analyst -d yogadb
SET ROLE yoga_analyst;
SELECT COUNT(*) FROM clients; -- Должно работать
SELECT COUNT(*) FROM memberships; -- Должно работать
INSERT INTO clients (first_name, last_name, email) VALUES ('Test', 'User', 'test@test.com'); -- Должно FAIL

-- Проверка от имени менеджера
SET ROLE yoga_manager;
INSERT INTO studios (name, address) VALUES ('Новая студия', 'Адрес'); -- Должно работать
SELECT * FROM studios; -- Должно работать

-- Проверка от имени инструктора
SET ROLE yoga_instructor;
SELECT * FROM classes LIMIT 10; -- Должно работать
SELECT * FROM clients LIMIT 10; -- Должно FAIL

-- Возврат к админу
RESET ROLE;
