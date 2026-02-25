-- Роль 1: Администратор (полный доступ)
CREATE ROLE yoga_admin WITH LOGIN PASSWORD 'admin123' SUPERUSER;

-- Роль 2: Менеджер (CRUD на основные таблицы, без прав на создание ролей)
CREATE ROLE yoga_manager WITH LOGIN PASSWORD 'manager123';
GRANT CONNECT ON DATABASE yogadb TO yoga_manager;

-- Роль 3: Аналитик (только SELECT)
CREATE ROLE yoga_analyst WITH LOGIN PASSWORD 'analyst123';
GRANT CONNECT ON DATABASE yogadb TO yoga_analyst;

-- Роль 4: Инструктор (только просмотр своих классов)
CREATE ROLE yoga_instructor WITH LOGIN PASSWORD 'instructor123';
GRANT CONNECT ON DATABASE yogadb TO yoga_instructor;

-- Проверка ролей
\du
