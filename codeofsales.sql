


DROP FUNCTION IF EXISTS generate_sales_summary(DATE, DATE);

------------new generate_sales_summary

CREATE OR REPLACE FUNCTION generate_sales_summary(
    p_start_date DATE,
    p_end_date   DATE
)
RETURNS VOID AS $$
DECLARE
    v_task_id BIGINT;

    -- Core KPIs
    v_total_sales NUMERIC;
    v_total_transactions INT;
    v_avg_sale NUMERIC;

    -- Business KPIs
    v_top_category VARCHAR(50);
    v_top_region VARCHAR(50);
    v_top_product VARCHAR(80);
    v_worst_category VARCHAR(50);
    v_max_sale NUMERIC(12,2);

    -- Trend
    v_prev_total_sales NUMERIC;
    v_sales_trend VARCHAR(10);
BEGIN
    -- 1️⃣ Prevent duplicate reports
    IF EXISTS (
        SELECT 1
        FROM summary_report
        WHERE start_date = p_start_date
          AND end_date = p_end_date
    ) THEN
        RETURN;
    END IF;

    -- 2️⃣ Create report task
    INSERT INTO report_task (
        trigger_id,
        status,
        task_type,
        task_start,
        task_end
    )
    VALUES (
        1,
        'SUCCESS',
        'AUTOMATED',
        NOW(),
        NOW()
    )
    RETURNING task_id INTO v_task_id;

    -- 3️⃣ Core KPIs
    SELECT
        COALESCE(SUM(amount),0),
        COUNT(*),
        COALESCE(AVG(amount),0)
    INTO
        v_total_sales,
        v_total_transactions,
        v_avg_sale
    FROM raw_sale
    WHERE sale_date BETWEEN p_start_date AND p_end_date;

    -- 4️⃣ Top category
    SELECT category
    INTO v_top_category
    FROM raw_sale
    WHERE sale_date BETWEEN p_start_date AND p_end_date
    GROUP BY category
    ORDER BY SUM(amount) DESC
    LIMIT 1;

    -- 5️⃣ Worst category
    SELECT category
    INTO v_worst_category
    FROM raw_sale
    WHERE sale_date BETWEEN p_start_date AND p_end_date
    GROUP BY category
    ORDER BY SUM(amount) ASC
    LIMIT 1;

    -- 6️⃣ Top region
    SELECT region
    INTO v_top_region
    FROM raw_sale
    WHERE sale_date BETWEEN p_start_date AND p_end_date
    GROUP BY region
    ORDER BY SUM(amount) DESC
    LIMIT 1;

    -- 7️⃣ Top product
    SELECT product
    INTO v_top_product
    FROM raw_sale
    WHERE sale_date BETWEEN p_start_date AND p_end_date
    GROUP BY product
    ORDER BY SUM(amount) DESC
    LIMIT 1;

    -- 8️⃣ Max single sale
    SELECT MAX(amount)
    INTO v_max_sale
    FROM raw_sale
    WHERE sale_date BETWEEN p_start_date AND p_end_date;

    -- 9️⃣ Previous period sales (for trend)
    SELECT COALESCE(SUM(amount),0)
    INTO v_prev_total_sales
    FROM raw_sale
    WHERE sale_date BETWEEN
          (p_start_date - (p_end_date - p_start_date))
          AND (p_start_date - INTERVAL '1 day');

    IF v_total_sales > v_prev_total_sales THEN
        v_sales_trend := 'UP';
    ELSIF v_total_sales < v_prev_total_sales THEN
        v_sales_trend := 'DOWN';
    ELSE
        v_sales_trend := 'STABLE';
    END IF;

    -- 🔟 Insert summary report
    INSERT INTO summary_report (
        task_id,
        start_date,
        end_date,
        total_sales,
        total_transactions,
        avg_sale,
        top_category,
        top_region,
        top_product,
        worst_category,
        max_sale,
        sales_trend,
        generated_at
    )
    VALUES (
        v_task_id,
        p_start_date,
        p_end_date,
        v_total_sales,
        v_total_transactions,
        v_avg_sale,
        v_top_category,
        v_top_region,
        v_top_product,
        v_worst_category,
        v_max_sale,
        v_sales_trend,
        NOW()
    );
END;
$$ LANGUAGE plpgsql;

-------END




SELECT * FROM report_task;
SELECT * FROM summary_report;


CREATE OR REPLACE FUNCTION trg_auto_generate_report()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate report for last 14 days (explicit DATE cast)
    PERFORM generate_sales_summary(
        (CURRENT_DATE - INTERVAL '14 days')::DATE,
        CURRENT_DATE
    );
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


	

CREATE TRIGGER after_raw_sale_insert
AFTER INSERT ON raw_sale
FOR EACH STATEMENT
EXECUTE FUNCTION trg_auto_generate_report();


CREATE OR REPLACE FUNCTION trg_log_report_creation()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO automation_log (task_id, event_type, message)
    VALUES (
        NEW.task_id,
        'REPORT_GENERATED',
        'Sales summary report generated successfully'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_summary_report_insert
AFTER INSERT ON summary_report
FOR EACH ROW
EXECUTE FUNCTION trg_log_report_creation();


INSERT INTO raw_sale (source_id, sale_date, amount, product, category, region)
SELECT source_id, CURRENT_DATE, 150, 'Laptop', 'Electronics', 'North'
FROM data_source
LIMIT 1;


SELECT * FROM report_task ORDER BY task_id DESC;
SELECT * FROM summary_report ORDER BY report_id DESC;
SELECT * FROM automation_log ORDER BY log_id DESC;

SELECT * 
FROM raw_sale
ORDER BY sale_date DESC;


SELECT sale_id, sale_date, amount, product, category
FROM raw_sale
WHERE category = 'Electronics';


SELECT sale_id, sale_date, amount, region
FROM raw_sale
WHERE region = 'North';

SELECT *
FROM summary_report
ORDER BY generated_at DESC;

SELECT *
FROM automation_log
ORDER BY created_at DESC;


SELECT
    category,
    SUM(amount) AS total_sales
FROM raw_sale
GROUP BY category
ORDER BY total_sales DESC;


SELECT
    region,
    SUM(amount) AS total_sales
FROM raw_sale
GROUP BY region
ORDER BY total_sales DESC;


SELECT
    region,
    SUM(amount) AS total_sales
FROM raw_sale
GROUP BY region
ORDER BY total_sales DESC;


SELECT
    product,
    AVG(amount) AS avg_sale
FROM raw_sale
GROUP BY product
ORDER BY avg_sale DESC;


SELECT
    sale_date,
    COUNT(*) AS transactions
FROM raw_sale
GROUP BY sale_date
ORDER BY sale_date;

SELECT
    rt.trigger_name,
    COUNT(t.task_id) AS reports_generated
FROM report_trigger rt
JOIN report_task t ON rt.trigger_id = t.trigger_id
GROUP BY rt.trigger_name;

SELECT
    r.report_id,
    r.total_sales,
    r.total_transactions,
    t.status,
    rt.trigger_name
FROM summary_report r
JOIN report_task t ON r.task_id = t.task_id
JOIN report_trigger rt ON t.trigger_id = rt.trigger_id;


SELECT current_database();

SELECT * FROM summary_report LIMIT 1;

ALTER TABLE summary_report
ADD COLUMN top_region VARCHAR(50);

ALTER TABLE summary_report
ADD COLUMN top_product VARCHAR(80),
ADD COLUMN worst_category VARCHAR(50),
ADD COLUMN max_sale NUMERIC(12,2),
ADD COLUMN sales_trend VARCHAR(10)
    CHECK (sales_trend IN ('UP', 'DOWN', 'STABLE'));


SELECT generate_sales_summary(
    (CURRENT_DATE - INTERVAL '14 days')::DATE,
    CURRENT_DATE::DATE
);

SELECT
    report_id,
    start_date,
    end_date,
    total_sales,
    total_transactions,
    avg_sale,
    top_product,
    top_category,
    top_region,
    worst_category,
    max_sale,
    sales_trend,
    generated_at
FROM summary_report
ORDER BY generated_at DESC
LIMIT 1;


SELECT
    task_id,
    status,
    task_type,
    task_start,
    task_end
FROM report_task
ORDER BY task_id DESC
LIMIT 1;

SELECT
    event_type,
    message,
    created_at
FROM automation_log
ORDER BY created_at DESC
LIMIT 5;

CREATE OR REPLACE VIEW vw_sales_by_category AS
SELECT
    category,
    COUNT(*)        AS transactions,
    SUM(amount)     AS total_sales,
    AVG(amount)     AS avg_sale
FROM raw_sale
GROUP BY category;

CREATE OR REPLACE VIEW vw_daily_sales AS
SELECT
    sale_date,
    COUNT(*)    AS transactions,
    SUM(amount) AS total_sales
FROM raw_sale
GROUP BY sale_date
ORDER BY sale_date;

CREATE OR REPLACE PROCEDURE sp_generate_sales_summary(
    p_start_date DATE,
    p_end_date   DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM generate_sales_summary(p_start_date, p_end_date);
END;
$$;








