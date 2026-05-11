-- ==============================================================================
-- ANALYSIS 1: SUPPLIER OTIF (ON-TIME IN-FULL) PERFORMANCE & RANKING
-- ==============================================================================
-- This query evaluates supplier reliability by calculating the percentage of 
-- orders delivered exactly on time and in the correct quantities. It uses Window 
-- Functions to rank suppliers based on their performance.

WITH OrderMetrics AS (
    -- Step 1: Flagging each order for On-Time and In-Full criteria
    SELECT 
        po.po_id,
        po.supplier_id,
        s.company_name,
        -- Calculating delay duration in days
        EXTRACT(DAY FROM (po.actual_delivery::timestamp - po.expected_delivery::timestamp)) AS delay_days,
        -- On-Time Check
        CASE WHEN po.actual_delivery <= po.expected_delivery THEN 1 ELSE 0 END AS is_on_time,
        -- In-Full Check
        CASE WHEN po.received_qty >= po.ordered_qty THEN 1 ELSE 0 END AS is_in_full
    FROM purchase_orders po
    JOIN suppliers s ON po.supplier_id = s.supplier_id
),
SupplierPerformance AS (
    -- Step 2: Grouping by supplier to calculate overall OTIF rates
    SELECT 
        company_name,
        COUNT(po_id) AS total_orders,
        -- Calculating % OTIF
        ROUND((SUM(CASE WHEN is_on_time = 1 AND is_in_full = 1 THEN 1 ELSE 0 END)::numeric / COUNT(po_id)) * 100, 2) AS otif_percentage,
        -- Average delay duration for delayed orders
        AVG(CASE WHEN delay_days > 0 THEN delay_days ELSE NULL END) AS avg_delay_days
    FROM OrderMetrics
    GROUP BY company_name
)
-- Step 3: Final Output with Ranking (Window Function)
SELECT 
    company_name,
    total_orders,
    otif_percentage,
    COALESCE(ROUND(avg_delay_days, 1), 0) AS avg_delay_days,
    -- Ranking from best to worst
    RANK() OVER(ORDER BY otif_percentage DESC) AS performance_rank
FROM SupplierPerformance
ORDER BY performance_rank;
