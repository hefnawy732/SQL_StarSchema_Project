USE cleaning_project;

-- Preview a sample of the raw cleaned dataset
SELECT * FROM cafe_sales_cleaned LIMIT 10;

-- ========================
-- DIMENSION TABLES
-- ========================

-- 1. Create dim_product table: contains unique products and their prices
CREATE TABLE dim_product (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(50),
    unit_price DECIMAL(10,2),
    UNIQUE(product_name,unite_price)
);

-- Insert distinct products; handle NULL items by combining with price to avoid FK issues
INSERT INTO dim_product (product_name, unit_price)
SELECT DISTINCT 
    CASE 
        WHEN item IS NULL THEN CONCAT('N/A - ', price_per_unit)
        ELSE item
    END AS product_name,
    price_per_unit
FROM cafe_sales_cleaned;

-- 2. Create dim_payment_method: contains unique payment methods
CREATE TABLE dim_payment_method (
    payment_method_id INT AUTO_INCREMENT PRIMARY KEY,
    payment_method_name VARCHAR(50) UNIQUE
);


-- Insert payment methods; use 'N/A' for NULLs to maintain referential integrity
INSERT INTO dim_payment_method (payment_method_name)
SELECT DISTINCT COALESCE(payment_method, 'N/A')
FROM cafe_sales_cleaned;

-- check
SELECT * FROM dim_payment_method;

-- 3. Create dim_location: contains unique location types
CREATE TABLE dim_location(
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    location_type VARCHAR(50) UNIQUE
);

-- Insert location values; use 'N/A' for NULLs
INSERT INTO dim_location (location_type)
SELECT DISTINCT COALESCE(location, 'N/A')
FROM cafe_sales_cleaned;

-- check
SELECT * FROM dim_location;

-- 4. Create dim_date: full calendar role_playing dimension (2023 only)
CREATE TABLE dim_date (
    date_id DATE PRIMARY KEY,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(20),
    week INT,
    day INT,
    day_of_week VARCHAR(10),
    is_weekend BOOLEAN
);

-- Populate dim_date dynamically (up to 365 days from '2023-01-01')
INSERT INTO dim_date (
    date_id, year, quarter, month, month_name, week, day, day_of_week, is_weekend
)
SELECT
    DATE_ADD('2023-01-01', INTERVAL n DAY) AS date_id,
    YEAR(DATE_ADD('2023-01-01', INTERVAL n DAY)),
    QUARTER(DATE_ADD('2023-01-01', INTERVAL n DAY)),
    MONTH(DATE_ADD('2023-01-01', INTERVAL n DAY)),
    MONTHNAME(DATE_ADD('2023-01-01', INTERVAL n DAY)),
    WEEK(DATE_ADD('2023-01-01', INTERVAL n DAY), 0),
    DAY(DATE_ADD('2023-01-01', INTERVAL n DAY)),
    DAYNAME(DATE_ADD('2023-01-01', INTERVAL n DAY)),
    CASE 
        WHEN DAYOFWEEK(DATE_ADD('2023-01-01', INTERVAL n DAY)) IN (1, 7) THEN TRUE 
        ELSE FALSE 
    END AS is_weekend
FROM (
  SELECT a.N + b.N * 10 + c.N * 100 AS n
  FROM 
    (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
    (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
     UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b,
    (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3) c
) AS numbers
WHERE DATE_ADD('2023-01-01', INTERVAL n DAY) <= '2023-12-31';

-- ========================
-- FACT TABLE
-- ========================

-- Create fact_sales: stores transactional measures with FKs to dimension tables
CREATE TABLE fact_sales (
    sales_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_id VARCHAR(50) UNIQUE,           -- Degenerate dimension
    date_id DATE,                         -- FK to dim_date
    product_id INT,                       -- FK to dim_product
    payment_method_id INT,                -- FK to dim_payment_method
    location_id INT,                      -- FK to dim_location
    quantity INT,                         -- Measure
    total_spent DECIMAL(10,2),           -- Measure

    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (payment_method_id) REFERENCES dim_payment_method(payment_method_id),
    FOREIGN KEY (location_id) REFERENCES dim_location(location_id)
);

-- integrity check: confirm dim tables populated
SELECT COUNT(*) AS product_count FROM dim_product;
SELECT COUNT(*) AS payment_method_count FROM dim_payment_method;
SELECT COUNT(*) AS location_count FROM dim_location;
SELECT COUNT(*) AS date_count FROM dim_date;

-- Preview join results before inserting into fact table (highly professional step)
SELECT 
    c.transaction_id,
    c.transaction_date,
    d.date_id,
    p.product_id,
    pm.payment_method_id,
    l.location_id
FROM cafe_sales_cleaned c
LEFT JOIN dim_product p 
    ON CASE 
        WHEN c.item IS NULL THEN CONCAT('N/A - ', c.price_per_unit)
        ELSE c.item
    END = p.product_name
LEFT JOIN dim_payment_method pm 
    ON COALESCE(c.payment_method, 'N/A') = pm.payment_method_name
LEFT JOIN dim_location l 
    ON COALESCE(c.location, 'N/A') = l.location_type
LEFT JOIN dim_date d 
    ON c.transaction_date = d.date_id
LIMIT 10;

-- Insert final cleaned, joined data into fact_sales
INSERT INTO fact_sales (
    transaction_id,
    date_id,
    product_id,
    payment_method_id,
    location_id,
    quantity,
    total_spent
)
SELECT 
    c.transaction_id,
    c.transaction_date,
    p.product_id,
    pm.payment_method_id,
    l.location_id,
    c.quantity,
    c.total_spent
FROM cafe_sales_cleaned c
LEFT JOIN dim_product p 
    ON CASE 
        WHEN c.item IS NULL THEN CONCAT('N/A - ', c.price_per_unit)
        ELSE c.item
    END = p.product_name
LEFT JOIN dim_payment_method pm 
    ON COALESCE(c.payment_method, 'N/A') = pm.payment_method_name
LEFT JOIN dim_location l 
    ON COALESCE(c.location, 'N/A') = l.location_type
LEFT JOIN dim_date d 
    ON c.transaction_date = d.date_id;

-- ========================
-- POST-LOAD INTEGRITY CHECKS
-- ========================

-- Ensure all foreign keys matched correctly
SELECT COUNT(*) AS unmatched_products FROM fact_sales WHERE product_id IS NULL;
SELECT COUNT(*) AS unmatched_dates FROM fact_sales WHERE date_id IS NULL; -- Orginal Source have 410 records NULL
SELECT COUNT(*) AS unmatched_payment_methods FROM fact_sales WHERE payment_method_id IS NULL;
SELECT COUNT(*) AS unmatched_locations FROM fact_sales WHERE location_id IS NULL;

-- ========================
-- Indexing common filters and slicers
-- ========================
CREATE INDEX idx_fact_date ON fact_sales(date_id);
CREATE INDEX idx_fact_product ON fact_sales(product_id);
CREATE INDEX idx_fact_payment_method ON fact_sales(payment_method_id);
SHOW INDEXES FROM fact_sales;
