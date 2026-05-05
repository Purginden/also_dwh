-- Создаём новую схему also
CREATE SCHEMA IF NOT EXISTS also;

-- Проверяем, что схема создана
SELECT 
    schema_name,
    schema_owner
FROM information_schema.schemata 
WHERE schema_name = 'also';

-- Удаляем схему
-- DROP SCHEMA IF EXISTS also CASCADE;


-- =====================================================
-- Таблицы Справочников 
-- =====================================================

-- Создаем Справочник Календарь

CREATE TABLE IF NOT EXISTS also.dim_calendar (
    date_id         DATE PRIMARY KEY,           -- Ключ 
    year            SMALLINT NOT NULL,          -- Год 
    quarter         SMALLINT NOT NULL,          -- Квартал 
    month           SMALLINT NOT NULL,          -- Месяц 
    month_name      VARCHAR(20) NOT NULL,       -- Название месяца 
    month_short     VARCHAR(3) NOT NULL,        -- Короткое название 
    week            SMALLINT NOT NULL,          -- Номер недели в году
    day_of_month    SMALLINT NOT NULL,          -- День месяца 
    day_of_week     SMALLINT NOT NULL,          -- День недели 
    day_name        VARCHAR(20) NOT NULL,       -- Название дня 
    is_weekend      BOOLEAN NOT NULL DEFAULT FALSE, -- Выходной
    is_holiday      BOOLEAN NOT NULL DEFAULT FALSE  -- Праздник
);

-- Удаляем Справочник Календарь
-- DROP TABLE IF EXISTS also.dim_calendar CASCADE;

-- Наполняем Справочник Календарь (2020-2026)
INSERT INTO also.dim_calendar (
    date_id,
    year,
    quarter,
    month,
    month_name,
    month_short,
    week,
    day_of_month,
    day_of_week,
    day_name,
    is_weekend,
    is_holiday
)
SELECT 
    generate_series::DATE AS date_id,
    EXTRACT(YEAR FROM generate_series)::SMALLINT AS year,
    EXTRACT(QUARTER FROM generate_series)::SMALLINT AS quarter,
    EXTRACT(MONTH FROM generate_series)::SMALLINT AS month,
    CASE EXTRACT(MONTH FROM generate_series)
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
    END AS month_name,
    CASE EXTRACT(MONTH FROM generate_series)
        WHEN 1 THEN 'Янв'
        WHEN 2 THEN 'Фев'
        WHEN 3 THEN 'Мар'
        WHEN 4 THEN 'Апр'
        WHEN 5 THEN 'Май'
        WHEN 6 THEN 'Июн'
        WHEN 7 THEN 'Июл'
        WHEN 8 THEN 'Авг'
        WHEN 9 THEN 'Сен'
        WHEN 10 THEN 'Окт'
        WHEN 11 THEN 'Ноя'
        WHEN 12 THEN 'Дек'
    END AS month_short,
    EXTRACT(WEEK FROM generate_series)::SMALLINT AS week,
    EXTRACT(DAY FROM generate_series)::SMALLINT AS day_of_month,
    -- День недели: понедельник = 1, воскресенье = 7
    CASE EXTRACT(DOW FROM generate_series)
        WHEN 0 THEN 7  -- Воскресенье в PostgreSQL это 0
        ELSE EXTRACT(DOW FROM generate_series)::INT
    END::SMALLINT AS day_of_week,
    CASE EXTRACT(DOW FROM generate_series)
        WHEN 1 THEN 'Понедельник'
        WHEN 2 THEN 'Вторник'
        WHEN 3 THEN 'Среда'
        WHEN 4 THEN 'Четверг'
        WHEN 5 THEN 'Пятница'
        WHEN 6 THEN 'Суббота'
        WHEN 0 THEN 'Воскресенье'
    END AS day_name,
    -- Выходные: суббота (6) или воскресенье (0)
    (EXTRACT(DOW FROM generate_series) IN (0, 6)) AS is_weekend,
    FALSE AS is_holiday  -- Пока все FALSE, можно будет обновить
FROM generate_series('2020-01-01'::DATE, '2026-12-31'::DATE, '1 day'::INTERVAL);


-- Чистим Справочник Календарь 
--TRUNCATE TABLE also.dim_calendar RESTART IDENTITY;

-- Создаем Справочник Филиалы

CREATE TABLE IF NOT EXISTS also.dim_branch (
    branch_id       SERIAL PRIMARY KEY,          -- Уникальный идентификатор филиала
    branch_code     VARCHAR(10) NOT NULL UNIQUE, -- Код филиала (RND, SPB, MSK)
    branch_name     VARCHAR(100) NOT NULL,       -- Название филиала
    city           VARCHAR(100) NOT NULL,        -- Город
    address        VARCHAR(255) NOT NULL,        -- Полный адрес
    phone          VARCHAR(50),                  -- Телефон
    extension      VARCHAR(10),                  -- Добавочный номер
    email          VARCHAR(100),                 -- Email филиала
    is_active      BOOLEAN DEFAULT TRUE,         -- Активен ли филиал
    created_date   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Удаляем Справочник Филиалы
--DROP TABLE IF EXISTS also.dim_branch CASCADE;

-- Наполняем Справочник Филиалы
INSERT INTO also.dim_branch (
    branch_code,
    branch_name,
    city,
    address,
    phone,
    extension,
    email,
    is_active
) VALUES 
    -- Челябинск
    (
        'CHE',
        'Уральский регион',
        'г. Челябинск',
        'ул. Складская, 1',
        '+7 (800) 444-74-74',
        '-',
        'info@alsoarm.ru',  -- email не указан в исходных данных
        TRUE
    ),
    -- Ростов-на-Дону
    (
        'RND',
        'Южный регион',
        'г. Ростов-на-Дону',
        'ул. Доватора, 150, оф. 329',
        '+7 (800) 444-74-74',
        '300',
        'ba@alsoarm.ru',  -- email не указан в исходных данных
        TRUE
    ),
    -- Санкт-Петербург
    (
        'SPB',
        'Северо-Западный регион',
        'Санкт-Петербург',
        'ул. Домостроительная, 3Д',
        '+7 (800) 444-74-74',
        '500',
        'msd@alsoarm.ru',
        TRUE
    ),
    -- Москва
    (
        'MSK',
        'Центральный регион',
        'Москва',
        'ул. Амурская, д. 3, стр. 19',
        '+7 (800) 444-74-74',
        '550',
        'tsa@alsoarm.ru',
        TRUE
    );

-- Чистим Справочник Филиалы
--TRUNCATE TABLE also.dim_branch RESTART IDENTITY;

-- Создаем Справочник Дилеры

CREATE TABLE IF NOT EXISTS also.dim_dealer (
    dealer_id       SERIAL PRIMARY KEY,          -- Уникальный идентификатор дилера
    dealer_code     VARCHAR(20) NOT NULL UNIQUE, -- Код дилера 
    short_name      VARCHAR(100) NOT NULL,       -- Краткое название 
    full_name       VARCHAR(200),                -- Полное юридическое название
    website         VARCHAR(100),                -- Сайт компании
    email_primary   VARCHAR(100),                -- Основной email
    email_secondary VARCHAR(100),                -- Дополнительный email
    address         VARCHAR(255) NOT NULL,       -- Юридический/фактический адрес
    phone_primary   VARCHAR(50) NOT NULL,        -- Основной телефон
    phone_secondary VARCHAR(50),                 -- Дополнительный телефон
    is_active       BOOLEAN DEFAULT TRUE,        -- Активен ли дилер
    contract_date   DATE,                        -- Дата заключения договора
    rating          SMALLINT DEFAULT 3,          -- Рейтинг дилера (1-5)
    created_date    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Удаляем Справочник Дилеры
--DROP TABLE IF EXISTS also.dim_dealer CASCADE;

-- Наполняем Справочник Дилеры
INSERT INTO also.dim_dealer (
    dealer_code,
    short_name,
    full_name,
    website,
    email_primary,
    email_secondary,
    address,
    phone_primary,
    phone_secondary,
    is_active,
    contract_date,
    rating
) VALUES 
    -- ООО «Терем»
    (
        'TEREM',
        'ООО «Терем»',
        'Общество с ограниченной ответственностью «Терем»',
        'teremopt.ru',
        'info@teremopt.ru',
        'info@teremonline.ru',
        'г. Москва, пр. Нахимовский, д. 47',
        '+7 (495) 775-20-20',
        NULL,
        TRUE,
        '2020-01-15',
        5
    ),
    -- Компания ЭТМ
    (
        'ETM',
        'Компания ЭТМ',
        'Электротехнические материалы',
        'etm.ru',
        'msk2@msk.etm.ru',
        NULL,
        'г. Москва, пр. Балаклавский, д. 28 лит. Б',
        '+7 (495) 785-04-20',
        '+7 (495) 785-04-21',
        TRUE,
        '2019-03-20',
        5
    ),
    -- ЗАО Фирма «Проконсим»
    (
        'PROK',
        'ЗАО Фирма «Проконсим»',
        'Закрытое акционерное общество Фирма «Проконсим»',
        'proconsim.ru',
        'sales_msk@proconsim.ru',
        NULL,
        'г. Москва, ул. Авиамоторная, д.10, корп. 2',
        '+7 (800) 551-69-78',
        NULL,
        TRUE,
        '2021-06-10',
        4
    ),
    -- ДН.РУ
    (
        'DNRU',
        'ДН.РУ',
        'ДН.РУ - интернет-магазин',
        'dn.ru',
        'info@dn.ru',
        NULL,
        'г. Москва, проезд Востряковский, дом 10Б, стр. 3, помещ. 19',
        '+7 (495) 504-37-40',
        NULL,
        TRUE,
        '2022-01-25',
        4
    );

-- Чистим Справочник Дилеры
--TRUNCATE TABLE also.dim_dealer RESTART IDENTITY;


-- Создаем Справочник Виды Крана

CREATE TABLE IF NOT EXISTS also.dim_crane_type (
    crane_type_id       SERIAL PRIMARY KEY,           -- Уникальный идентификатор вида крана
    crane_code          VARCHAR(20) NOT NULL UNIQUE,  -- Код вида крана (BALL_LIQUID, BALL_GAS, etc.)
    crane_name          VARCHAR(150) NOT NULL,        -- Наименование вида крана
    crane_category      VARCHAR(50),                  -- Категория (шаровые, запорные и т.д.)
    application_area    TEXT,                         -- Область применения (жидкие/газообразные среды)
    purpose             TEXT,                         -- Назначение (запорные, регулирующие)
    is_import_substitution BOOLEAN DEFAULT FALSE,     -- Импортозамещение?
    technical_conditions VARCHAR(100),                -- Технические условия (ТУ)
    is_active           BOOLEAN DEFAULT TRUE,         -- Активен ли вид продукции
    sort_order          SMALLINT,                     -- Порядок сортировки
    created_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Удаляем Справочник Виды Крана
--DROP TABLE IF EXISTS also.dim_crane_type  CASCADE;

-- Наполняем Справочник Виды Крана
INSERT INTO also.dim_crane_type (
    crane_code,
    crane_name,
    crane_category,
    application_area,
    purpose,
    is_import_substitution,
    technical_conditions,
    is_active,
    sort_order
) VALUES 
    -- 1. Краны шаровые для жидких сред
    (
        'BALL_LIQUID',
        'Краны шаровые для жидких сред',
        'Шаровые краны',
        'Жидкие среды (вода, нефтепродукты, химические жидкости)',
        'Запорные',
        FALSE,
        'ТУ 3743-001-XXXX-2020',
        TRUE,
        1
    ),
    
    -- 2. Краны шаровые для газообразных сред
    (
        'BALL_GAS',
        'Краны шаровые для газообразных сред',
        'Шаровые краны',
        'Газообразные среды (природный газ, азот, кислород, пропан)',
        'Запорные',
        FALSE,
        'ТУ 3743-002-XXXX-2020',
        TRUE,
        2
    ),
    
    -- 3. Краны шаровые для импортозамещения
    (
        'BALL_IMPORT_SUB',
        'Краны шаровые для импортозамещения',
        'Шаровые краны',
        'Жидкие и газообразные среды (аналоги импортных кранов)',
        'Запорные, регулирующие',
        TRUE,
        'ТУ 3743-003-XXXX-2021',
        TRUE,
        3
    ),
    
    -- 4. Краны шаровые запорно-регулирующие
    (
        'BALL_REGULATING',
        'Краны шаровые запорно-регулирующие',
        'Шаровые краны',
        'Жидкие среды с регулированием потока',
        'Запорно-регулирующие',
        FALSE,
        'ТУ 3743-004-XXXX-2021',
        TRUE,
        4
    );

-- Чистим Справочник Виды Крана
--TRUNCATE TABLE also.dim_crane_type  RESTART IDENTITY;

-- Создаем Справочник Продукты
CREATE TABLE IF NOT EXISTS also.dim_product (
    product_id          SERIAL PRIMARY KEY,              -- Уникальный идентификатор продукта
    product_code        VARCHAR(50) NOT NULL UNIQUE,     -- Код продукта (артикул)
    product_name        VARCHAR(200) NOT NULL,           -- Наименование продукта
    crane_type_id       INTEGER NOT NULL,                -- Ссылка на вид крана
    model               VARCHAR(100),                    -- Модель/серия
    diameter_dn         SMALLINT,                        -- Диаметр DN (15, 20, 25...)
    pressure_pn         SMALLINT,                        -- Давление PN (16, 25, 40...)
    connection_type     VARCHAR(50),                     -- Тип присоединения (приварной, фланцевый, резьбовой)
    bore_type           VARCHAR(50),                     -- Тип прохода (полнопроходный, стандартный)
    body_material       VARCHAR(100),                    -- Материал корпуса
    seal_material       VARCHAR(100),                    -- Материал уплотнений
    temperature_range   VARCHAR(50),                     -- Диапазон температур
    weight_kg           DECIMAL(10,2),                   -- Вес в кг
    length_mm           INTEGER,                         -- Длина в мм
    height_mm           INTEGER,                         -- Высота в мм
    is_active           BOOLEAN DEFAULT TRUE,            -- Активен ли продукт
    is_stocked          BOOLEAN DEFAULT TRUE,            -- Есть ли на складе
    retail_price       DECIMAL(12,2),                    -- Розничная цена
    wholesale_price    DECIMAL(12,2),                    -- Оптовая цена
    created_date       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Внешний ключ к справочнику видов кранов
    CONSTRAINT fk_product_crane_type FOREIGN KEY (crane_type_id) 
        REFERENCES also.dim_crane_type(crane_type_id) ON DELETE RESTRICT
);

-- Удаляем Справочник Продукты
--DROP TABLE IF EXISTS also.dim_product CASCADE;

-- Наполняем Справочник Продукты
WITH ct AS (
    SELECT crane_type_id, crane_code 
    FROM also.dim_crane_type 
    WHERE crane_code IN ('BALL_LIQUID', 'BALL_GAS', 'BALL_IMPORT_SUB', 'BALL_REGULATING')
)
INSERT INTO also.dim_product (
    product_code,
    product_name,
    crane_type_id,
    model,
    diameter_dn,
    pressure_pn,
    connection_type,
    bore_type,
    body_material,
    seal_material,
    temperature_range,
    weight_kg,
    length_mm,
    height_mm,
    is_active,
    is_stocked,
    retail_price,
    wholesale_price
)
SELECT * FROM (
    VALUES 
    -- =====================================================
    -- 1. Краны шаровые для жидких сред (BALL_LIQUID)
    -- =====================================================
    (
        'ALSO-BL-WP-15-40',
        'Кран шаровой ALSO для жидких сред приварной полнопроходный DN 15 PN 40',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_LIQUID'),
        'ALSO-Ball-WP',
        15, 40, 'Приварной', 'Полнопроходный', 'Сталь 20', 'PTFE', '-40°C до +200°C',
        1.2, 130, 65, TRUE, TRUE, 2450.00, 1850.00
    ),
    (
        'ALSO-BL-FL-20-25',
        'Кран шаровой ALSO для жидких сред фланцевый полнопроходный DN 20 PN 25',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_LIQUID'),
        'ALSO-Ball-FL',
        20, 25, 'Фланцевый', 'Полнопроходный', 'Сталь 20', 'PTFE', '-40°C до +200°C',
        2.5, 160, 85, TRUE, TRUE, 3850.00, 2950.00
    ),
    (
        'ALSO-BL-RES-25-16',
        'Кран шаровой ALSO для жидких сред резьбовой стандартный DN 25 PN 16',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_LIQUID'),
        'ALSO-Ball-RES',
        25, 16, 'Резьбовой', 'Стандартный', 'Чугун ВЧШГ', 'NBR', '-20°C до +120°C',
        3.2, 180, 95, TRUE, TRUE, 2950.00, 2250.00
    ),
    (
        'ALSO-BL-WP-32-40',
        'Кран шаровой ALSO для жидких сред приварной полнопроходный DN 32 PN 40',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_LIQUID'),
        'ALSO-Ball-WP',
        32, 40, 'Приварной', 'Полнопроходный', 'Сталь 20', 'PTFE', '-40°C до +200°C',
        2.8, 170, 95, TRUE, TRUE, 3850.00, 2950.00
    ),
    (
        'ALSO-BL-WP-40-40',
        'Кран шаровой ALSO для жидких сред приварной полнопроходный DN 40 PN 40',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_LIQUID'),
        'ALSO-Ball-WP',
        40, 40, 'Приварной', 'Полнопроходный', 'Сталь 09Г2С', 'PTFE', '-60°C до +200°C',
        5.2, 200, 115, TRUE, TRUE, 6850.00, 5250.00
    ),
    (
        'ALSO-BL-WP-50-40',
        'Кран шаровой ALSO для жидких сред приварной полнопроходный DN 50 PN 40',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_LIQUID'),
        'ALSO-Ball-WP',
        50, 40, 'Приварной', 'Полнопроходный', 'Сталь 09Г2С', 'PTFE', '-60°C до +200°C',
        8.5, 230, 135, TRUE, TRUE, 12500.00, 9800.00
    ),
    (
        'ALSO-BL-FL-80-16',
        'Кран шаровой ALSO для жидких сред фланцевый полнопроходный DN 80 PN 16',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_LIQUID'),
        'ALSO-Ball-FL',
        80, 16, 'Фланцевый', 'Полнопроходный', 'Сталь 20', 'PTFE', '-40°C до +180°C',
        18.5, 280, 175, TRUE, TRUE, 28900.00, 23500.00
    ),
    (
        'ALSO-BL-FL-100-16',
        'Кран шаровой ALSO для жидких сред фланцевый полнопроходный DN 100 PN 16',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_LIQUID'),
        'ALSO-Ball-FL',
        100, 16, 'Фланцевый', 'Полнопроходный', 'Сталь 20', 'PTFE', '-40°C до +180°C',
        28.0, 350, 210, TRUE, FALSE, 45600.00, 36800.00
    ),
    (
        'ALSO-BL-FL-150-16',
        'Кран шаровой ALSO для жидких сред фланцевый полнопроходный DN 150 PN 16',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_LIQUID'),
        'ALSO-Ball-FL',
        150, 16, 'Фланцевый', 'Полнопроходный', 'Сталь 20', 'PTFE', '-40°C до +180°C',
        52.0, 480, 290, TRUE, FALSE, 87600.00, 69800.00
    ),

    -- =====================================================
    -- 2. Краны шаровые для газообразных сред (BALL_GAS)
    -- =====================================================
    (
        'ALSO-BG-WP-15-40',
        'Кран шаровой ALSO для газообразных сред приварной полнопроходный DN 15 PN 40',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_GAS'),
        'ALSO-Gas-WP',
        15, 40, 'Приварной', 'Полнопроходный', 'Сталь 09Г2С', 'PTFE+POM', '-60°C до +80°C',
        1.3, 130, 65, TRUE, TRUE, 2850.00, 2250.00
    ),
    (
        'ALSO-BG-WP-25-40',
        'Кран шаровой ALSO для газообразных сред приварной полнопроходный DN 25 PN 40',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_GAS'),
        'ALSO-Gas-WP',
        25, 40, 'Приварной', 'Полнопроходный', 'Сталь 09Г2С', 'PTFE+POM', '-60°C до +80°C',
        3.5, 190, 100, TRUE, TRUE, 4250.00, 3350.00
    ),
    (
        'ALSO-BG-WP-40-40',
        'Кран шаровой ALSO для газообразных сред приварной полнопроходный DN 40 PN 40',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_GAS'),
        'ALSO-Gas-WP',
        40, 40, 'Приварной', 'Полнопроходный', 'Сталь 09Г2С', 'PTFE+POM', '-60°C до +80°C',
        5.8, 200, 115, TRUE, TRUE, 7850.00, 6250.00
    ),
    (
        'ALSO-BG-FL-50-25',
        'Кран шаровой ALSO для газообразных сред фланцевый полнопроходный DN 50 PN 25',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_GAS'),
        'ALSO-Gas-FL',
        50, 25, 'Фланцевый', 'Полнопроходный', 'Сталь 09Г2С', 'PTFE+POM', '-60°C до +80°C',
        9.5, 240, 140, TRUE, TRUE, 14900.00, 11800.00
    ),
    (
        'ALSO-BG-FL-80-25',
        'Кран шаровой ALSO для газообразных сред фланцевый полнопроходный DN 80 PN 25',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_GAS'),
        'ALSO-Gas-FL',
        80, 25, 'Фланцевый', 'Полнопроходный', 'Сталь 09Г2С', 'PTFE+POM', '-60°C до +80°C',
        19.5, 290, 180, TRUE, FALSE, 32900.00, 26800.00
    ),

    -- =====================================================
    -- 3. Краны шаровые для импортозамещения (BALL_IMPORT_SUB)
    -- =====================================================
    (
        'ALSO-IS-FL-25-40',
        'Кран шаровой ALSO импортозамещение фланцевый полнопроходный DN 25 PN 40 (аналог Bray)',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_IMPORT_SUB'),
        'ALSO-ImportSub',
        25, 40, 'Фланцевый', 'Полнопроходный', 'AISI 304', 'PTFE+EPDM', '-40°C до +180°C',
        4.5, 190, 105, TRUE, TRUE, 8900.00, 7200.00
    ),
    (
        'ALSO-IS-FL-40-40',
        'Кран шаровой ALSO импортозамещение фланцевый полнопроходный DN 40 PN 40 (аналог Kitz)',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_IMPORT_SUB'),
        'ALSO-ImportSub',
        40, 40, 'Фланцевый', 'Полнопроходный', 'AISI 304', 'PTFE+EPDM', '-40°C до +180°C',
        8.5, 220, 130, TRUE, TRUE, 14900.00, 11900.00
    ),
    (
        'ALSO-IS-FL-50-40',
        'Кран шаровой ALSO импортозамещение фланцевый полнопроходный DN 50 PN 40 (аналог Bray)',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_IMPORT_SUB'),
        'ALSO-ImportSub',
        50, 40, 'Фланцевый', 'Полнопроходный', 'AISI 304', 'PTFE+EPDM', '-40°C до +180°C',
        12.5, 280, 160, TRUE, TRUE, 18900.00, 15200.00
    ),
    (
        'ALSO-IS-WP-80-25',
        'Кран шаровой ALSO импортозамещение приварной полнопроходный DN 80 PN 25 (аналог Kitz)',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_IMPORT_SUB'),
        'ALSO-ImportSub',
        80, 25, 'Приварной', 'Полнопроходный', 'AISI 316', 'PTFE', '-196°C до +200°C',
        24.0, 320, 195, TRUE, TRUE, 32400.00, 26800.00
    ),
    (
        'ALSO-IS-FL-100-16',
        'Кран шаровой ALSO импортозамещение фланцевый полнопроходный DN 100 PN 16 (аналог Bray)',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_IMPORT_SUB'),
        'ALSO-ImportSub',
        100, 16, 'Фланцевый', 'Полнопроходный', 'AISI 316', 'PTFE', '-196°C до +200°C',
        32.0, 360, 220, TRUE, FALSE, 58900.00, 47800.00
    ),

    -- =====================================================
    -- 4. Краны шаровые запорно-регулирующие (BALL_REGULATING)
    -- =====================================================
    (
        'ALSO-BR-FL-20-25',
        'Кран шаровой ALSO запорно-регулирующий фланцевый DN 20 PN 25 с рукояткой',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_REGULATING'),
        'ALSO-Regulate',
        20, 25, 'Фланцевый', 'Стандартный', 'Сталь 20', 'PTFE+EPDM', '-30°C до +150°C',
        3.2, 160, 90, TRUE, TRUE, 4850.00, 3850.00
    ),
    (
        'ALSO-BR-FL-32-25',
        'Кран шаровой ALSO запорно-регулирующий фланцевый DN 32 PN 25 с червячным редуктором',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_REGULATING'),
        'ALSO-Regulate',
        32, 25, 'Фланцевый', 'Стандартный', 'Сталь 20', 'PTFE+EPDM', '-30°C до +150°C',
        6.5, 190, 115, TRUE, TRUE, 7850.00, 6250.00
    ),
    (
        'ALSO-BR-FL-40-25',
        'Кран шаровой ALSO запорно-регулирующий фланцевый DN 40 PN 25 с рукояткой',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_REGULATING'),
        'ALSO-Regulate',
        40, 25, 'Фланцевый', 'Стандартный', 'Сталь 20', 'PTFE+EPDM', '-30°C до +150°C',
        7.8, 220, 125, TRUE, TRUE, 8750.00, 6950.00
    ),
    (
        'ALSO-BR-FL-50-16',
        'Кран шаровой ALSO запорно-регулирующий фланцевый DN 50 PN 16 с червячным редуктором',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_REGULATING'),
        'ALSO-Regulate',
        50, 16, 'Фланцевый', 'Стандартный', 'Сталь 20', 'PTFE+EPDM', '-30°C до +150°C',
        11.5, 250, 145, TRUE, TRUE, 12900.00, 10200.00
    ),
    (
        'ALSO-BR-FL-65-16',
        'Кран шаровой ALSO запорно-регулирующий фланцевый DN 65 PN 16 с червячным редуктором',
        (SELECT crane_type_id FROM ct WHERE crane_code = 'BALL_REGULATING'),
        'ALSO-Regulate',
        65, 16, 'Фланцевый', 'Стандартный', 'Сталь 20', 'PTFE+EPDM', '-30°C до +150°C',
        16.5, 270, 165, TRUE, FALSE, 18900.00, 15200.00
    )
) AS v(
    product_code, product_name, crane_type_id, model, diameter_dn, pressure_pn,
    connection_type, bore_type, body_material, seal_material, temperature_range,
    weight_kg, length_mm, height_mm, is_active, is_stocked, retail_price, wholesale_price
);

-- Чистим Справочник Продукты
--TRUNCATE TABLE also.dim_product  RESTART IDENTITY;

-- Создаем Справочник Менеджеры

CREATE TABLE IF NOT EXISTS also.dim_manager (
    manager_id          SERIAL PRIMARY KEY,              -- Уникальный идентификатор менеджера
    manager_code        VARCHAR(20) NOT NULL UNIQUE,     -- Код менеджера (M001, M002...)
    last_name           VARCHAR(50) NOT NULL,            -- Фамилия
    first_name          VARCHAR(50) NOT NULL,            -- Имя
    middle_name         VARCHAR(50),                     -- Отчество
    manager_name        VARCHAR(150) GENERATED ALWAYS AS 
                        (CASE 
                            WHEN middle_name IS NOT NULL THEN last_name || ' ' || first_name || ' ' || middle_name
                            ELSE last_name || ' ' || first_name
                        END) STORED,                     -- Полное имя (генерируется автоматически)
    position            VARCHAR(100) NOT NULL,           -- Должность
    department          VARCHAR(100) NOT NULL,           -- Отдел
    branch_id           INTEGER,                         -- Филиал (убираем FOREIGN KEY временно)
    phone_work          VARCHAR(50),                     -- Рабочий телефон
    phone_mobile        VARCHAR(50),                     -- Мобильный телефон
    email               VARCHAR(100) UNIQUE,             -- Email
    hire_date           DATE NOT NULL,                   -- Дата найма
    experience_years    INTEGER,                         -- Опыт в годах (будем заполнять через UPDATE или триггер)
    sales_quota_year    DECIMAL(12,2),                   -- Годовая квота продаж (руб)
    manager_level       VARCHAR(20) CHECK (manager_level IN ('Junior', 'Middle', 'Senior', 'Lead')), -- Уровень
    is_active           BOOLEAN DEFAULT TRUE,            -- Активен ли менеджер
    created_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Добавляем внешний ключ после создания таблицы
ALTER TABLE also.dim_manager 
ADD CONSTRAINT fk_manager_branch 
FOREIGN KEY (branch_id) REFERENCES also.dim_branch(branch_id);

-- Удаляем Справочник Менеджеры
--DROP TABLE IF EXISTS also.dim_manager CASCADE;

-- Наполняем Справочник Менеджеры
INSERT INTO also.dim_manager (
    manager_code,
    last_name,
    first_name,
    middle_name,
    position,
    department,
    branch_id,
    phone_work,
    phone_mobile,
    email,
    hire_date,
    sales_quota_year,
    manager_level,
    is_active
) VALUES 
-- Филиал Москва (branch_id = 3)
(
    'M001', 'Смирнов', 'Алексей', 'Владимирович',
    'Ведущий менеджер по продажам', 'Отдел продаж кранов',
    3, '+7 (495) 777-10-01', '+7 (916) 111-22-33',
    'a.smirnov@alsoarm.ru', '2015-03-15', 50000000, 'Senior', TRUE
),
(
    'M002', 'Кузнецова', 'Елена', 'Андреевна',
    'Руководитель отдела продаж', 'Управление продажами',
    3, '+7 (495) 777-10-02', '+7 (916) 222-33-44',
    'e.kuznetsova@alsoarm.ru', '2012-07-20', 75000000, 'Lead', TRUE
),
(
    'M003', 'Волков', 'Дмитрий', 'Сергеевич',
    'Старший менеджер по продажам', 'Отдел продаж кранов',
    3, '+7 (495) 777-10-03', '+7 (916) 333-44-55',
    'd.volkov@alsoarm.ru', '2016-11-10', 45000000, 'Senior', TRUE
),
(
    'M004', 'Морозова', 'Анна', 'Игоревна',
    'Менеджер по продажам', 'Отдел продаж кранов',
    3, '+7 (495) 777-10-04', '+7 (916) 444-55-66',
    'a.morozova@alsoarm.ru', '2018-02-01', 35000000, 'Middle', TRUE
),
(
    'M005', 'Новиков', 'Павел', 'Александрович',
    'Менеджер по продажам', 'Отдел продаж кранов',
    3, '+7 (495) 777-10-05', '+7 (916) 555-66-77',
    'p.novikov@alsoarm.ru', '2019-05-15', 30000000, 'Middle', TRUE
),
(
    'M006', 'Федорова', 'Татьяна', 'Михайловна',
    'Менеджер по работе с клиентами', 'Отдел сопровождения',
    3, '+7 (495) 777-10-06', '+7 (916) 666-77-88',
    't.fedorova@alsoarm.ru', '2019-09-20', 25000000, 'Middle', TRUE
),
(
    'M007', 'Соколов', 'Иван', 'Денисович',
    'Младший менеджер по продажам', 'Отдел продаж кранов',
    3, '+7 (495) 777-10-07', '+7 (916) 777-88-99',
    'i.sokolov@alsoarm.ru', '2021-03-10', 20000000, 'Junior', TRUE
),
(
    'M008', 'Лебедева', 'Мария', 'Алексеевна',
    'Младший менеджер по продажам', 'Отдел продаж кранов',
    3, '+7 (495) 777-10-08', '+7 (916) 888-99-00',
    'm.lebedeva@alsoarm.ru', '2022-01-15', 18000000, 'Junior', TRUE
),

-- Филиал Санкт-Петербург (branch_id = 2)
(
    'M009', 'Козлов', 'Андрей', 'Владимирович',
    'Региональный менеджер', 'Региональные продажи',
    2, '+7 (812) 444-10-01', '+7 (921) 111-22-33',
    'a.kozlov@alsoarm.ru', '2014-04-12', 40000000, 'Senior', TRUE
),
(
    'M010', 'Павлова', 'Ольга', 'Сергеевна',
    'Менеджер по продажам', 'Региональные продажи',
    2, '+7 (812) 444-10-02', '+7 (921) 222-33-44',
    'o.pavlova@alsoarm.ru', '2017-08-25', 32000000, 'Middle', TRUE
),
(
    'M011', 'Степанов', 'Максим', 'Игоревич',
    'Менеджер по продажам', 'Региональные продажи',
    2, '+7 (812) 444-10-03', '+7 (921) 333-44-55',
    'm.stepanov@alsoarm.ru', '2018-11-18', 28000000, 'Middle', TRUE
),
(
    'M012', 'Николаева', 'Екатерина', 'Дмитриевна',
    'Младший менеджер', 'Региональные продажи',
    2, '+7 (812) 444-10-04', '+7 (921) 444-55-66',
    'e.nikolaeva@alsoarm.ru', '2021-07-01', 18000000, 'Junior', TRUE
),

-- Филиал Ростов-на-Дону (branch_id = 1)
(
    'M013', 'Сидоров', 'Владимир', 'Петрович',
    'Региональный менеджер', 'Региональные продажи',
    1, '+7 (863) 555-10-01', '+7 (928) 111-22-33',
    'v.sidorov@alsoarm.ru', '2013-09-05', 38000000, 'Senior', TRUE
),
(
    'M014', 'Васильева', 'Наталья', 'Андреевна',
    'Менеджер по продажам', 'Региональные продажи',
    1, '+7 (863) 555-10-02', '+7 (928) 222-33-44',
    'n.vasilieva@alsoarm.ru', '2016-12-12', 30000000, 'Middle', TRUE
),
(
    'M015', 'Петров', 'Артем', 'Витальевич',
    'Менеджер по продажам', 'Региональные продажи',
    1, '+7 (863) 555-10-03', '+7 (928) 333-44-55',
    'a.petrov@alsoarm.ru', '2019-03-22', 25000000, 'Middle', TRUE
),

-- Дополнительные менеджеры
(
    'M016', 'Михайлова', 'Ирина', 'Александровна',
    'Менеджер по работе с дилерами', 'Дилерский отдел',
    3, '+7 (495) 777-10-09', '+7 (916) 999-00-11',
    'i.mikhailova@alsoarm.ru', '2017-05-17', 35000000, 'Middle', TRUE
),
(
    'M017', 'Егоров', 'Константин', 'Владиславович',
    'Специалист по импортозамещению', 'Отдел импортозамещения',
    3, '+7 (495) 777-10-10', '+7 (916) 000-11-22',
    'k.egorov@alsoarm.ru', '2020-02-10', 28000000, 'Middle', TRUE
),
(
    'M018', 'Андреева', 'Светлана', 'Игоревна',
    'Ведущий менеджер по продажам', 'Отдел продаж кранов',
    3, '+7 (495) 777-10-11', '+7 (916) 111-22-44',
    's.andreeva@alsoarm.ru', '2014-10-01', 48000000, 'Senior', TRUE
),
(
    'M019', 'Тимофеев', 'Александр', 'Николаевич',
    'Менеджер по продажам', 'Отдел продаж кранов',
    3, '+7 (495) 777-10-12', '+7 (916) 222-33-55',
    'a.timofeev@alsoarm.ru', '2019-08-14', 32000000, 'Middle', TRUE
),
(
    'M020', 'Григорьева', 'Юлия', 'Валерьевна',
    'Младший менеджер', 'Отдел продаж кранов',
    3, '+7 (495) 777-10-13', '+7 (916) 333-44-66',
    'y.grigorieva@alsoarm.ru', '2022-06-20', 15000000, 'Junior', TRUE
);

-- Чистим Справочник Менеджеры
--TRUNCATE TABLE also.dim_manager  RESTART IDENTITY;


-- Создаем Справочник Пользователи
CREATE TABLE also.dim_user (
    user_id             SERIAL PRIMARY KEY,
    username            VARCHAR(50) NOT NULL UNIQUE,    -- Логин пользователя
    email               VARCHAR(100) NOT NULL UNIQUE,   -- Email (для авторизации)
    
    -- Связь с менеджером
    manager_id          INTEGER UNIQUE,                 -- Ссылка на менеджера (1:1)
    
    -- Роли и права доступа
    user_role           VARCHAR(50) DEFAULT 'Viewer' 
                        CHECK (user_role IN ('Admin', 'Editor', 'Viewer', 'Analyst')),
    
    -- Статус и аудит
    is_active           BOOLEAN DEFAULT TRUE,
    last_login          TIMESTAMP,
    last_activity       TIMESTAMP,
    created_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Внешний ключ к dim_manager
    CONSTRAINT fk_user_manager FOREIGN KEY (manager_id) 
        REFERENCES also.dim_manager(manager_id) ON DELETE SET NULL,
    
    -- Индекс для быстрого поиска
    CONSTRAINT unique_manager_user UNIQUE (manager_id)
);

-- Индексы
CREATE INDEX idx_user_username ON also.dim_user(username);
CREATE INDEX idx_user_email ON also.dim_user(email);
CREATE INDEX idx_user_role ON also.dim_user(user_role);
CREATE INDEX idx_user_active ON also.dim_user(is_active);


-- Удаляем Справочник Пользователи
--DROP TABLE IF EXISTS also.dim_user CASCADE;

-- Наполняем Справочник Пользователи

INSERT INTO also.dim_user (
    username,
    email,
    manager_id,
    user_role,
    is_active,
    created_date,
    updated_date
)
SELECT 
    -- Генерация username из email (часть до @) или из manager_name
    CASE 
        WHEN m.email IS NOT NULL THEN SPLIT_PART(m.email, '@', 1)
        ELSE LOWER(REPLACE(REPLACE(m.manager_name, ' ', '.'), 'ё', 'е'))
    END AS username,
    
    -- Email (используем существующий или генерируем)
    COALESCE(m.email, LOWER(REPLACE(REPLACE(m.manager_name, ' ', '.'), 'ё', 'е')) || '@alsoarm.ru') AS email,
    
    -- manager_id
    m.manager_id,
    
    -- Назначение роли в зависимости от уровня менеджера
    CASE 
        WHEN m.manager_level = 'Lead' THEN 'Admin'
        WHEN m.manager_level = 'Senior' THEN 'Editor'
        WHEN m.manager_level = 'Middle' THEN 'Analyst'
        WHEN m.manager_level = 'Junior' THEN 'Viewer'
        ELSE 'Viewer'
    END AS user_role,
    
    -- Активен, если менеджер активен
    m.is_active AS is_active,
    
    -- Даты
    CURRENT_TIMESTAMP AS created_date,
    CURRENT_TIMESTAMP AS updated_date
    
FROM also.dim_manager m
WHERE m.is_active = TRUE
  AND m.email IS NOT NULL  -- Только менеджеры с email
ON CONFLICT (username) DO UPDATE SET
    email = EXCLUDED.email,
    manager_id = EXCLUDED.manager_id,
    user_role = EXCLUDED.user_role,
    is_active = EXCLUDED.is_active,
    updated_date = CURRENT_TIMESTAMP;


-- Чистим Справочник Пользователи
--TRUNCATE TABLE also.dim_user  RESTART IDENTITY;


-- Создаем Справочник Клиенты
CREATE TABLE IF NOT EXISTS also.dim_customer (
    customer_id         SERIAL PRIMARY KEY,              -- Уникальный идентификатор клиента
    customer_code       VARCHAR(20) NOT NULL UNIQUE,     -- Код клиента (C00001, C00002...)
    customer_type       VARCHAR(50) NOT NULL,            -- Тип клиента (Юрлицо, ИП, Физлицо)
    short_name          VARCHAR(150) NOT NULL,           -- Краткое наименование
    full_name           VARCHAR(300),                    -- Полное наименование
    inn                 VARCHAR(12),                     -- ИНН (10 или 12 цифр)
    kpp                 VARCHAR(9),                      -- КПП (для юрлиц)
    ogrn                VARCHAR(15),                     -- ОГРН/ОГРНИП
    legal_address       VARCHAR(300),                    -- Юридический адрес
    actual_address      VARCHAR(300),                    -- Фактический адрес
    phone_primary       VARCHAR(50) NOT NULL,            -- Основной телефон
    phone_secondary     VARCHAR(50),                     -- Дополнительный телефон
    email_primary       VARCHAR(100),                    -- Основной email
    email_secondary     VARCHAR(100),                    -- Дополнительный email
    contact_person      VARCHAR(150),                    -- Контактное лицо
    contact_position    VARCHAR(100),                    -- Должность контактного лица
    manager_id          INTEGER REFERENCES also.dim_manager(manager_id), -- Ответственный менеджер
    region              VARCHAR(100),                    -- Регион
    city                VARCHAR(100),                    -- Город
    postcode            VARCHAR(10),                     -- Индекс
    credit_limit        DECIMAL(15,2) DEFAULT 0,         -- Кредитный лимит
    payment_delay_days  INTEGER DEFAULT 0,               -- Отсрочка платежа (дней)
    discount_percent    DECIMAL(5,2) DEFAULT 0,          -- Персональная скидка (%)
    client_status       VARCHAR(20) DEFAULT 'Active' 
                        CHECK (client_status IN ('Active', 'Inactive', 'Blocked', 'Potential')), -- Статус
    registration_date   DATE NOT NULL DEFAULT CURRENT_DATE, -- Дата регистрации в системе
    last_purchase_date  DATE,                            -- Дата последней покупки
    total_purchases     DECIMAL(15,2) DEFAULT 0,         -- Сумма всех покупок
    is_vip              BOOLEAN DEFAULT FALSE,           -- VIP-клиент
    is_active           BOOLEAN DEFAULT TRUE,            -- Активен ли клиент
    created_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Удаляем Справочник Клиенты
--DROP TABLE IF EXISTS also.dim_customer  CASCADE;

-- Наполняем Справочник Клиенты

-- Функция для генерации случайного телефона
CREATE OR REPLACE FUNCTION also.generate_random_phone()
RETURNS VARCHAR(50) AS $$
BEGIN
    RETURN '+7 (9' || 
           floor(random() * 10)::int || 
           floor(random() * 10)::int || 
           floor(random() * 10)::int || 
           ') ' ||
           floor(random() * 100)::int || '-' ||
           floor(random() * 100)::int || '-' ||
           floor(random() * 100)::int;
END;
$$ LANGUAGE plpgsql;

-- Функция для генерации случайного email
CREATE OR REPLACE FUNCTION also.generate_random_email(p_name VARCHAR, p_domain VARCHAR DEFAULT 'mail.ru')
RETURNS VARCHAR(100) AS $$
DECLARE
    v_clean_name VARCHAR(100);
BEGIN
    v_clean_name := REPLACE(REPLACE(REPLACE(LOWER(p_name), ' ', ''), '-', ''), '''', '');
    RETURN v_clean_name || floor(random() * 1000)::int || '@' || p_domain;
END;
$$ LANGUAGE plpgsql;

WITH manager_ids AS (
    SELECT manager_id, ROW_NUMBER() OVER (ORDER BY manager_id) as rn
    FROM also.dim_manager
    WHERE is_active = TRUE
)
INSERT INTO also.dim_customer (
    customer_code,
    customer_type,
    short_name,
    full_name,
    inn,
    kpp,
    ogrn,
    legal_address,
    actual_address,
    phone_primary,
    phone_secondary,
    email_primary,
    contact_person,
    contact_position,
    manager_id,
    region,
    city,
    postcode,
    credit_limit,
    payment_delay_days,
    discount_percent,
    client_status,
    registration_date,
    is_vip
)
SELECT 
    'C' || LPAD(generate_series::TEXT, 5, '0') AS customer_code,
    CASE (random() * 3)::int
        WHEN 0 THEN 'Юрлицо'
        WHEN 1 THEN 'Юрлицо'
        WHEN 2 THEN 'ИП'
        ELSE 'Физлицо'
    END AS customer_type,
    CASE (random() * 3)::int
        WHEN 0 THEN 'ООО "Трейд-' || chr(65 + (random() * 25)::int) || chr(65 + (random() * 25)::int) || '"'
        WHEN 1 THEN 'АО "' || 
            CASE (random() * 5)::int
                WHEN 0 THEN 'Строй'
                WHEN 1 THEN 'Техно'
                WHEN 2 THEN 'Пром'
                WHEN 3 THEN 'Нефте'
                ELSE 'Газ'
            END || 
            CASE (random() * 5)::int
                WHEN 0 THEN 'Инвест'
                WHEN 1 THEN 'Ресурс'
                WHEN 2 THEN 'Снаб'
                WHEN 3 THEN 'Торг'
                ELSE 'Монтаж'
            END || '"'
        WHEN 2 THEN 'ИП ' || 
            CASE (random() * 9)::int
                WHEN 0 THEN 'Иванов'
                WHEN 1 THEN 'Петров'
                WHEN 2 THEN 'Сидоров'
                WHEN 3 THEN 'Кузнецов'
                WHEN 4 THEN 'Смирнов'
                WHEN 5 THEN 'Васильев'
                WHEN 6 THEN 'Попов'
                WHEN 7 THEN 'Соколов'
                ELSE 'Михайлов'
            END
        ELSE 
            CASE (random() * 5)::int
                WHEN 0 THEN 'ООО "Альянс"'
                WHEN 1 THEN 'ООО "ПромТехСнаб"'
                WHEN 2 THEN 'ООО "ТехноСервис"'
                WHEN 3 THEN 'АО "СтройКомплект"'
                ELSE 'ООО "ЭнергоМаш"'
            END
    END AS short_name,
    NULL AS full_name,
    LPAD((random() * 1000000000000)::bigint::text, 12, '0') AS inn,
    CASE WHEN (random() * 3)::int IN (0,1) THEN LPAD((random() * 100000000)::int::text, 9, '0') ELSE NULL END AS kpp,
    LPAD((random() * 100000000000000)::bigint::text, 15, '0') AS ogrn,
    'г. ' || 
    CASE (random() * 4)::int
        WHEN 0 THEN 'Москва'
        WHEN 1 THEN 'Санкт-Петербург'
        WHEN 2 THEN 'Ростов-на-Дону'
        WHEN 3 THEN 'Казань'
        ELSE 'Новосибирск'
    END || ', ул. ' || 
    CASE (random() * 5)::int
        WHEN 0 THEN 'Ленина'
        WHEN 1 THEN 'Пушкина'
        WHEN 2 THEN 'Советская'
        WHEN 3 THEN 'Мира'
        ELSE 'Гагарина'
    END || ', д. ' || (random() * 100 + 1)::int ||
    CASE WHEN random() > 0.7 THEN ', к. ' || (random() * 10 + 1)::int ELSE '' END ||
    CASE WHEN random() > 0.8 THEN ', оф. ' || (random() * 100 + 1)::int ELSE '' END AS legal_address,
    CASE WHEN random() > 0.3 THEN NULL ELSE 
        'г. ' || 
        CASE (random() * 4)::int
            WHEN 0 THEN 'Москва'
            WHEN 1 THEN 'Санкт-Петербург'
            WHEN 2 THEN 'Ростов-на-Дону'
            WHEN 3 THEN 'Казань'
            ELSE 'Новосибирск'
        END || ', ул. ' || 
        CASE (random() * 5)::int
            WHEN 0 THEN 'Ленина'
            WHEN 1 THEN 'Пушкина'
            WHEN 2 THEN 'Советская'
            WHEN 3 THEN 'Мира'
            ELSE 'Гагарина'
        END || ', д. ' || (random() * 100 + 1)::int
    END AS actual_address,
    also.generate_random_phone() AS phone_primary,
    CASE WHEN random() > 0.6 THEN also.generate_random_phone() ELSE NULL END AS phone_secondary,
    LOWER(REPLACE(REPLACE(
        CASE (random() * 5)::int
            WHEN 0 THEN 'info'
            WHEN 1 THEN 'sales'
            WHEN 2 THEN 'zakaz'
            WHEN 3 THEN 'office'
            ELSE 'contact'
        END || '@' ||
        CASE (random() * 4)::int
            WHEN 0 THEN 'company'
            WHEN 1 THEN 'firm'
            WHEN 2 THEN 'trade'
            ELSE 'biz'
        END || 
        (random() * 99 + 1)::int || '.ru', ' ', ''), '-', '')) AS email_primary,
    CASE (random() * 6)::int
        WHEN 0 THEN 'Иванов Иван Иванович'
        WHEN 1 THEN 'Петров Петр Петрович'
        WHEN 2 THEN 'Сидорова Анна Сергеевна'
        WHEN 3 THEN 'Кузнецова Елена Владимировна'
        WHEN 4 THEN 'Смирнов Алексей Дмитриевич'
        ELSE 'Васильева Ольга Николаевна'
    END AS contact_person,
    CASE (random() * 5)::int
        WHEN 0 THEN 'Генеральный директор'
        WHEN 1 THEN 'Коммерческий директор'
        WHEN 2 THEN 'Начальник отдела снабжения'
        WHEN 3 THEN 'Главный инженер'
        ELSE 'Менеджер по закупкам'
    END AS contact_position,
    -- ИСПРАВЛЕНО: берём реальные manager_id из CTE
    (SELECT manager_id FROM manager_ids ORDER BY random() LIMIT 1) AS manager_id,
    CASE (random() * 4)::int
        WHEN 0 THEN 'Центральный'
        WHEN 1 THEN 'Северо-Западный'
        WHEN 2 THEN 'Южный'
        WHEN 3 THEN 'Приволжский'
        ELSE 'Сибирский'
    END AS region,
    CASE (random() * 9)::int
        WHEN 0 THEN 'Москва'
        WHEN 1 THEN 'Санкт-Петербург'
        WHEN 2 THEN 'Ростов-на-Дону'
        WHEN 3 THEN 'Казань'
        WHEN 4 THEN 'Новосибирск'
        WHEN 5 THEN 'Екатеринбург'
        WHEN 6 THEN 'Нижний Новгород'
        WHEN 7 THEN 'Самара'
        ELSE 'Краснодар'
    END AS city,
    LPAD((random() * 1000000)::int::text, 6, '0') AS postcode,
    CASE 
        WHEN random() > 0.7 THEN 0
        ELSE (random() * 5000000 + 100000)::int
    END AS credit_limit,
    CASE (random() * 4)::int
        WHEN 0 THEN 0
        WHEN 1 THEN 7
        WHEN 2 THEN 14
        WHEN 3 THEN 30
        ELSE 60
    END AS payment_delay_days,
    CASE 
        WHEN random() > 0.8 THEN 0
        ELSE (random() * 15)::int
    END AS discount_percent,
    CASE (random() * 20)::int
        WHEN 0 THEN 'Inactive'
        WHEN 1 THEN 'Blocked'
        WHEN 2 THEN 'Potential'
        ELSE 'Active'
    END AS client_status,
    (CURRENT_DATE - (random() * 365 * 5)::int) AS registration_date,
    random() < 0.1 AS is_vip
FROM generate_series(1, 100);

-- Чистим Справочник Клиенты
--TRUNCATE TABLE also.dim_customer RESTART IDENTITY;

-- =====================================================
-- Таблицы Фактов 
-- =====================================================


-- Создаем Факты Продажи
CREATE TABLE IF NOT EXISTS also.fact_sales (
    sale_id             SERIAL PRIMARY KEY,              -- Уникальный идентификатор продажи
    sale_date          DATE NOT NULL,                    -- Дата продажи
    product_id         INTEGER NOT NULL,                 -- Ссылка на продукт
    customer_id        INTEGER NOT NULL,                 -- Ссылка на клиента
    dealer_id          INTEGER,                          -- Ссылка на дилера (может быть NULL, если продажа напрямую)
    manager_id         INTEGER NOT NULL,                 -- Ссылка на менеджера
    branch_id          INTEGER NOT NULL,                 -- Ссылка на филиал
    quantity           INTEGER NOT NULL CHECK (quantity > 0), -- Количество
    unit_price         DECIMAL(12,2) NOT NULL,           -- Цена за единицу
    discount_amount    DECIMAL(12,2) DEFAULT 0,          -- Сумма скидки
    total_amount       DECIMAL(12,2) GENERATED ALWAYS AS 
                       (quantity * unit_price - discount_amount) STORED, -- Итоговая сумма
    payment_status     VARCHAR(20) DEFAULT 'Paid' 
                       CHECK (payment_status IN ('Paid', 'Pending', 'Overdue', 'Cancelled')), -- Статус оплаты
    delivery_status    VARCHAR(20) DEFAULT 'Delivered'
                       CHECK (delivery_status IN ('Pending', 'Shipped', 'Delivered', 'Cancelled')), -- Статус доставки
    invoice_number     VARCHAR(50),                      -- Номер счета/накладной
    comment            TEXT,                             -- Комментарий
    created_date       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Внешние ключи
    CONSTRAINT fk_sales_product FOREIGN KEY (product_id) 
        REFERENCES also.dim_product(product_id) ON DELETE RESTRICT,
    CONSTRAINT fk_sales_customer FOREIGN KEY (customer_id) 
        REFERENCES also.dim_customer(customer_id) ON DELETE RESTRICT,
    CONSTRAINT fk_sales_dealer FOREIGN KEY (dealer_id) 
        REFERENCES also.dim_dealer(dealer_id) ON DELETE RESTRICT,
    CONSTRAINT fk_sales_manager FOREIGN KEY (manager_id) 
        REFERENCES also.dim_manager(manager_id) ON DELETE RESTRICT,
    CONSTRAINT fk_sales_branch FOREIGN KEY (branch_id) 
        REFERENCES also.dim_branch(branch_id) ON DELETE RESTRICT,
    CONSTRAINT fk_sales_date FOREIGN KEY (sale_date) 
        REFERENCES also.dim_calendar(date_id) ON DELETE RESTRICT
);

-- Удаляем Факты Продажи
--DROP TABLE IF EXISTS also.fact_sales  CASCADE;

-- Наполняем Факты Продажи

-- Получаем все ID в переменные
DO $$
DECLARE
    -- Целевые показатели по годам
    v_target_revenue_mln DECIMAL[] := ARRAY[45, 52, 61, 78, 94, 113, 130];
    v_target_customers INTEGER[] := ARRAY[87, 95, 102, 110, 118, 125, 130];
    v_target_avg_check DECIMAL[] := ARRAY[15240, 16820, 18590, 20940, 23580, 26550, 29900];
    
    -- Коэффициенты сезонности по месяцам (БОЛЬШОЙ РАЗБРОС)
    -- Зимой мало клиентов, осенью много
    v_monthly_multiplier DECIMAL[] := ARRAY[
        0.35,  -- Январь (35% от годового максимума)
        0.40,  -- Февраль
        0.55,  -- Март
        0.65,  -- Апрель
        0.75,  -- Май
        0.85,  -- Июнь
        0.80,  -- Июль
        0.70,  -- Август
        0.90,  -- Сентябрь
        1.10,  -- Октябрь
        1.20,  -- Ноябрь
        1.15   -- Декабрь
    ];
    
    -- Массивы для случайных выборок
    v_customer_ids INTEGER[];
    v_product_ids INTEGER[];
    v_manager_ids INTEGER[];
    v_branch_ids INTEGER[];
    v_dealer_ids INTEGER[];
    
    v_customer_count INTEGER;
    v_product_count INTEGER;
    v_manager_count INTEGER;
    v_branch_count INTEGER;
    v_dealer_count INTEGER;
    
    v_year INTEGER;
    v_month INTEGER;
    v_month_index INTEGER;
    v_days_in_month INTEGER;
    v_rows_for_month INTEGER;
    v_customers_for_month INTEGER;
    v_max_customers_for_year INTEGER;
    v_base_revenue DECIMAL;
    v_date_ids DATE[];
    v_counter INTEGER := 0;
    v_year_index INTEGER;
BEGIN
    -- Загружаем все ID в массивы
    SELECT ARRAY_AGG(customer_id) INTO v_customer_ids
    FROM also.dim_customer WHERE client_status = 'Active' AND is_active = TRUE;
    v_customer_count := array_length(v_customer_ids, 1);
    
    SELECT ARRAY_AGG(product_id) INTO v_product_ids
    FROM also.dim_product WHERE is_active = TRUE;
    v_product_count := array_length(v_product_ids, 1);
    
    SELECT ARRAY_AGG(manager_id) INTO v_manager_ids
    FROM also.dim_manager WHERE is_active = TRUE;
    v_manager_count := array_length(v_manager_ids, 1);
    
    SELECT ARRAY_AGG(branch_id) INTO v_branch_ids
    FROM also.dim_branch WHERE is_active = TRUE;
    v_branch_count := array_length(v_branch_ids, 1);
    
    SELECT ARRAY_AGG(dealer_id) INTO v_dealer_ids
    FROM also.dim_dealer WHERE is_active = TRUE;
    v_dealer_count := array_length(v_dealer_ids, 1);
    
    RAISE NOTICE 'Загружено: клиентов %, продуктов %, менеджеров %', 
                 v_customer_count, v_product_count, v_manager_count;
    
    FOR v_year IN 2020..2026 LOOP
        v_year_index := v_year - 2019;
        
        -- Максимальное количество клиентов для года (в пиковый месяц)
        v_max_customers_for_year := (v_target_customers[v_year_index] * 1.2)::INTEGER;
        v_max_customers_for_year := LEAST(v_max_customers_for_year, v_customer_count);
        
        RAISE NOTICE '=== Год % (макс. клиентов: %) ===', v_year, v_max_customers_for_year;
        
        FOR v_month IN 1..12 LOOP
            v_month_index := v_month;
            
            -- Количество строк для месяца (сильно зависит от сезонности)
            v_rows_for_month := (v_target_revenue_mln[v_year_index] * 300 * v_monthly_multiplier[v_month_index])::INTEGER;
            v_rows_for_month := GREATEST(v_rows_for_month, 500);   -- минимум 500
            v_rows_for_month := LEAST(v_rows_for_month, 30000);    -- максимум 30000
            
            -- Количество уникальных клиентов для месяца (сильно зависит от сезонности)
            v_customers_for_month := (v_max_customers_for_year * v_monthly_multiplier[v_month_index])::INTEGER;
            v_customers_for_month := GREATEST(v_customers_for_month, 5);     -- минимум 5 клиентов
            v_customers_for_month := LEAST(v_customers_for_month, v_customer_count);
            
            -- Добавляем случайный фактор ±15% к количеству клиентов
            v_customers_for_month := (v_customers_for_month * (0.85 + random() * 0.3))::INTEGER;
            v_customers_for_month := GREATEST(v_customers_for_month, 5);
            v_customers_for_month := LEAST(v_customers_for_month, v_customer_count);
            
            -- Базовая выручка для расчёта среднего чека
            v_base_revenue := v_target_avg_check[v_year_index] / 10;
            
            RAISE NOTICE '  Месяц %: строк %, клиентов %, сезонность %', 
                         v_month, v_rows_for_month, v_customers_for_month, v_monthly_multiplier[v_month_index];
            
            -- Загружаем даты для конкретного месяца
            SELECT ARRAY_AGG(date_id) INTO v_date_ids
            FROM also.dim_calendar 
            WHERE EXTRACT(YEAR FROM date_id) = v_year 
              AND EXTRACT(MONTH FROM date_id) = v_month
              AND is_weekend = FALSE;
            
            IF array_length(v_date_ids, 1) IS NULL OR array_length(v_date_ids, 1) = 0 THEN
                CONTINUE;
            END IF;
            
            -- Вставляем данные для месяца
            INSERT INTO also.fact_sales (
                sale_date, product_id, customer_id, dealer_id, manager_id, branch_id,
                quantity, unit_price, discount_amount, payment_status, delivery_status, invoice_number
            )
            SELECT 
                -- Дата в рамках месяца
                v_date_ids[1 + floor(random() * array_length(v_date_ids, 1))],
                
                -- Продукт
                v_product_ids[1 + floor(random() * v_product_count)],
                
                -- Клиент (разные клиенты для разных месяцев)
                v_customer_ids[1 + floor(random() * v_customers_for_month)],
                
                -- Дилер (30% случаев)
                CASE WHEN random() < 0.3 
                     THEN v_dealer_ids[1 + floor(random() * v_dealer_count)]
                     ELSE NULL 
                END,
                
                -- Менеджер
                v_manager_ids[1 + floor(random() * v_manager_count)],
                
                -- Филиал
                v_branch_ids[1 + floor(random() * v_branch_count)],
                
                -- Количество (1-50)
                (1 + floor(random() * 49))::int,
                
                -- Цена (зависит от сезонности)
                v_base_revenue * (0.6 + random() * 0.8) * (0.8 + v_monthly_multiplier[v_month_index] * 0.4),
                
                -- Скидка
                CASE WHEN random() < 0.3 THEN random() * 5000 ELSE 0 END,
                
                -- Статус оплаты
                CASE 
                    WHEN random() < 0.85 THEN 'Paid'
                    WHEN random() < 0.92 THEN 'Pending'
                    WHEN random() < 0.96 THEN 'Overdue'
                    ELSE 'Cancelled'
                END,
                
                -- Статус доставки
                CASE 
                    WHEN random() < 0.75 THEN 'Delivered'
                    WHEN random() < 0.88 THEN 'Shipped'
                    ELSE 'Pending'
                END,
                
                -- Номер счета
                'INV-' || v_year || '-' || LPAD(v_month::text, 2, '0') || '-' || LPAD((random() * 10000)::int::text, 4, '0')
                
            FROM generate_series(1, v_rows_for_month);
            
            v_counter := v_counter + v_rows_for_month;
            
            COMMIT;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Завершено! Всего вставлено % записей.', v_counter;
END;
$$;

-- Чистим Факты Продажи
--TRUNCATE TABLE also.fact_sales RESTART IDENTITY

-- Оптимизация 
  
CREATE INDEX IF NOT EXISTS idx_fact_sales_product_id ON also.fact_sales(product_id);
CREATE INDEX IF NOT EXISTS idx_fact_sales_customer_id ON also.fact_sales(customer_id);
CREATE INDEX IF NOT EXISTS idx_fact_sales_manager_id ON also.fact_sales(manager_id);
CREATE INDEX IF NOT EXISTS idx_fact_sales_branch_id ON also.fact_sales(branch_id);
CREATE INDEX IF NOT EXISTS idx_fact_sales_dealer_id ON also.fact_sales(dealer_id);
CREATE INDEX IF NOT EXISTS idx_fact_sales_date ON also.fact_sales(sale_date);

----------------------------------------------------------------------------------------------------

-- Детальная витрина данных для проверки
/*explain analyze 
SELECT 
    f.sale_id,
    f.sale_date,
    p.product_code,
    cust.short_name AS customer,
    m.full_name AS manager,
    b.branch_name AS branch,
    d.short_name AS dealer,
    f.quantity,
    f.total_amount,
    f.payment_status
FROM also.fact_sales f
LEFT JOIN also.dim_product p ON f.product_id = p.product_id
LEFT JOIN also.dim_customer cust ON f.customer_id = cust.customer_id
LEFT JOIN also.dim_manager m ON f.manager_id = m.manager_id
LEFT JOIN also.dim_branch b ON f.branch_id = b.branch_id
LEFT JOIN also.dim_dealer d ON f.dealer_id = d.dealer_id*/


-- =====================================================
-- Планы по продажам
-- =====================================================

-- Создаем таблицу для заливки сырых данных из файла по плана на месяц по менеджерам
  
DROP TABLE IF EXISTS also.file_manager_plan;

CREATE TABLE also.file_manager_plan (
    id                  SERIAL PRIMARY KEY,
    plan_month          DATE NOT NULL,                  -- Месяц плана (формат: 01.01.2026)
    manager_full_name   VARCHAR(150) NOT NULL,          -- ФИО менеджера
    plan_revenue        DECIMAL(15,2) NOT NULL,         -- План по выручке (руб)
    plan_new_customers  INTEGER NOT NULL,               -- План по новым клиентам
    plan_quantity       INTEGER NOT NULL,               -- План по количеству товаров
    plan_transactions   INTEGER NOT NULL,               -- План по количеству сделок
    
    -- Служебные поля
    file_name           VARCHAR(255),                   -- Имя исходного файла
    upload_date         TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Дата загрузки
    is_processed        BOOLEAN DEFAULT FALSE,          -- Обработана ли запись
    processed_date      TIMESTAMP,                      -- Дата обработки
    error_message       TEXT,                           -- Сообщение об ошибке
    
    -- Уникальность: один план на менеджера в месяц
    CONSTRAINT uk_file_manager_plan UNIQUE (plan_month, manager_full_name)
);

-- Индексы для быстрого поиска
CREATE INDEX idx_file_plan_month ON also.file_manager_plan(plan_month);
CREATE INDEX idx_file_manager_name ON also.file_manager_plan(manager_full_name);
CREATE INDEX idx_file_processed ON also.file_manager_plan(is_processed);
CREATE INDEX idx_file_upload_date ON also.file_manager_plan(upload_date);  


-- =====================================================
-- Процедура: Перенос данных из file_manager_plan в manager_sales_plan
-- =====================================================

CREATE OR REPLACE PROCEDURE also.process_file_manager_plan()
LANGUAGE plpgsql
AS $$
DECLARE
    v_record RECORD;
    v_manager_id INTEGER;
    v_year INTEGER;
    v_month INTEGER;
    v_month_name VARCHAR(20);
    v_error_msg TEXT;
    v_processed_count INTEGER := 0;
    v_error_count INTEGER := 0;
BEGIN
    RAISE NOTICE 'Начинаем обработку файловых планов...';
    
    FOR v_record IN 
        SELECT * FROM also.file_manager_plan 
        WHERE is_processed = FALSE
        ORDER BY upload_date, plan_month
    LOOP
        BEGIN
            -- Получаем manager_id по ФИО
            SELECT manager_id INTO v_manager_id
            FROM also.dim_manager
            WHERE manager_name = v_record.manager_full_name
            LIMIT 1;
            
            IF v_manager_id IS NULL THEN
                v_error_msg := 'Менеджер не найден: ' || v_record.manager_full_name;
                RAISE EXCEPTION '%', v_error_msg;
            END IF;
            
            -- Извлекаем год и месяц из plan_month
            v_year := EXTRACT(YEAR FROM v_record.plan_month);
            v_month := EXTRACT(MONTH FROM v_record.plan_month);
            v_month_name := CASE v_month
                WHEN 1 THEN 'January' WHEN 2 THEN 'February' WHEN 3 THEN 'March'
                WHEN 4 THEN 'April' WHEN 5 THEN 'May' WHEN 6 THEN 'June'
                WHEN 7 THEN 'July' WHEN 8 THEN 'August' WHEN 9 THEN 'September'
                WHEN 10 THEN 'October' WHEN 11 THEN 'November' WHEN 12 THEN 'December'
            END;
            
            -- Вставляем или обновляем план в manager_sales_plan
            INSERT INTO also.manager_sales_plan (
                manager_id,
                year,
                month,
                month_name,
                plan_revenue,
                plan_quantity,
                plan_transactions,
                plan_customers,
                target_growth_percent,
                plan_status
            ) VALUES (
                v_manager_id,
                v_year,
                v_month,
                v_month_name,
                v_record.plan_revenue,
                v_record.plan_quantity,
                v_record.plan_transactions,
                v_record.plan_new_customers,
                NULL,  -- target_growth_percent будет рассчитан позже
                'Approved'
            )
            ON CONFLICT (manager_id, year, month) DO UPDATE SET
                plan_revenue = EXCLUDED.plan_revenue,
                plan_quantity = EXCLUDED.plan_quantity,
                plan_transactions = EXCLUDED.plan_transactions,
                plan_customers = EXCLUDED.plan_customers,
                plan_status = EXCLUDED.plan_status,
                updated_date = CURRENT_TIMESTAMP;
            
            -- Отмечаем запись как обработанную
            UPDATE also.file_manager_plan
            SET 
                is_processed = TRUE,
                processed_date = CURRENT_TIMESTAMP,
                error_message = NULL
            WHERE id = v_record.id;
            
            v_processed_count := v_processed_count + 1;
            
            IF v_processed_count % 100 = 0 THEN
                RAISE NOTICE 'Обработано % записей...', v_processed_count;
            END IF;
            
        EXCEPTION WHEN OTHERS THEN
            v_error_count := v_error_count + 1;
            v_error_msg := SQLERRM;
            
            UPDATE also.file_manager_plan
            SET 
                error_message = v_error_msg,
                processed_date = CURRENT_TIMESTAMP
            WHERE id = v_record.id;
            
            RAISE WARNING 'Ошибка при обработке ID %: %', v_record.id, v_error_msg;
        END;
    END LOOP;
    
    RAISE NOTICE 'Обработка завершена. Успешно: %, Ошибок: %', v_processed_count, v_error_count;
END;
$$;


-- Генерируем если нет файла- Планы продаж по менеджерам
CREATE TABLE also.manager_sales_plan (
    plan_id             SERIAL PRIMARY KEY,
    manager_id          INTEGER NOT NULL,
    year                INTEGER NOT NULL,
    month               INTEGER NOT NULL,
    month_name          VARCHAR(20),
    
    -- Плановые показатели
    plan_revenue        DECIMAL(15,2) NOT NULL,      -- План по выручке (руб)
    plan_quantity       INTEGER NOT NULL,            -- План по количеству товаров (шт)
    plan_transactions   INTEGER NOT NULL,            -- План по количеству сделок
    plan_customers      INTEGER NOT NULL,            -- План по новым клиентам
    
    -- Коэффициенты выполнения
    target_growth_percent DECIMAL(5,2),              -- Целевой рост к предыдущему периоду
    
    -- Статус плана
    plan_status         VARCHAR(20) DEFAULT 'Draft' 
                        CHECK (plan_status IN ('Draft', 'Approved', 'Achieved', 'Failed')),
    
    created_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Внешний ключ
    CONSTRAINT fk_plan_manager FOREIGN KEY (manager_id) 
        REFERENCES also.dim_manager(manager_id) ON DELETE CASCADE,
    
    -- Уникальность: один план на менеджера в месяц
    CONSTRAINT uk_manager_month UNIQUE (manager_id, year, month)
);

-- Индексы для быстрого доступа
CREATE INDEX idx_plan_manager ON also.manager_sales_plan(manager_id);
CREATE INDEX idx_plan_year_month ON also.manager_sales_plan(year, month);
CREATE INDEX idx_plan_status ON also.manager_sales_plan(plan_status);

-- Удаляем Планы продаж по менеджерам
--DROP TABLE IF EXISTS also.manager_sales_plan;

-- Наполняем Планы продаж по менеджерам
INSERT INTO also.manager_sales_plan (
    manager_id,
    year,
    month,
    month_name,
    plan_revenue,
    plan_quantity,
    plan_transactions,
    plan_customers,
    target_growth_percent,
    plan_status
)
WITH 
-- Фактические показатели по менеджерам за прошлые периоды
actual_stats AS (
    SELECT 
        f.manager_id,
        EXTRACT(YEAR FROM f.sale_date)::INTEGER AS year,
        EXTRACT(MONTH FROM f.sale_date)::INTEGER AS month,
        SUM(f.total_amount) AS actual_revenue,
        SUM(f.quantity) AS actual_quantity,
        COUNT(DISTINCT f.sale_id) AS actual_transactions,
        COUNT(DISTINCT f.customer_id) AS actual_customers
    FROM also.fact_sales f
    WHERE f.payment_status = 'Paid'
    GROUP BY f.manager_id, EXTRACT(YEAR FROM f.sale_date), EXTRACT(MONTH FROM f.sale_date)
),
-- Средние показатели по менеджерам за всё время
manager_avg AS (
    SELECT 
        manager_id,
        COALESCE(AVG(actual_revenue), 500000) AS avg_monthly_revenue,
        COALESCE(AVG(actual_quantity), 500) AS avg_monthly_quantity,
        COALESCE(AVG(actual_transactions), 50) AS avg_monthly_transactions,
        COALESCE(AVG(actual_customers), 5) AS avg_monthly_customers
    FROM actual_stats
    GROUP BY manager_id
),
-- Генерация всех комбинаций менеджер + месяц (2020-2026)
managers_list AS (
    SELECT manager_id FROM also.dim_manager WHERE is_active = TRUE
),
years_list AS (
    SELECT generate_series(2020, 2026) AS year
),
months_list AS (
    SELECT generate_series(1, 12) AS month
),
all_months AS (
    SELECT 
        m.manager_id,
        y.year,
        mo.month,
        CASE mo.month
            WHEN 1 THEN 'January'
            WHEN 2 THEN 'February'
            WHEN 3 THEN 'March'
            WHEN 4 THEN 'April'
            WHEN 5 THEN 'May'
            WHEN 6 THEN 'June'
            WHEN 7 THEN 'July'
            WHEN 8 THEN 'August'
            WHEN 9 THEN 'September'
            WHEN 10 THEN 'October'
            WHEN 11 THEN 'November'
            WHEN 12 THEN 'December'
        END AS month_name,
        -- Сезонный коэффициент
        CASE 
            WHEN mo.month IN (1, 2) THEN 0.85
            WHEN mo.month IN (3, 4, 5) THEN 0.95
            WHEN mo.month IN (6, 7, 8) THEN 1.00
            WHEN mo.month IN (9, 10) THEN 1.10
            WHEN mo.month IN (11, 12) THEN 1.15
            ELSE 1.0
        END AS seasonality,
        -- Коэффициент роста по годам
        CASE 
            WHEN y.year = 2020 THEN 1.0
            WHEN y.year = 2021 THEN 1.15
            WHEN y.year = 2022 THEN 1.32
            WHEN y.year = 2023 THEN 1.52
            WHEN y.year = 2024 THEN 1.75
            WHEN y.year = 2025 THEN 2.0
            WHEN y.year = 2026 THEN 2.2
            ELSE 1.0
        END AS year_growth
    FROM managers_list m
    CROSS JOIN years_list y
    CROSS JOIN months_list mo
)
SELECT 
    am.manager_id,
    am.year,
    am.month,
    am.month_name,
    
    -- План по выручке
    (COALESCE(ma.avg_monthly_revenue * 1.2, 600000) * 
     am.seasonality * am.year_growth *
     (0.85 + random() * 0.3))::DECIMAL(15,2) AS plan_revenue,
    
    -- План по количеству товаров
    GREATEST(
        (COALESCE(ma.avg_monthly_quantity * 1.2, 500) * 
         am.seasonality * am.year_growth *
         (0.85 + random() * 0.3))::INTEGER,
        10
    ) AS plan_quantity,
    
    -- План по количеству сделок
    GREATEST(
        (COALESCE(ma.avg_monthly_transactions * 1.2, 50) * 
         am.seasonality * am.year_growth *
         (0.85 + random() * 0.3))::INTEGER,
        5
    ) AS plan_transactions,
    
    -- План по новым клиентам
    GREATEST(
        (COALESCE(ma.avg_monthly_customers * 1.15, 5) * 
         am.seasonality *
         (0.7 + random() * 0.6))::INTEGER,
        1
    ) AS plan_customers,
    
    -- Целевой рост
    ROUND((10 + random() * 15)::NUMERIC, 1) AS target_growth_percent,
    
    'Approved' AS plan_status
    
FROM all_months am
LEFT JOIN manager_avg ma ON am.manager_id = ma.manager_id
ON CONFLICT (manager_id, year, month) DO UPDATE SET
    plan_revenue = EXCLUDED.plan_revenue,
    plan_quantity = EXCLUDED.plan_quantity,
    plan_transactions = EXCLUDED.plan_transactions,
    plan_customers = EXCLUDED.plan_customers,
    target_growth_percent = EXCLUDED.target_growth_percent,
    updated_date = CURRENT_TIMESTAMP;


/*SELECT 
    manager_id,
    year,
    month,
    month_name,
    ROUND(plan_revenue / 1000000, 2) AS plan_mln,
    plan_quantity,
    plan_transactions,
    plan_customers
FROM also.manager_sales_plan
WHERE year = 2026
ORDER BY manager_id, month
LIMIT 30;*/

-- Чистим Планы продаж по менеджерам
--TRUNCATE TABLE also.manager_sales_plan RESTART IDENTITY;


-- =====================================================
--  Обертки для Airflow
-- =====================================================


-- Данные из file_manager_plan в manager_sales_plan

CREATE OR REPLACE FUNCTION also.run_process_file_manager_plan()
RETURNS TEXT AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_unprocessed INTEGER;
    v_result TEXT;
BEGIN
    v_start_time := CURRENT_TIMESTAMP;
    
    -- Проверяем наличие необработанных записей
    SELECT COUNT(*) INTO v_unprocessed
    FROM also.file_manager_plan
    WHERE is_processed = FALSE;
    
    IF v_unprocessed = 0 THEN
        v_result := 'Нет необработанных записей для обработки';
        RAISE NOTICE '⚠️ %', v_result;
        RETURN v_result;
    END IF;
    
    RAISE NOTICE '🚀 Начинаем обработку % записей в %', v_unprocessed, v_start_time;
    
    -- Вызываем процедуру
    CALL also.process_file_manager_plan();
    
    v_end_time := CURRENT_TIMESTAMP;
    v_result := format('✅ Обработка завершена. Обработано: %s записей. Время: %s секунд', 
                       v_unprocessed, 
                       EXTRACT(SECOND FROM (v_end_time - v_start_time)));
    
    RAISE NOTICE '%', v_result;
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

--SELECT also.run_process_file_manager_plan();


-- Обновление Витрина 8: План-факт по менеджерам 

CREATE OR REPLACE FUNCTION also.refresh_mart_manager_plan_fact()
RETURNS TEXT AS $$
BEGIN
    DROP TABLE IF EXISTS also.mart_manager_plan_fact;
    
CREATE TABLE also.mart_manager_plan_fact AS
WITH 
-- Фактические показатели по менеджерам
actual_stats AS (
    SELECT 
        f.manager_id,
        EXTRACT(YEAR FROM f.sale_date)::INTEGER AS year,
        EXTRACT(MONTH FROM f.sale_date)::INTEGER AS month,
        SUM(f.total_amount) AS fact_revenue,
        SUM(f.quantity) AS fact_quantity,
        COUNT(DISTINCT f.sale_id) AS fact_transactions,
        COUNT(DISTINCT f.customer_id) AS fact_customers,
        COUNT(DISTINCT CASE WHEN cust.is_vip THEN f.customer_id END) AS fact_vip_customers,
        SUM(f.discount_amount) AS fact_discounts,
        ROUND(AVG(f.total_amount), 2) AS fact_avg_check
    FROM also.fact_sales f
    LEFT JOIN also.dim_customer cust ON f.customer_id = cust.customer_id
    WHERE f.payment_status = 'Paid'
    GROUP BY f.manager_id, EXTRACT(YEAR FROM f.sale_date), EXTRACT(MONTH FROM f.sale_date)
),
-- Плановые показатели
plan_stats AS (
    SELECT 
        manager_id,
        year,
        month,
        month_name,
        plan_revenue,
        plan_quantity,
        plan_transactions,
        plan_customers,
        target_growth_percent
    FROM also.manager_sales_plan
    WHERE plan_status = 'Approved'
)
SELECT 
    -- Период
    COALESCE(a.year, p.year) AS year,
    COALESCE(a.month, p.month) AS month,
    COALESCE(p.month_name, 
        CASE COALESCE(a.month, p.month)
            WHEN 1 THEN 'January' WHEN 2 THEN 'February' WHEN 3 THEN 'March'
            WHEN 4 THEN 'April' WHEN 5 THEN 'May' WHEN 6 THEN 'June'
            WHEN 7 THEN 'July' WHEN 8 THEN 'August' WHEN 9 THEN 'September'
            WHEN 10 THEN 'October' WHEN 11 THEN 'November' WHEN 12 THEN 'December'
        END
    ) AS month_name,
    
    -- Менеджер
    COALESCE(a.manager_id, p.manager_id) AS manager_id,
    m.manager_code,
    m.manager_name AS manager_name,  -- Исправлено: full_name → manager_name
    m.manager_level,
    m.department,
    b.branch_name,
    b.city AS branch_city,
    
    -- Добавлено поле user_name
    u.username AS username,
    
    -- Плановые показатели
    COALESCE(p.plan_revenue, 0) AS plan_revenue,
    COALESCE(p.plan_revenue, 0) / 1000000 AS plan_revenue_mln,
    COALESCE(p.plan_quantity, 0) AS plan_quantity,
    COALESCE(p.plan_transactions, 0) AS plan_transactions,
    COALESCE(p.plan_customers, 0) AS plan_customers,
    p.target_growth_percent,
    
    -- Фактические показатели
    COALESCE(a.fact_revenue, 0) AS fact_revenue,
    COALESCE(a.fact_revenue, 0) / 1000000 AS fact_revenue_mln,
    COALESCE(a.fact_quantity, 0) AS fact_quantity,
    COALESCE(a.fact_transactions, 0) AS fact_transactions,
    COALESCE(a.fact_customers, 0) AS fact_customers,
    COALESCE(a.fact_vip_customers, 0) AS fact_vip_customers,
    COALESCE(a.fact_discounts, 0) AS fact_discounts,
    COALESCE(a.fact_avg_check, 0) AS fact_avg_check,
    
    -- Процент выполнения плана
    CASE 
        WHEN COALESCE(p.plan_revenue, 0) > 0 
        THEN ROUND(100.0 * COALESCE(a.fact_revenue, 0) / p.plan_revenue, 2)
        ELSE 0
    END AS revenue_completion_percent,
    
    CASE 
        WHEN COALESCE(p.plan_quantity, 0) > 0 
        THEN ROUND(100.0 * COALESCE(a.fact_quantity, 0) / p.plan_quantity, 2)
        ELSE 0
    END AS quantity_completion_percent,
    
    CASE 
        WHEN COALESCE(p.plan_transactions, 0) > 0 
        THEN ROUND(100.0 * COALESCE(a.fact_transactions, 0) / p.plan_transactions, 2)
        ELSE 0
    END AS transactions_completion_percent,
    
    CASE 
        WHEN COALESCE(p.plan_customers, 0) > 0 
        THEN ROUND(100.0 * COALESCE(a.fact_customers, 0) / p.plan_customers, 2)
        ELSE 0
    END AS customers_completion_percent,
    
    -- Отклонения
    COALESCE(a.fact_revenue, 0) - COALESCE(p.plan_revenue, 0) AS revenue_variance,
    COALESCE(a.fact_quantity, 0) - COALESCE(p.plan_quantity, 0) AS quantity_variance,
    COALESCE(a.fact_transactions, 0) - COALESCE(p.plan_transactions, 0) AS transactions_variance,
    COALESCE(a.fact_customers, 0) - COALESCE(p.plan_customers, 0) AS customers_variance,
    
    -- Статус выполнения
    CASE 
        WHEN COALESCE(p.plan_revenue, 0) = 0 THEN 'Нет плана'
        WHEN COALESCE(a.fact_revenue, 0) >= p.plan_revenue THEN 'Выполнен'
        WHEN COALESCE(a.fact_revenue, 0) >= p.plan_revenue * 0.8 THEN 'Частично'
        WHEN COALESCE(a.fact_revenue, 0) >= p.plan_revenue * 0.6 THEN 'Отставание'
        ELSE 'Провал'
    END AS plan_status,
    
    -- Дополнительные метрики
    ROUND(COALESCE(a.fact_revenue, 0) / NULLIF(COALESCE(a.fact_transactions, 0), 0), 2) AS actual_avg_check,
    COALESCE(a.fact_revenue, 0) / NULLIF(COALESCE(a.fact_customers, 0), 0) AS revenue_per_customer,
    
    -- Дата расчёта
    CURRENT_DATE AS calculation_date
    
FROM plan_stats p
FULL OUTER JOIN actual_stats a ON p.manager_id = a.manager_id AND p.year = a.year AND p.month = a.month
LEFT JOIN also.dim_manager m ON COALESCE(a.manager_id, p.manager_id) = m.manager_id
LEFT JOIN also.dim_branch b ON m.branch_id = b.branch_id
LEFT JOIN also.dim_user u ON m.manager_id = u.manager_id
ORDER BY year DESC, month DESC, revenue_completion_percent DESC;

-- Создаём индексы
    CREATE INDEX idx_plan_fact_manager ON also.mart_manager_plan_fact(manager_id);
    CREATE INDEX idx_plan_fact_date ON also.mart_manager_plan_fact(year, month);
    CREATE INDEX idx_plan_fact_status ON also.mart_manager_plan_fact(plan_status);
    CREATE INDEX idx_plan_fact_completion ON also.mart_manager_plan_fact(revenue_completion_percent);
    CREATE INDEX idx_plan_fact_username ON also.mart_manager_plan_fact(username);
    
    ANALYZE also.mart_manager_plan_fact;
    
    RETURN '✅ Витрина обновлена';
END;
$$ LANGUAGE plpgsql;

--SELECT also.refresh_mart_manager_plan_fact();


-- Обновление Витрина 9: Сводная витрина план-факт по компании 

CREATE OR REPLACE FUNCTION also.refresh_mart_company_plan_fact()
RETURNS TEXT AS $$
BEGIN
    DROP TABLE IF EXISTS also.mart_company_plan_fact;
    
    CREATE TABLE also.mart_company_plan_fact AS
SELECT 
    year,
    month,
    month_name,
    
    -- Плановые показатели
    SUM(plan_revenue) AS total_plan_revenue,
    SUM(plan_quantity) AS total_plan_quantity,
    SUM(plan_transactions) AS total_plan_transactions,
    SUM(plan_customers) AS total_plan_customers,
    
    -- Фактические показатели
    SUM(fact_revenue) AS total_fact_revenue,
    SUM(fact_quantity) AS total_fact_quantity,
    SUM(fact_transactions) AS total_fact_transactions,
    SUM(fact_customers) AS total_fact_customers,
    
    -- Количество менеджеров
    COUNT(DISTINCT manager_id) AS managers_with_plan,
    COUNT(CASE WHEN fact_revenue > 0 THEN 1 END) AS managers_with_sales,
    
    -- Процент выполнения
    CASE 
        WHEN SUM(plan_revenue) > 0 
        THEN ROUND(100.0 * SUM(fact_revenue) / SUM(plan_revenue), 2)
        ELSE 0
    END AS company_revenue_completion_percent,
    
    -- Количество выполнивших план
    COUNT(CASE WHEN fact_revenue >= plan_revenue AND plan_revenue > 0 THEN 1 END) AS managers_achieved_plan,
    COUNT(CASE WHEN fact_revenue >= plan_revenue * 0.8 AND plan_revenue > 0 THEN 1 END) AS managers_good_performance,
    
    -- Процент выполнивших
    ROUND(100.0 * COUNT(CASE WHEN fact_revenue >= plan_revenue AND plan_revenue > 0 THEN 1 END) / 
          NULLIF(COUNT(CASE WHEN plan_revenue > 0 THEN 1 END), 0), 2) AS achievement_rate_percent
    
FROM also.mart_manager_plan_fact
GROUP BY year, month, month_name
ORDER BY year DESC, month DESC;

-- Индексы
CREATE INDEX idx_company_plan_fact_date ON also.mart_company_plan_fact(year, month);
    
    ANALYZE also.mart_company_plan_fact;
    
    RETURN '✅ Витрина обновлена';
END;
$$ LANGUAGE plpgsql;

--SELECT also.refresh_mart_company_plan_fact();


-- =====================================================
-- Витрины данных для BI
-- =====================================================

-- =====================================================
-- Витрина 1: Ежемесячные KPI по компании
-- Назначение: Верхнеуровневые показатели эффективности
-- =====================================================

DROP TABLE IF EXISTS also.mart_monthly_kpi;

CREATE TABLE also.mart_monthly_kpi AS
WITH sales_data AS (
    SELECT 
        DATE_TRUNC('month', f.sale_date) AS month_date,
        EXTRACT(YEAR FROM f.sale_date) AS year,
        EXTRACT(MONTH FROM f.sale_date) AS month_num,
        c.month_name,
        
        -- Базовые показатели
        COUNT(DISTINCT f.sale_id) AS total_transactions,
        SUM(f.quantity) AS total_units_sold,
        SUM(f.total_amount) AS total_revenue,
        SUM(f.discount_amount) AS total_discounts,
        ROUND(AVG(f.total_amount), 2) AS avg_check,
        
        -- Клиентские показатели
        COUNT(DISTINCT f.customer_id) AS active_customers,
        COUNT(DISTINCT CASE WHEN cust.is_vip THEN f.customer_id END) AS vip_customers_active,
        
        -- Продуктовые показатели
        COUNT(DISTINCT f.product_id) AS unique_products_sold,
        COUNT(DISTINCT p.crane_type_id) AS unique_crane_types,
        
        -- Эффективность продаж
        SUM(f.total_amount) / NULLIF(COUNT(DISTINCT f.manager_id), 0) AS revenue_per_manager,
        SUM(f.quantity) / NULLIF(COUNT(DISTINCT f.manager_id), 0) AS units_per_manager,
        
        -- Качество продаж
        COUNT(CASE WHEN f.payment_status = 'Paid' THEN 1 END) AS paid_transactions,
        COUNT(CASE WHEN f.payment_status = 'Pending' THEN 1 END) AS pending_transactions,
        COUNT(CASE WHEN f.payment_status = 'Overdue' THEN 1 END) AS overdue_transactions,
        COUNT(CASE WHEN f.payment_status = 'Cancelled' THEN 1 END) AS cancelled_transactions,
        
        SUM(CASE WHEN f.payment_status = 'Paid' THEN f.total_amount ELSE 0 END) AS revenue_paid,
        
        -- Каналы продаж
        COUNT(CASE WHEN f.dealer_id IS NOT NULL THEN 1 END) AS dealer_sales,
        SUM(CASE WHEN f.dealer_id IS NOT NULL THEN f.total_amount ELSE 0 END) AS dealer_revenue,
        COUNT(CASE WHEN f.dealer_id IS NULL THEN 1 END) AS direct_sales,
        SUM(CASE WHEN f.dealer_id IS NULL THEN f.total_amount ELSE 0 END) AS direct_revenue,
        
        -- География
        COUNT(DISTINCT b.city) AS branches_with_sales,
        COUNT(DISTINCT cust.city) AS cities_served
        
    FROM also.fact_sales f
    LEFT JOIN also.dim_customer cust ON f.customer_id = cust.customer_id
    LEFT JOIN also.dim_product p ON f.product_id = p.product_id
    LEFT JOIN also.dim_branch b ON f.branch_id = b.branch_id
    LEFT JOIN also.dim_calendar c ON f.sale_date = c.date_id
    WHERE f.payment_status != 'Cancelled'
    GROUP BY DATE_TRUNC('month', f.sale_date), EXTRACT(YEAR FROM f.sale_date), 
             EXTRACT(MONTH FROM f.sale_date), c.month_name
)
SELECT 
    month_date,
    year,
    month_num,
    month_name,
    
    -- KPI Основные
    total_transactions,
    total_units_sold,
    total_revenue,
    ROUND(total_revenue / 1000000, 2) AS revenue_mln,
    total_discounts,
    ROUND(100.0 * total_discounts / NULLIF(total_revenue + total_discounts, 0), 2) AS discount_rate_percent,
    avg_check,
    
    -- KPI Клиентские
    active_customers,
    vip_customers_active,
    ROUND(100.0 * vip_customers_active / NULLIF(active_customers, 0), 2) AS vip_percent,
    ROUND(total_revenue / NULLIF(active_customers, 0), 2) AS revenue_per_customer,
    ROUND(total_units_sold / NULLIF(active_customers, 0), 2) AS units_per_customer,
    
    -- KPI Продуктовые
    unique_products_sold,
    unique_crane_types,
    
    -- KPI Эффективность менеджеров
    revenue_per_manager,
    units_per_manager,
    
    -- KPI Качество продаж
    paid_transactions,
    pending_transactions,
    overdue_transactions,
    cancelled_transactions,
    ROUND(100.0 * paid_transactions / NULLIF(total_transactions, 0), 2) AS payment_success_rate,
    revenue_paid,
    ROUND(100.0 * revenue_paid / NULLIF(total_revenue, 0), 2) AS revenue_realized_rate,
    
    -- KPI Каналы продаж
    dealer_sales,
    dealer_revenue,
    direct_sales,
    direct_revenue,
    ROUND(100.0 * dealer_revenue / NULLIF(total_revenue, 0), 2) AS dealer_share_percent,
    
    -- KPI География
    branches_with_sales,
    cities_served,
    
    -- Дополнительные метрики
    ROUND(total_revenue / NULLIF(total_units_sold, 0), 2) AS avg_price_per_unit,
    ROUND(total_units_sold / NULLIF(total_transactions, 0), 2) AS avg_units_per_transaction,
    
    -- Метрики для сравнения (будем обновлять позже)
    NULL AS prev_month_revenue,
    NULL AS revenue_growth_percent,
    NULL AS prev_month_customers,
    NULL AS customers_growth_percent
    
FROM sales_data
ORDER BY month_date DESC;

-- Создаём индексы для быстрого доступа
CREATE INDEX idx_mart_monthly_date ON also.mart_monthly_kpi(month_date);
CREATE INDEX idx_mart_monthly_year ON also.mart_monthly_kpi(year);

-- Добавляем вычисления роста (Month-over-Month)
UPDATE also.mart_monthly_kpi m1
SET 
    prev_month_revenue = m2.total_revenue,
    revenue_growth_percent = ROUND(100.0 * (m1.total_revenue - m2.total_revenue) / NULLIF(m2.total_revenue, 0), 2),
    prev_month_customers = m2.active_customers,
    customers_growth_percent = ROUND(100.0 * (m1.active_customers - m2.active_customers) / NULLIF(m2.active_customers, 0), 2)
FROM also.mart_monthly_kpi m2
WHERE m1.month_date = m2.month_date + INTERVAL '1 month';



-- =====================================================
-- Витрина 2: Анализ продаж по видам кранов и продуктам
-- Назначение: Понимание продуктового портфеля
-- =====================================================

DROP TABLE IF EXISTS also.mart_product_mix_monthly;

CREATE TABLE also.mart_product_mix_monthly AS
SELECT 
    DATE_TRUNC('month', f.sale_date) AS month_date,
    EXTRACT(YEAR FROM f.sale_date) AS year,
    EXTRACT(MONTH FROM f.sale_date) AS month_num,
    
    -- Продуктовая аналитика
    ct.crane_type_id,
    ct.crane_name AS crane_type,
    ct.is_import_substitution,
    p.connection_type,
    p.diameter_dn,
    
    -- Показатели продаж
    COUNT(DISTINCT f.sale_id) AS sales_count,
    SUM(f.quantity) AS units_sold,
    SUM(f.total_amount) AS revenue,
    ROUND(AVG(f.unit_price), 2) AS avg_price,
    ROUND(AVG(f.discount_amount), 2) AS avg_discount,
    COUNT(DISTINCT f.customer_id) AS unique_customers,
    COUNT(DISTINCT f.manager_id) AS unique_managers,
    
    -- Доля в общей выручке (будет рассчитана позже)
    NULL AS revenue_share_percent,
    NULL AS rank_by_revenue
    
FROM also.fact_sales f
JOIN also.dim_product p ON f.product_id = p.product_id
JOIN also.dim_crane_type ct ON p.crane_type_id = ct.crane_type_id
WHERE f.payment_status = 'Paid'
GROUP BY DATE_TRUNC('month', f.sale_date), EXTRACT(YEAR FROM f.sale_date), 
         EXTRACT(MONTH FROM f.sale_date), ct.crane_type_id, ct.crane_name,
         ct.is_import_substitution, p.connection_type, p.diameter_dn
ORDER BY month_date DESC, revenue DESC;

CREATE INDEX idx_mart_product_month ON also.mart_product_mix_monthly(month_date);
CREATE INDEX idx_mart_product_type ON also.mart_product_mix_monthly(crane_type_id);


-- =====================================================
-- Витрина 3: Анализ продаж по регионам и филиалам
-- Назначение: Географическое распределение продаж
-- =====================================================

DROP TABLE IF EXISTS also.mart_regional_monthly;

CREATE TABLE also.mart_regional_monthly AS
SELECT 
    DATE_TRUNC('month', f.sale_date) AS month_date,
    EXTRACT(YEAR FROM f.sale_date) AS year,
    EXTRACT(MONTH FROM f.sale_date) AS month_num,
    
    -- Географические разрезы
    b.branch_id,
    b.branch_name,
    b.city AS branch_city,
    cust.region,
    cust.city AS customer_city,
    
    -- Показатели
    COUNT(DISTINCT f.sale_id) AS sales_count,
    SUM(f.quantity) AS units_sold,
    SUM(f.total_amount) AS revenue,
    COUNT(DISTINCT f.customer_id) AS unique_customers,
    COUNT(DISTINCT f.manager_id) AS active_managers,
    COUNT(DISTINCT CASE WHEN f.dealer_id IS NOT NULL THEN f.dealer_id END) AS active_dealers,
    
    -- Качество
    COUNT(CASE WHEN f.payment_status = 'Paid' THEN 1 END) AS paid_sales,
    SUM(CASE WHEN f.payment_status = 'Paid' THEN f.total_amount ELSE 0 END) AS revenue_paid,
    
    -- Аналитика по клиентам
    COUNT(DISTINCT CASE WHEN cust.is_vip THEN f.customer_id END) AS vip_customers,
    ROUND(SUM(f.total_amount) / NULLIF(COUNT(DISTINCT f.customer_id), 0), 2) AS revenue_per_customer
    
FROM also.fact_sales f
JOIN also.dim_branch b ON f.branch_id = b.branch_id
JOIN also.dim_customer cust ON f.customer_id = cust.customer_id
WHERE f.payment_status != 'Cancelled'
GROUP BY DATE_TRUNC('month', f.sale_date), EXTRACT(YEAR FROM f.sale_date), 
         EXTRACT(MONTH FROM f.sale_date), b.branch_id, b.branch_name, b.city,
         cust.region, cust.city
ORDER BY month_date DESC, revenue DESC;

CREATE INDEX idx_mart_regional_month ON also.mart_regional_monthly(month_date);
CREATE INDEX idx_mart_regional_branch ON also.mart_regional_monthly(branch_id);


-- =====================================================
-- Витрина 4: Анализ эффективности менеджеров
-- Назначение: Оценка работы команды продаж
-- =====================================================

DROP TABLE IF EXISTS also.mart_manager_performance_monthly;

-- Шаг 1: Агрегируем продажи по менеджерам и месяцам
CREATE TABLE also.mart_manager_performance_monthly AS
WITH 
-- Предварительно фильтруем и агрегируем данные фактов
sales_agg AS (
    SELECT 
        DATE_TRUNC('month', f.sale_date) AS month_date,
        f.manager_id,
        COUNT(DISTINCT f.sale_id) AS sales_count,
        SUM(f.quantity) AS units_sold,
        SUM(f.total_amount) AS revenue,
        ROUND(AVG(f.total_amount), 2) AS avg_check,
        COUNT(DISTINCT f.customer_id) AS unique_customers,
        COUNT(DISTINCT CASE WHEN f.dealer_id IS NOT NULL THEN f.dealer_id END) AS dealers_attracted,
        COUNT(CASE WHEN f.payment_status = 'Paid' THEN 1 END) AS paid_sales,
        SUM(CASE WHEN f.payment_status = 'Paid' THEN f.total_amount ELSE 0 END) AS revenue_paid,
        COUNT(CASE WHEN f.payment_status = 'Overdue' THEN 1 END) AS overdue_sales,
        COUNT(DISTINCT f.product_id) AS unique_products_sold
    FROM also.fact_sales f
    WHERE f.payment_status = 'Paid'
      AND f.sale_date >= '2020-01-01'
    GROUP BY DATE_TRUNC('month', f.sale_date), f.manager_id
),
-- Отдельно считаем VIP клиентов по менеджерам
vip_agg AS (
    SELECT 
        DATE_TRUNC('month', f.sale_date) AS month_date,
        f.manager_id,
        COUNT(DISTINCT cust.customer_id) AS vip_customers
    FROM also.fact_sales f
    JOIN also.dim_customer cust ON f.customer_id = cust.customer_id
    WHERE cust.is_vip = TRUE 
      AND f.payment_status = 'Paid'
    GROUP BY DATE_TRUNC('month', f.sale_date), f.manager_id
),
-- Отдельно считаем типы кранов
crane_agg AS (
    SELECT 
        DATE_TRUNC('month', f.sale_date) AS month_date,
        f.manager_id,
        COUNT(DISTINCT ct.crane_type_id) AS unique_crane_types
    FROM also.fact_sales f
    JOIN also.dim_product p ON f.product_id = p.product_id
    JOIN also.dim_crane_type ct ON p.crane_type_id = ct.crane_type_id
    WHERE f.payment_status = 'Paid'
    GROUP BY DATE_TRUNC('month', f.sale_date), f.manager_id
)
-- Собираем всё вместе
SELECT 
    sa.month_date,
    EXTRACT(YEAR FROM sa.month_date) AS year,
    EXTRACT(MONTH FROM sa.month_date) AS month_num,
    
    -- Менеджер
    m.manager_id,
    m.manager_code,
    m.manager_name AS manager_name,
    m.manager_level,
    m.department,
    b.branch_name,
    b.branch_id,
    m.sales_quota_year / 12 AS monthly_quota,
    
    -- Показатели из агрегации
    sa.sales_count,
    sa.units_sold,
    sa.revenue,
    sa.avg_check,
    sa.unique_customers,
    sa.dealers_attracted,
    sa.paid_sales,
    sa.revenue_paid,
    sa.overdue_sales,
    sa.unique_products_sold,
    
    -- Показатели из дополнительных агрегаций
    COALESCE(va.vip_customers, 0) AS vip_customers,
    COALESCE(ca.unique_crane_types, 0) AS unique_crane_types,
    
    -- Выручка на клиента
    CASE 
        WHEN sa.unique_customers > 0 
        THEN ROUND(sa.revenue / sa.unique_customers, 2)
        ELSE 0
    END AS revenue_per_customer,
    
    -- Расчётные показатели (будут заполнены позже)
    NULL AS quota_achievement_percent,
    NULL AS quota_status
    
FROM sales_agg sa
JOIN also.dim_manager m ON sa.manager_id = m.manager_id AND m.is_active = TRUE
JOIN also.dim_branch b ON m.branch_id = b.branch_id
LEFT JOIN vip_agg va ON sa.month_date = va.month_date AND sa.manager_id = va.manager_id
LEFT JOIN crane_agg ca ON sa.month_date = ca.month_date AND sa.manager_id = ca.manager_id;

-- Добавляем индексы
CREATE INDEX idx_mart_manager_month ON also.mart_manager_performance_monthly(month_date);
CREATE INDEX idx_mart_manager_id ON also.mart_manager_performance_monthly(manager_id);
CREATE INDEX idx_mart_manager_revenue ON also.mart_manager_performance_monthly(revenue DESC);

-- Обновляем показатели выполнения плана
UPDATE also.mart_manager_performance_monthly 
SET 
    quota_achievement_percent = CASE 
        WHEN monthly_quota > 0 THEN ROUND(100.0 * revenue / monthly_quota, 2)
        ELSE NULL
    END,
    quota_status = CASE 
        WHEN monthly_quota > 0 AND revenue >= monthly_quota THEN 'Выполнен'
        WHEN monthly_quota > 0 AND revenue >= monthly_quota * 0.8 THEN 'Хороший'
        WHEN monthly_quota > 0 AND revenue >= monthly_quota * 0.6 THEN 'Средний'
        WHEN monthly_quota > 0 AND revenue > 0 THEN 'Провал'
        ELSE 'Нет плана'
    END;



-- =====================================================
-- Витрина 5: Детальная аналитика по дням
-- Назначение: Оперативный мониторинг, выявление аномалий
-- =====================================================

DROP TABLE IF EXISTS also.mart_daily_details;

CREATE TABLE also.mart_daily_details AS
SELECT 
    f.sale_date,
    c.year,
    c.month AS month_num,  -- Исправлено: month вместо month_num
    c.month_name,
    c.day_of_month,
    c.day_name,
    c.is_weekend,
    c.week,
    
    -- Продажа
    f.sale_id,
    f.invoice_number,
    f.quantity,
    f.unit_price,
    f.discount_amount,
    f.total_amount,
    f.payment_status,
    f.delivery_status,
    
    -- Продукт
    p.product_code,
    p.product_name,
    ct.crane_name AS crane_type,
    p.diameter_dn,
    p.pressure_pn,
    p.connection_type,
    
    -- Клиент
    cust.customer_code,
    cust.short_name AS customer_name,
    cust.customer_type,
    cust.city AS customer_city,
    cust.region,
    cust.is_vip,
    cust.discount_percent AS customer_discount,
    
    -- Менеджер
    m.manager_code,
    m.manager_name AS manager_name,
    m.manager_level,
    
    -- Филиал
    b.branch_code,
    b.branch_name,
    b.city AS branch_city,
    
    -- Дилер
    d.dealer_code,
    d.short_name AS dealer_name,
    
    -- Флаги для аналитики
    CASE WHEN f.total_amount > 100000 THEN TRUE ELSE FALSE END AS is_big_sale,
    CASE WHEN f.discount_amount > 5000 THEN TRUE ELSE FALSE END AS has_big_discount,
    CASE WHEN f.quantity > 10 THEN TRUE ELSE FALSE END AS is_wholesale,
    CASE WHEN f.dealer_id IS NOT NULL THEN TRUE ELSE FALSE END AS is_dealer_sale
    
FROM also.fact_sales f
LEFT JOIN also.dim_calendar c ON f.sale_date = c.date_id
LEFT JOIN also.dim_product p ON f.product_id = p.product_id
LEFT JOIN also.dim_crane_type ct ON p.crane_type_id = ct.crane_type_id
LEFT JOIN also.dim_customer cust ON f.customer_id = cust.customer_id
LEFT JOIN also.dim_manager m ON f.manager_id = m.manager_id
LEFT JOIN also.dim_branch b ON f.branch_id = b.branch_id
LEFT JOIN also.dim_dealer d ON f.dealer_id = d.dealer_id
WHERE f.payment_status != 'Cancelled'
ORDER BY f.sale_date DESC, f.sale_id DESC;

-- Создаём индексы для быстрого доступа
CREATE INDEX IF NOT EXISTS idx_mart_daily_date ON also.mart_daily_details(sale_date);
CREATE INDEX IF NOT EXISTS idx_mart_daily_product ON also.mart_daily_details(product_code);
CREATE INDEX IF NOT EXISTS idx_mart_daily_customer ON also.mart_daily_details(customer_code);
CREATE INDEX IF NOT EXISTS idx_mart_daily_manager ON also.mart_daily_details(manager_code);
CREATE INDEX IF NOT EXISTS idx_mart_daily_payment ON also.mart_daily_details(payment_status);


-- =====================================================
-- Витрина 6: Аналитика по продуктам и клиентам (детальная)
-- Назначение: ABC-анализ, кросс-продажи, сегментация
-- =====================================================

DROP TABLE IF EXISTS also.mart_product_customer_agg;

-- Шаг 1: Агрегация по клиентам
CREATE TABLE also.mart_product_customer_agg AS
WITH 
-- Статистика по клиентам
customer_stats AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT sale_id) AS total_transactions,
        SUM(quantity) AS total_items,
        SUM(total_amount) AS total_spent,
        COUNT(DISTINCT product_id) AS unique_products,
        MIN(sale_date) AS first_purchase,
        MAX(sale_date) AS last_purchase,
        AVG(total_amount) AS avg_check,
        MODE() WITHIN GROUP (ORDER BY payment_status) AS typical_payment_status
    FROM also.fact_sales
    WHERE payment_status = 'Paid'
    GROUP BY customer_id
),
-- Статистика по продуктам
product_stats AS (
    SELECT 
        product_id,
        COUNT(DISTINCT sale_id) AS total_sales,
        SUM(quantity) AS total_units,
        SUM(total_amount) AS total_revenue,
        COUNT(DISTINCT customer_id) AS unique_customers,
        AVG(unit_price) AS avg_price
    FROM also.fact_sales
    WHERE payment_status = 'Paid'
    GROUP BY product_id
)
SELECT 
    f.sale_date,
    f.product_id,
    f.customer_id,
    f.quantity,
    f.total_amount,
    
    -- Продуктовые атрибуты
    p.product_code,
    p.product_name,
    ct.crane_name,
    ps.total_sales AS product_total_sales,
    ps.total_revenue AS product_total_revenue,
    
    -- Клиентские атрибуты
    cust.customer_code,
    cust.short_name AS customer_name,
    cust.customer_type,
    cust.region,
    cust.is_vip,
    cs.total_transactions AS customer_total_transactions,
    cs.total_spent AS customer_total_spent,
    cs.unique_products AS customer_unique_products,
    cs.first_purchase,
    cs.last_purchase,
    cs.avg_check AS customer_avg_check,
    
    -- Дополнительные метрики
    ROUND(100.0 * f.total_amount / NULLIF(cs.total_spent, 0), 2) AS pct_of_customer_spent,
    ROUND(100.0 * f.quantity / NULLIF(ps.total_units, 0), 2) AS pct_of_product_sales,
    
    -- Категории
    CASE 
        WHEN cs.total_spent > 1000000 THEN 'Platinum'
        WHEN cs.total_spent > 500000 THEN 'Gold'
        WHEN cs.total_spent > 100000 THEN 'Silver'
        WHEN cs.total_spent > 0 THEN 'Bronze'
        ELSE 'New'
    END AS customer_tier,
    
    CASE 
        WHEN ps.total_revenue > 1000000 THEN 'Top Product'
        WHEN ps.total_revenue > 500000 THEN 'Popular'
        WHEN ps.total_revenue > 100000 THEN 'Standard'
        ELSE 'Niche'
    END AS product_popularity
    
FROM also.fact_sales f
JOIN also.dim_product p ON f.product_id = p.product_id
JOIN also.dim_crane_type ct ON p.crane_type_id = ct.crane_type_id
JOIN also.dim_customer cust ON f.customer_id = cust.customer_id
LEFT JOIN customer_stats cs ON f.customer_id = cs.customer_id
LEFT JOIN product_stats ps ON f.product_id = ps.product_id
WHERE f.payment_status = 'Paid'
ORDER BY f.sale_date DESC;

-- Индексы
CREATE INDEX idx_mart_pc_agg_date ON also.mart_product_customer_agg(sale_date);
CREATE INDEX idx_mart_pc_agg_customer ON also.mart_product_customer_agg(customer_id);
CREATE INDEX idx_mart_pc_agg_product ON also.mart_product_customer_agg(product_id);
CREATE INDEX idx_mart_pc_agg_tier ON also.mart_product_customer_agg(customer_tier);


-- =====================================================
-- Витрина 7: Выявление аномалий и рисков
-- Назначение: Проактивное управление проблемами
-- =====================================================

DROP TABLE IF EXISTS also.mart_alerts_daily;

CREATE TABLE also.mart_alerts_daily AS
SELECT 
    CURRENT_DATE AS alert_date,
    f.sale_id,
    f.sale_date,
    f.invoice_number,
    
    -- Тип аномалии
    CASE 
        WHEN f.payment_status = 'Overdue' THEN 'Просрочка платежа'
        WHEN f.payment_status = 'Pending' AND f.sale_date < CURRENT_DATE - 7 THEN 'Долгая ожидаемая оплата'
        WHEN f.delivery_status = 'Pending' AND f.sale_date < CURRENT_DATE - 14 THEN 'Задержка доставки'
        WHEN f.delivery_status = 'Cancelled' THEN 'Отменённая доставка'
        WHEN f.discount_amount > f.total_amount * 0.3 THEN 'Аномально высокая скидка'
        WHEN f.quantity > 50 THEN 'Крупный опт (риск)'
        WHEN cust.credit_limit > 0 AND cust.total_purchases > cust.credit_limit THEN 'Превышение кредитного лимита'
        ELSE 'Другое'
    END AS alert_type,
    
    -- Приоритет (1 - критично, 2 - важно, 3 - информативно)
    CASE 
        WHEN f.payment_status = 'Overdue' THEN 1
        WHEN f.delivery_status = 'Cancelled' THEN 1
        WHEN cust.total_purchases > cust.credit_limit THEN 1
        WHEN f.payment_status = 'Pending' AND f.sale_date < CURRENT_DATE - 7 THEN 2
        WHEN f.delivery_status = 'Pending' AND f.sale_date < CURRENT_DATE - 14 THEN 2
        WHEN f.discount_amount > f.total_amount * 0.3 THEN 2
        ELSE 3
    END AS priority,
    
    -- Детали
    f.total_amount,
    f.payment_status,
    f.delivery_status,
    f.discount_amount,
    ROUND(100.0 * f.discount_amount / NULLIF(f.total_amount + f.discount_amount, 0), 2) AS discount_percent,
    
    -- Клиент
    cust.customer_code,
    cust.short_name AS customer_name,
    cust.credit_limit,
    cust.total_purchases,
    ROUND(100.0 * cust.total_purchases / NULLIF(cust.credit_limit, 0), 2) AS credit_limit_usage_percent,
    
    -- Менеджер
    m.manager_code,
    m.manager_name AS manager_name,
    m.phone_work AS manager_phone,
    
    -- Филиал
    b.branch_name,
    b.phone AS branch_phone
    
FROM also.fact_sales f
JOIN also.dim_customer cust ON f.customer_id = cust.customer_id
JOIN also.dim_manager m ON f.manager_id = m.manager_id
JOIN also.dim_branch b ON f.branch_id = b.branch_id
WHERE 
    -- Критерии аномалий
    f.payment_status IN ('Overdue', 'Pending')
    OR f.delivery_status IN ('Pending', 'Cancelled')
    OR f.discount_amount > f.total_amount * 0.3
    OR f.quantity > 50
    OR (cust.credit_limit > 0 AND cust.total_purchases > cust.credit_limit)
ORDER BY priority, f.sale_date;

CREATE INDEX idx_mart_alerts_priority ON also.mart_alerts_daily(priority);
CREATE INDEX idx_mart_alerts_type ON also.mart_alerts_daily(alert_type);


-- =====================================================
-- Витрина 8: План-факт по менеджерам
-- Назначение: Контроль за выполнением плана менеджерами
-- =====================================================

DROP TABLE IF EXISTS also.mart_manager_plan_fact;

CREATE TABLE also.mart_manager_plan_fact AS
WITH 
-- Фактические показатели по менеджерам
actual_stats AS (
    SELECT 
        f.manager_id,
        EXTRACT(YEAR FROM f.sale_date)::INTEGER AS year,
        EXTRACT(MONTH FROM f.sale_date)::INTEGER AS month,
        SUM(f.total_amount) AS fact_revenue,
        SUM(f.quantity) AS fact_quantity,
        COUNT(DISTINCT f.sale_id) AS fact_transactions,
        COUNT(DISTINCT f.customer_id) AS fact_customers,
        COUNT(DISTINCT CASE WHEN cust.is_vip THEN f.customer_id END) AS fact_vip_customers,
        SUM(f.discount_amount) AS fact_discounts,
        ROUND(AVG(f.total_amount), 2) AS fact_avg_check
    FROM also.fact_sales f
    LEFT JOIN also.dim_customer cust ON f.customer_id = cust.customer_id
    WHERE f.payment_status = 'Paid'
    GROUP BY f.manager_id, EXTRACT(YEAR FROM f.sale_date), EXTRACT(MONTH FROM f.sale_date)
),
-- Плановые показатели
plan_stats AS (
    SELECT 
        manager_id,
        year,
        month,
        month_name,
        plan_revenue,
        plan_quantity,
        plan_transactions,
        plan_customers,
        target_growth_percent
    FROM also.manager_sales_plan
    WHERE plan_status = 'Approved'
)
SELECT 
    -- Период
    COALESCE(a.year, p.year) AS year,
    COALESCE(a.month, p.month) AS month,
    COALESCE(p.month_name, 
        CASE COALESCE(a.month, p.month)
            WHEN 1 THEN 'January' WHEN 2 THEN 'February' WHEN 3 THEN 'March'
            WHEN 4 THEN 'April' WHEN 5 THEN 'May' WHEN 6 THEN 'June'
            WHEN 7 THEN 'July' WHEN 8 THEN 'August' WHEN 9 THEN 'September'
            WHEN 10 THEN 'October' WHEN 11 THEN 'November' WHEN 12 THEN 'December'
        END
    ) AS month_name,
    
    -- Менеджер
    COALESCE(a.manager_id, p.manager_id) AS manager_id,
    m.manager_code,
    m.manager_name AS manager_name,  -- Исправлено: full_name → manager_name
    m.manager_level,
    m.department,
    b.branch_name,
    b.city AS branch_city,
    
    -- Добавлено поле user_name
    u.username AS username,
    
    -- Плановые показатели
    COALESCE(p.plan_revenue, 0) AS plan_revenue,
    COALESCE(p.plan_revenue, 0) / 1000000 AS plan_revenue_mln,
    COALESCE(p.plan_quantity, 0) AS plan_quantity,
    COALESCE(p.plan_transactions, 0) AS plan_transactions,
    COALESCE(p.plan_customers, 0) AS plan_customers,
    p.target_growth_percent,
    
    -- Фактические показатели
    COALESCE(a.fact_revenue, 0) AS fact_revenue,
    COALESCE(a.fact_revenue, 0) / 1000000 AS fact_revenue_mln,
    COALESCE(a.fact_quantity, 0) AS fact_quantity,
    COALESCE(a.fact_transactions, 0) AS fact_transactions,
    COALESCE(a.fact_customers, 0) AS fact_customers,
    COALESCE(a.fact_vip_customers, 0) AS fact_vip_customers,
    COALESCE(a.fact_discounts, 0) AS fact_discounts,
    COALESCE(a.fact_avg_check, 0) AS fact_avg_check,
    
    -- Процент выполнения плана
    CASE 
        WHEN COALESCE(p.plan_revenue, 0) > 0 
        THEN ROUND(100.0 * COALESCE(a.fact_revenue, 0) / p.plan_revenue, 2)
        ELSE 0
    END AS revenue_completion_percent,
    
    CASE 
        WHEN COALESCE(p.plan_quantity, 0) > 0 
        THEN ROUND(100.0 * COALESCE(a.fact_quantity, 0) / p.plan_quantity, 2)
        ELSE 0
    END AS quantity_completion_percent,
    
    CASE 
        WHEN COALESCE(p.plan_transactions, 0) > 0 
        THEN ROUND(100.0 * COALESCE(a.fact_transactions, 0) / p.plan_transactions, 2)
        ELSE 0
    END AS transactions_completion_percent,
    
    CASE 
        WHEN COALESCE(p.plan_customers, 0) > 0 
        THEN ROUND(100.0 * COALESCE(a.fact_customers, 0) / p.plan_customers, 2)
        ELSE 0
    END AS customers_completion_percent,
    
    -- Отклонения
    COALESCE(a.fact_revenue, 0) - COALESCE(p.plan_revenue, 0) AS revenue_variance,
    COALESCE(a.fact_quantity, 0) - COALESCE(p.plan_quantity, 0) AS quantity_variance,
    COALESCE(a.fact_transactions, 0) - COALESCE(p.plan_transactions, 0) AS transactions_variance,
    COALESCE(a.fact_customers, 0) - COALESCE(p.plan_customers, 0) AS customers_variance,
    
    -- Статус выполнения
    CASE 
        WHEN COALESCE(p.plan_revenue, 0) = 0 THEN 'Нет плана'
        WHEN COALESCE(a.fact_revenue, 0) >= p.plan_revenue THEN 'Выполнен'
        WHEN COALESCE(a.fact_revenue, 0) >= p.plan_revenue * 0.8 THEN 'Частично'
        WHEN COALESCE(a.fact_revenue, 0) >= p.plan_revenue * 0.6 THEN 'Отставание'
        ELSE 'Провал'
    END AS plan_status,
    
    -- Дополнительные метрики
    ROUND(COALESCE(a.fact_revenue, 0) / NULLIF(COALESCE(a.fact_transactions, 0), 0), 2) AS actual_avg_check,
    COALESCE(a.fact_revenue, 0) / NULLIF(COALESCE(a.fact_customers, 0), 0) AS revenue_per_customer,
    
    -- Дата расчёта
    CURRENT_DATE AS calculation_date
    
FROM plan_stats p
FULL OUTER JOIN actual_stats a ON p.manager_id = a.manager_id AND p.year = a.year AND p.month = a.month
LEFT JOIN also.dim_manager m ON COALESCE(a.manager_id, p.manager_id) = m.manager_id
LEFT JOIN also.dim_branch b ON m.branch_id = b.branch_id
LEFT JOIN also.dim_user u ON m.manager_id = u.manager_id
ORDER BY year DESC, month DESC, revenue_completion_percent DESC;

-- Создаём индексы
CREATE INDEX idx_plan_fact_manager ON also.mart_manager_plan_fact(manager_id);
CREATE INDEX idx_plan_fact_date ON also.mart_manager_plan_fact(year, month);
CREATE INDEX idx_plan_fact_status ON also.mart_manager_plan_fact(plan_status);
CREATE INDEX idx_plan_fact_completion ON also.mart_manager_plan_fact(revenue_completion_percent);
CREATE INDEX idx_plan_fact_username ON also.mart_manager_plan_fact(username);


-- =====================================================
-- Витрина 9: Сводная витрина план-факт по компании 
-- Назначение: Контроль по компании за выполнением плана 
-- =====================================================


DROP TABLE IF EXISTS also.mart_company_plan_fact;

CREATE TABLE also.mart_company_plan_fact AS
SELECT 
    year,
    month,
    month_name,
    
    -- Плановые показатели
    SUM(plan_revenue) AS total_plan_revenue,
    SUM(plan_quantity) AS total_plan_quantity,
    SUM(plan_transactions) AS total_plan_transactions,
    SUM(plan_customers) AS total_plan_customers,
    
    -- Фактические показатели
    SUM(fact_revenue) AS total_fact_revenue,
    SUM(fact_quantity) AS total_fact_quantity,
    SUM(fact_transactions) AS total_fact_transactions,
    SUM(fact_customers) AS total_fact_customers,
    
    -- Количество менеджеров
    COUNT(DISTINCT manager_id) AS managers_with_plan,
    COUNT(CASE WHEN fact_revenue > 0 THEN 1 END) AS managers_with_sales,
    
    -- Процент выполнения
    CASE 
        WHEN SUM(plan_revenue) > 0 
        THEN ROUND(100.0 * SUM(fact_revenue) / SUM(plan_revenue), 2)
        ELSE 0
    END AS company_revenue_completion_percent,
    
    -- Количество выполнивших план
    COUNT(CASE WHEN fact_revenue >= plan_revenue AND plan_revenue > 0 THEN 1 END) AS managers_achieved_plan,
    COUNT(CASE WHEN fact_revenue >= plan_revenue * 0.8 AND plan_revenue > 0 THEN 1 END) AS managers_good_performance,
    
    -- Процент выполнивших
    ROUND(100.0 * COUNT(CASE WHEN fact_revenue >= plan_revenue AND plan_revenue > 0 THEN 1 END) / 
          NULLIF(COUNT(CASE WHEN plan_revenue > 0 THEN 1 END), 0), 2) AS achievement_rate_percent
    
FROM also.mart_manager_plan_fact
GROUP BY year, month, month_name
ORDER BY year DESC, month DESC;

-- Индексы
CREATE INDEX idx_company_plan_fact_date ON also.mart_company_plan_fact(year, month);


-- =====================================================
-- Служебная часть
-- =====================================================

-- Сбор статистики по объектам схемы

DO $$
DECLARE
    v_rel RECORD;
    v_count INTEGER := 0;
BEGIN
    FOR v_rel IN 
        SELECT 
            n.nspname AS schema_name,
            c.relname AS object_name,
            CASE c.relkind
                WHEN 'r' THEN 'TABLE'
                WHEN 'm' THEN 'MATERIALIZED VIEW'
                WHEN 'i' THEN 'INDEX'
                ELSE c.relkind::text
            END AS object_type
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'also'
          AND c.relkind IN ('r', 'm')  -- таблицы и мат.вью
        ORDER BY c.relname
    LOOP
        EXECUTE format('ANALYZE also.%I', v_rel.object_name);
        v_count := v_count + 1;
        RAISE NOTICE '✅ %: also.%', v_rel.object_type, v_rel.object_name;
    END LOOP;
    RAISE NOTICE '📊 Завершено. Проанализировано объектов: %', v_count;
END;
$$;

--  Размер схемы also
SELECT 
    pg_size_pretty(SUM(pg_total_relation_size(schemaname || '.' || tablename))) AS total_size
FROM pg_tables
WHERE schemaname = 'also';

--  Размер объектов схемы also

SELECT 
    tablename AS table_name,
    pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname || '.' || tablename)) AS table_size,
    pg_size_pretty(pg_indexes_size(schemaname || '.' || tablename)) AS indexes_size,
    pg_total_relation_size(schemaname || '.' || tablename) AS size_bytes,
    -- Количество строк (приблизительно)
    (SELECT reltuples::bigint 
     FROM pg_class 
     WHERE relname = tablename 
       AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = schemaname)) AS estimated_rows
FROM pg_tables
WHERE schemaname = 'also'
ORDER BY pg_total_relation_size(schemaname || '.' || tablename) DESC;