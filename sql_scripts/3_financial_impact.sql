-- ==============================================================================
-- ANALYSIS 2: PRODUCTION DOWNTIME COST & RISK CATEGORIZATION
-- ==============================================================================
-- This advanced query calculates the direct financial loss caused by supplier 
-- delays. It joins procurement data with factory production logs and dynamically 
-- categorizes vendors into risk tiers to drive procurement decisions.

WITH DowntimeCalculation AS (
    -- Step 1: Calculate total downtime hours and cost per delayed purchase order
    SELECT 
        pl.po_id,
        SUM(pl.downtime_hours) AS total_downtime_hours,
        SUM(pl.downtime_hours * pl.hourly_cost_eur) AS total_downtime_cost
    FROM production_logs pl
    GROUP BY pl.po_id
),
SupplierImpact AS (
    -- Step 2: Aggregate financial impact at the supplier level
    SELECT 
        s.company_name,
        s.part_category,
        COUNT(po.po_id) AS total_orders,
        SUM(CASE WHEN po.actual_delivery > po.expected_delivery THEN 1 ELSE 0 END) AS delayed_orders,
        -- Using LEFT JOIN and COALESCE to ensure perfect suppliers show 0 cost instead of NULL
        COALESCE(SUM(dc.total_downtime_hours), 0) AS total_hours_lost,
        COALESCE(SUM(dc.total_downtime_cost), 0) AS total_financial_loss_eur
    FROM suppliers s
    JOIN purchase_orders po ON s.supplier_id = po.supplier_id
    LEFT JOIN DowntimeCalculation dc ON po.po_id = dc.po_id
    GROUP BY 
        s.company_name, 
        s.part_category
)
-- Step 3: Final Output with Dynamic Risk Categorization
SELECT 
    company_name,
    part_category,
    total_orders,
    delayed_orders,
    total_hours_lost,
    total_financial_loss_eur,
    -- Dynamic Risk Labeling based on financial damage
    CASE 
        WHEN total_financial_loss_eur >= 50000 THEN 'Critical Risk - Immediate Action'
        WHEN total_financial_loss_eur >= 10000 THEN 'High Risk - Needs Review'
        WHEN total_financial_loss_eur > 0 THEN 'Medium Risk - Monitor closely'
        ELSE 'Low Risk - Reliable Supplier'
    END AS risk_category
FROM SupplierImpact
ORDER BY total_financial_loss_eur DESC;
