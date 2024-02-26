-- Настройка прав для ролей
GRANT SELECT ON ALL TABLES IN SCHEMA public TO yoga_analyst;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO yoga_manager;
GRANT SELECT ON studios, classes TO yoga_instructor;

-- Проверка от имени аналитика
-- Подключение: psql -U yoga_analyst -d yogadb
SET ROLE yoga_analyst;
SELECT COUNT(*) FROM clients; 
SELECT COUNT(*) FROM memberships; 
INSERT INTO clients (first_name, last_name, email) VALUES ('Test', 'User', 'test@test.com'); 
<img width="809" height="231" alt="image" src="https://github.com/user-attachments/assets/90d9e834-435d-403e-8913-eb432099a29b" />

-- Проверка от имени менеджера
SET ROLE yoga_manager;
INSERT INTO studios (name, address) VALUES ('Новая студия', 'Адрес'); 
SELECT * FROM studios; 
<img width="594" height="31" alt="image" src="https://github.com/user-attachments/assets/0bd7f85d-55d0-4210-8b4f-2302416ef271" />
<img width="212" height="402" alt="image" src="https://github.com/user-attachments/assets/e06a82c7-fb67-4a95-8898-83996e9002ff" />

-- Проверка от имени инструктора
SET ROLE yoga_instructor;
SELECT * FROM classes LIMIT 10; 
SELECT * FROM clients LIMIT 10; 
<img width="438" height="48" alt="image" src="https://github.com/user-attachments/assets/c38ece2a-7dd1-42a3-af40-8a46e30b2922" />


-- Возврат к админу
RESET ROLE;
