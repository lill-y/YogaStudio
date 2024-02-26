-- Миграция 1: Создание основных таблиц
-- ======================================

-- Таблица студий (равномерное распределение - 5 студий)
CREATE TABLE studios (
    studio_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    established_date DATE,
    studio_size VARCHAR(20), -- "small", "medium", "large"
    rating DECIMAL(3,2),
    amenities JSONB DEFAULT "[]", -- JSONB: ["parking", "showers", "cafe"]
    location_point POINT, -- геометрический тип
    working_hours_range TSRANGE, -- range тип
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица клиентов (высокая кардинальность - уникальные)
CREATE TABLE clients (
    client_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(10), -- низкая кардинальность: "male", "female", "other"
    loyalty_level VARCHAR(20), -- низкая кардинальность: "bronze", "silver", "gold", "platinum"
    referral_code VARCHAR(20), -- уникальный код приглашения
    preferences TEXT[], -- массив предпочтений: ["yoga", "meditation", "pilates"]
    health_notes TEXT,
    last_visit_date DATE,
    is_active BOOLEAN DEFAULT true,
    studio_id INT REFERENCES studios(studio_id),
    registration_date DATE DEFAULT CURRENT_DATE,
    CONSTRAINT fk_studio FOREIGN KEY (studio_id) REFERENCES studios(studio_id)
);

-- Таблица членств (неравномерное распределение)
CREATE TABLE memberships (
    membership_id SERIAL PRIMARY KEY,
    client_id INT NOT NULL REFERENCES clients(client_id),
    membership_type VARCHAR(30), -- неравномерное: 70% "basic", 20% "premium", 10% "vip"
    start_date DATE NOT NULL,
    end_date DATE,
    price DECIMAL(10,2),
    discount DECIMAL(5,2), -- NULL в 20% строк
    auto_renew BOOLEAN DEFAULT false,
    payment_method VARCHAR(30),
    contract TEXT, -- полнотекстовые данные
    special_conditions JSONB, -- JSONB
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_client FOREIGN KEY (client_id) REFERENCES clients(client_id)
);

-- Таблица классов (диапазонные значения + полнотекст)
CREATE TABLE classes (
    class_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT, -- полнотекстовый поиск
    category VARCHAR(30), -- низкая кардинальность: "hatha", "vinyasa", "ashtanga", "yin", "kundalini"
    difficulty_level INT CHECK (difficulty_level BETWEEN 1 AND 5),
    duration_minutes INT,
    max_capacity INT,
    current_enrollment INT,
    instructor_id INT,
    studio_id INT REFERENCES studios(studio_id),
    schedule_info JSONB, -- JSONB с расписанием
    is_active BOOLEAN DEFAULT true,
    tags TEXT[], -- массив тегов
    average_rating DECIMAL(3,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица платежей (равномерное распределение)
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    client_id INT NOT NULL REFERENCES clients(client_id),
    membership_id INT REFERENCES memberships(membership_id),
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method VARCHAR(30), -- неравномерное: 60% "card", 30% "cash", 10% "online"
    status VARCHAR(20) DEFAULT "completed", -- "completed", "pending", "failed", "refunded"
    transaction_id VARCHAR(100) UNIQUE, -- высокая кардинальность
    notes TEXT,
    refund_reason TEXT, -- NULL в 95% строк
    processed_by INT, -- NULL в 10% строк
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Миграция 2: Создание индексов
-- ======================================
CREATE INDEX idx_clients_email ON clients(email);
CREATE INDEX idx_clients_loyalty ON clients(loyalty_level);
CREATE INDEX idx_memberships_dates ON memberships(start_date, end_date);
CREATE INDEX idx_payments_date ON payments(payment_date);
CREATE INDEX idx_classes_category ON classes(category);
CREATE INDEX idx_classes_difficulty ON classes(difficulty_level);

-- Полнотекстовый индекс
CREATE INDEX idx_classes_description ON classes USING GIN(to_tsvector("russian", description));

-- JSONB индексы
CREATE INDEX idx_studios_amenities ON studios USING GIN(amenities);
CREATE INDEX idx_memberships_conditions ON memberships USING GIN(special_conditions);

-- Миграция 3: Создание представлений и триггеров
-- ======================================

-- Представление для аналитики
CREATE VIEW membership_stats AS
SELECT 
    membership_type,
    COUNT(*) as total_count,
    AVG(price) as avg_price,
    SUM(CASE WHEN auto_renew THEN 1 ELSE 0 END) as auto_renew_count
FROM memberships
GROUP BY membership_type;

-- Триггер для обновления даты последнего визита
CREATE OR REPLACE FUNCTION update_last_visit()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE clients 
    SET last_visit_date = CURRENT_DATE 
    WHERE client_id = NEW.client_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_last_visit
AFTER INSERT ON payments
FOR EACH ROW
EXECUTE FUNCTION update_last_visit();

