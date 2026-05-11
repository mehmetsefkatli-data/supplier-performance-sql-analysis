-- ==============================================================================
-- DATABASE SETUP: SUPPLIERS, PURCHASE ORDERS, AND PRODUCTION LOGS
-- ==============================================================================

-- STEP 1: Clean up existing tables (Order is important due to foreign keys!)
DROP TABLE IF EXISTS production_logs;
DROP TABLE IF EXISTS purchase_orders;
DROP TABLE IF EXISTS suppliers;


-- STEP 2: Create tables from scratch

-- 2.1. Suppliers Table
CREATE TABLE suppliers (
    supplier_id SERIAL PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    country VARCHAR(50),
    part_category VARCHAR(50) -- Electronics, Mechanics, Plastics etc.
);

-- 2.2. Purchase Orders Table
CREATE TABLE purchase_orders (
    po_id SERIAL PRIMARY KEY,
    supplier_id INT REFERENCES suppliers(supplier_id),
    order_date DATE,
    expected_delivery DATE,
    actual_delivery DATE,
    ordered_qty INT,
    received_qty INT,
    unit_price_eur DECIMAL(10,2)
);

-- 2.3. Production Logs Table (For Downtime Analysis)
CREATE TABLE production_logs (
    log_id SERIAL PRIMARY KEY,
    po_id INT REFERENCES purchase_orders(po_id),
    incident_date DATE,
    downtime_hours DECIMAL(5,2),
    hourly_cost_eur DECIMAL(10,2), 
    cause_description VARCHAR(255)
);


-- STEP 3: Insert Sample Data

-- 3.1. Supplier Data
INSERT INTO suppliers (company_name, country, part_category) VALUES 
('TechVantage GmbH', 'Germany', 'Electronics'),
('Global Steel Parts', 'Poland', 'Mechanics'),
('EuroPlast', 'Italy', 'Plastics');

-- 3.2. Order Data (Includes delayed and incomplete deliveries)
INSERT INTO purchase_orders (supplier_id, order_date, expected_delivery, actual_delivery, ordered_qty, received_qty, unit_price_eur) VALUES
(1, '2026-04-01', '2026-04-10', '2026-04-10', 500, 500, 45.50), -- On-time, in-full (OTIF)
(1, '2026-04-05', '2026-04-15', '2026-04-18', 300, 300, 45.50), -- Delayed (3 days)
(2, '2026-04-02', '2026-04-12', '2026-04-12', 1000, 950, 12.00), -- On-time, but incomplete quantity
(2, '2026-04-10', '2026-04-20', '2026-04-25', 1000, 1000, 12.00), -- Delayed (5 days)
(3, '2026-04-05', '2026-04-08', '2026-04-08', 2000, 2000, 2.50);  -- On-time, in-full (OTIF)

-- 3.3. Production Downtime Data (Linked to delayed orders)
INSERT INTO production_logs (po_id, incident_date, downtime_hours, hourly_cost_eur, cause_description) VALUES
(2, '2026-04-16', 4.5, 5000.00, 'Assembly line stopped due to missing electronic components'),
(4, '2026-04-21', 12.0, 3500.00, 'Machining process halted, waiting for steel parts'),
(4, '2026-04-22', 8.0, 3500.00, 'Machining process still halted, waiting for steel parts');
