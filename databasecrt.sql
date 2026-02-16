-- =========================
-- 0) Optional: clean reset
-- =========================
-- DROP SCHEMA public CASCADE;
-- CREATE SCHEMA public;

-- =========================
-- 1) USERS (supertype + role via discriminator)
-- =========================
CREATE TABLE app_user (
    user_id        BIGSERIAL PRIMARY KEY,
    username       VARCHAR(50) NOT NULL UNIQUE,
    password_hash  TEXT NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    user_type      VARCHAR(20) NOT NULL CHECK (user_type IN ('ADMIN', 'BUSINESS'))
);

-- Optional subtype tables (useful for your EER explanation)
CREATE TABLE admin_user (
    user_id     BIGINT PRIMARY KEY REFERENCES app_user(user_id) ON DELETE CASCADE,
    admin_level VARCHAR(20) NOT NULL DEFAULT 'STANDARD'
);

CREATE TABLE business_user (
    user_id     BIGINT PRIMARY KEY REFERENCES app_user(user_id) ON DELETE CASCADE,
    department  VARCHAR(50)
);

-- =========================
-- 2) DATA SOURCE (supertype)
-- =========================
CREATE TABLE data_source (
    source_id    BIGSERIAL PRIMARY KEY,
    source_type  VARCHAR(20) NOT NULL CHECK (source_type IN ('FILE', 'API')),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- FILE_UPLOAD subtype
CREATE TABLE file_upload (
    source_id     BIGINT PRIMARY KEY REFERENCES data_source(source_id) ON DELETE CASCADE,
    file_name     TEXT NOT NULL,
    upload_date   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    row_count     INT NOT NULL DEFAULT 0 CHECK (row_count >= 0),
    uploaded_by   BIGINT NOT NULL REFERENCES app_user(user_id)
);

-- API_SOURCE subtype (future-ready)
CREATE TABLE api_source (
    source_id   BIGINT PRIMARY KEY REFERENCES data_source(source_id) ON DELETE CASCADE,
    endpoint    TEXT NOT NULL,
    frequency   VARCHAR(30) NOT NULL
);

-- =========================
-- 3) RAW SALES (transactional input)
-- =========================
CREATE TABLE raw_sale (
    sale_id     BIGSERIAL PRIMARY KEY,
    source_id   BIGINT NOT NULL REFERENCES data_source(source_id) ON DELETE RESTRICT,
    sale_date   DATE NOT NULL,
    amount      NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    product     VARCHAR(80) NOT NULL,
    category    VARCHAR(50) NOT NULL,
    region      VARCHAR(40) NOT NULL
);

CREATE INDEX idx_raw_sale_date ON raw_sale(sale_date);
CREATE INDEX idx_raw_sale_source ON raw_sale(source_id);

-- =========================
-- 4) REPORT TRIGGERS (automation controller)
-- =========================
CREATE TABLE report_trigger (
    trigger_id    BIGSERIAL PRIMARY KEY,
    trigger_name  VARCHAR(80) NOT NULL UNIQUE,
    description   TEXT,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE
);

-- =========================
-- 5) REPORT TASKS (processing executions)
-- =========================
CREATE TABLE report_task (
    task_id      BIGSERIAL PRIMARY KEY,
    trigger_id   BIGINT REFERENCES report_trigger(trigger_id),
    task_start   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    task_end     TIMESTAMPTZ,
    status       VARCHAR(20) NOT NULL CHECK (status IN ('PENDING','RUNNING','SUCCESS','FAILED')),
    task_type    VARCHAR(20) NOT NULL CHECK (task_type IN ('AUTOMATED','MANUAL')),
    requested_by BIGINT REFERENCES app_user(user_id)
);

-- =========================
-- 6) SUMMARY REPORT (time-variant output)
-- =========================
CREATE TABLE summary_report (
    report_id            BIGSERIAL PRIMARY KEY,
    task_id              BIGINT NOT NULL UNIQUE REFERENCES report_task(task_id) ON DELETE CASCADE,
    start_date           DATE NOT NULL,
    end_date             DATE NOT NULL,
    total_sales          NUMERIC(14,2) NOT NULL,
    total_transactions   INT NOT NULL,
    avg_sale             NUMERIC(14,2) NOT NULL,
    generated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (start_date <= end_date)
);

-- =========================
-- 7) AUTOMATION LOGS (audit trail)
-- =========================
CREATE TABLE automation_log (
    log_id      BIGSERIAL PRIMARY KEY,
    task_id     BIGINT NOT NULL REFERENCES report_task(task_id) ON DELETE CASCADE,
    event_type  VARCHAR(30) NOT NULL,
    message     TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_log_task ON automation_log(task_id);

-- Subtypes AUTOMATED_TASK and MANUAL_TASK implemented via task_type discriminator

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;


INSERT INTO app_user (username, password_hash, user_type)
VALUES
('admin1', 'hashed_admin_pw', 'ADMIN'),
('user1',  'hashed_user_pw',  'BUSINESS');


INSERT INTO admin_user (user_id, admin_level)
SELECT user_id, 'SUPER'
FROM app_user
WHERE username = 'admin1';

INSERT INTO business_user (user_id, department)
SELECT user_id, 'Sales'
FROM app_user
WHERE username = 'user1';


SELECT * FROM app_user;
SELECT * FROM admin_user;
SELECT * FROM business_user;

INSERT INTO report_trigger (trigger_name, description, is_active)
VALUES (
  'AUTO_SALES_REPORT',
  'Automatically generates sales summary after data insertion',
  TRUE
);

SELECT * FROM report_trigger;

INSERT INTO data_source (source_type)
VALUES ('FILE');

SELECT * FROM data_source;


INSERT INTO file_upload (source_id, file_name, uploaded_by)
SELECT
    ds.source_id,
    'sales_week_01.csv',
    u.user_id
FROM data_source ds
JOIN app_user u ON u.username = 'user1'
ORDER BY ds.source_id DESC
LIMIT 1;

SELECT * FROM file_upload;


INSERT INTO raw_sale (source_id, sale_date, amount, product, category, region)
SELECT
    fu.source_id,
    DATE '2025-10-01' + (random() * 14)::int,
    ROUND((20 + random() * 500)::numeric, 2),
    (ARRAY['Laptop','Phone','Tablet','Monitor','Keyboard'])[1 + (random()*4)::int],
    (ARRAY['Electronics','Accessories','Office'])[1 + (random()*2)::int],
    (ARRAY['North','South','East','West'])[1 + (random()*3)::int]
FROM file_upload fu
CROSS JOIN generate_series(1, 200);


UPDATE file_upload
SET row_count = (
    SELECT COUNT(*)
    FROM raw_sale
    WHERE raw_sale.source_id = file_upload.source_id
);


SELECT
    (SELECT COUNT(*) FROM app_user)     AS users,
    (SELECT COUNT(*) FROM file_upload) AS uploads,
    (SELECT COUNT(*) FROM raw_sale)    AS raw_sales;


	
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'summary_report'
ORDER BY ordinal_position;

DELETE FROM summary_report;
DELETE FROM report_task;
DELETE FROM automation_log;






