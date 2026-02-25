-- Сначала создадим функцию для генерации текста
CREATE OR REPLACE FUNCTION random_text(min_words INT DEFAULT 5, max_words INT DEFAULT 20)
RETURNS TEXT AS $$
DECLARE
    words TEXT[] := ARRAY['йога', 'здоровье', 'медитация', 'гибкость', 'сила', 'баланс', 
                          'дыхание', 'расслабление', 'энергия', 'гармония', 'спокойствие',
                          'практика', 'осознанность', 'тело', 'дух', 'здоровый', 'активный',
                          'восстановление', 'релаксация', 'концентрация'];
    result TEXT := '';
    word_count INT := floor(random() * (max_words - min_words + 1)) + min_words;
    i INT;
BEGIN
    FOR i IN 1..word_count LOOP
        result := result || ' ' || words[1 + floor(random() * array_length(words, 1))];
    END LOOP;
    RETURN trim(result);
END;
$$ LANGUAGE plpgsql;

-- 1. Заполняем студии (равномерное распределение - 10 студий)
TRUNCATE studios CASCADE;
INSERT INTO studios (name, address, phone, email, established_date, studio_size, rating, amenities, location_point, working_hours_range)
SELECT 
    'Йога-студия ' || chr(65 + i) || ' ' || floor(random() * 100)::TEXT,
    'ул. ' || chr(66 + floor(random() * 20)::INT) || ', д. ' || floor(random() * 100)::TEXT,
    '+7 (495) ' || lpad(floor(random() * 1000)::TEXT, 3, '0') || '-' || lpad(floor(random() * 100)::TEXT, 2, '0') || '-' || lpad(floor(random() * 100)::TEXT, 2, '0'),
    'studio' || i || '@yoga.ru',
    '2020-01-01'::DATE + (random() * 1000)::INT * INTERVAL '1 day',
    CASE floor(random() * 3) 
        WHEN 0 THEN 'small'
        WHEN 1 THEN 'medium'
        ELSE 'large'
    END,
    3.5 + random() * 1.5,
    jsonb_build_array(
        CASE WHEN random() > 0.3 THEN 'parking' END,
        CASE WHEN random() > 0.5 THEN 'showers' END,
        CASE WHEN random() > 0.7 THEN 'cafe' END,
        CASE WHEN random() > 0.8 THEN 'lockers' END
    ),
    point(37.6 + random() * 0.2, 55.7 + random() * 0.2),
    tsrange(
        '09:00'::TIME + (random() * 2 * INTERVAL '1 hour'),
        '21:00'::TIME + (random() * 2 * INTERVAL '1 hour')
    )
FROM generate_series(1, 10) i;

-- 2. Заполняем клиентов (500k записей)
TRUNCATE clients CASCADE;
INSERT INTO clients (first_name, last_name, email, phone, date_of_birth, gender, loyalty_level, referral_code, preferences, health_notes, last_visit_date, is_active, studio_id, registration_date)
SELECT 
    'Имя' || i,
    'Фамилия' || i,
    'user' || i || '@example.com',
    '+7' || lpad(floor(random() * 10000000000)::TEXT, 10, '0'),
    '1950-01-01'::DATE + (random() * 25000)::INT * INTERVAL '1 day',
    CASE floor(random() * 3)
        WHEN 0 THEN 'male'
        WHEN 1 THEN 'female'
        ELSE 'other'
    END,
    CASE 
        WHEN random() < 0.4 THEN 'bronze'      -- 40%
        WHEN random() < 0.7 THEN 'silver'       -- 30%
        WHEN random() < 0.9 THEN 'gold'         -- 20%
        ELSE 'platinum'                          -- 10%
    END,
    'REF' || lpad(i::TEXT, 8, '0'),
    ARRAY[
        CASE WHEN random() > 0.5 THEN 'yoga' END,
        CASE WHEN random() > 0.7 THEN 'meditation' END,
        CASE WHEN random() > 0.8 THEN 'pilates' END
    ],
    CASE WHEN random() < 0.2 THEN random_text(10, 50) ELSE NULL END, -- NULL в 20%
    CASE WHEN random() < 0.7 THEN CURRENT_DATE - (random() * 30)::INT * INTERVAL '1 day' ELSE NULL END,
    random() < 0.9, -- 90% активных
    floor(random() * 10 + 1)::INT,
    '2022-01-01'::DATE + (random() * 700)::INT * INTERVAL '1 day'
FROM generate_series(1, 500000) i;

-- 3. Заполняем членства (300k записей - неравномерное распределение)
TRUNCATE memberships CASCADE;
INSERT INTO memberships (client_id, membership_type, start_date, end_date, price, discount, auto_renew, payment_method, contract, special_conditions)
SELECT 
    floor(random() * 500000 + 1)::INT,
    CASE 
        WHEN random() < 0.7 THEN 'basic'        -- 70% basic
        WHEN random() < 0.9 THEN 'premium'       -- 20% premium
        ELSE 'vip'                                -- 10% vip
    END,
    '2023-01-01'::DATE + (random() * 600)::INT * INTERVAL '1 day',
    CASE 
        WHEN random() < 0.8 THEN '2023-12-31'::DATE + (random() * 100)::INT * INTERVAL '1 day'
        ELSE NULL
    END,
    5000 + random() * 15000,
    CASE WHEN random() < 0.2 THEN random() * 30 ELSE NULL END, -- NULL в 20%
    random() < 0.3,
    CASE floor(random() * 4)
        WHEN 0 THEN 'card'
        WHEN 1 THEN 'cash'
        WHEN 2 THEN 'online'
        ELSE 'bank_transfer'
    END,
    random_text(20, 100),
    jsonb_build_object(
        'has_trial', random() < 0.1,
        'freeze_months', floor(random() * 3)::INT,
        'guest_passes', floor(random() * 5)::INT
    )
FROM generate_series(1, 300000) i;

-- 4. Заполняем классы (250k записей)
TRUNCATE classes CASCADE;
INSERT INTO classes (name, description, category, difficulty_level, duration_minutes, max_capacity, current_enrollment, instructor_id, studio_id, schedule_info, is_active, tags, average_rating)
SELECT 
    CASE floor(random() * 5)
        WHEN 0 THEN 'Хатха-йога'
        WHEN 1 THEN 'Аштанга-йога'
        WHEN 2 THEN 'Кундалини-йога'
        WHEN 3 THEN 'Йога-терапия'
        ELSE 'Виньяса-флоу'
    END || ' ' || i,
    random_text(15, 40),
    CASE floor(random() * 5)
        WHEN 0 THEN 'hatha'
        WHEN 1 THEN 'vinyasa'
        WHEN 2 THEN 'ashtanga'
        WHEN 3 THEN 'yin'
        ELSE 'kundalini'
    END,
    floor(random() * 5 + 1)::INT,
    CASE floor(random() * 3)
        WHEN 0 THEN 60
        WHEN 1 THEN 75
        ELSE 90
    END,
    floor(random() * 20 + 10)::INT,
    floor(random() * 20)::INT,
    floor(random() * 50 + 1)::INT,
    floor(random() * 10 + 1)::INT,
    jsonb_build_object(
        'monday', random() < 0.3,
        'tuesday', random() < 0.3,
        'wednesday', random() < 0.3,
        'thursday', random() < 0.3,
        'friday', random() < 0.3,
        'saturday', random() < 0.2,
        'sunday', random() < 0.1
    ),
    random() < 0.95,
    ARRAY[
        CASE WHEN random() > 0.7 THEN 'beginners' END,
        CASE WHEN random() > 0.8 THEN 'advanced' END,
        CASE WHEN random() > 0.9 THEN 'hot' END
    ],
    3.0 + random() * 2.0
FROM generate_series(1, 250000) i;

-- 5. Заполняем платежи (200k записей)
TRUNCATE payments CASCADE;
INSERT INTO payments (client_id, membership_id, amount, payment_date, payment_method, status, transaction_id, notes, refund_reason, processed_by)
SELECT 
    floor(random() * 500000 + 1)::INT,
    floor(random() * 300000 + 1)::INT,
    5000 + random() * 20000,
    '2023-06-01'::DATE + (random() * 180)::INT * INTERVAL '1 day',
    CASE 
        WHEN random() < 0.6 THEN 'card'      -- 60%
        WHEN random() < 0.9 THEN 'cash'       -- 30%
        ELSE 'online'                          -- 10%
    END,
    CASE 
        WHEN random() < 0.9 THEN 'completed'
        WHEN random() < 0.95 THEN 'pending'
        WHEN random() < 0.98 THEN 'failed'
        ELSE 'refunded'
    END,
    'TXN' || lpad(floor(random() * 1000000000)::TEXT, 10, '0'),
    CASE WHEN random() < 0.3 THEN random_text(5, 15) ELSE NULL END,
    CASE WHEN random() < 0.05 THEN random_text(10, 30) ELSE NULL END, -- NULL в 95%
    CASE WHEN random() < 0.9 THEN floor(random() * 50 + 1)::INT ELSE NULL END
FROM generate_series(1, 200000) i;

-- Проверка количества записей
SELECT 'studios' as table_name, COUNT(*) as count FROM studios
UNION ALL
SELECT 'clients', COUNT(*) FROM clients
UNION ALL
SELECT 'memberships', COUNT(*) FROM memberships
UNION ALL
SELECT 'classes', COUNT(*) FROM classes
UNION ALL
SELECT 'payments', COUNT(*) FROM payments;
