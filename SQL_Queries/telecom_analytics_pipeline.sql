-- =================================================================================
-- PROJECT 1: CROSS-FUNCTIONAL TELECOM OPERATIONAL FALLOUT & CHURN ANALYTICS ENGINE
-- AUTHOR: SHILPI
-- TARGET DATABASE: ORACLE SQL / MYSQL
-- =================================================================================

-- STEP 1: CREATE CRITICAL SUBSCRIBER OPERATIONS CORE AGGREGATION
-- This query acts as the semantic backbone, calculating cross-functional metrics
-- across Billing Pipeline Fallout, Technical Tickets, and Network Consumption.

SELECT 
    sub.subscriber_id,
    sub.device_type,
    sub.plan_type,
    sub.contract_months,
    bill.payment_status,
    bill.year_month,
    
    -- 1. Financial Revenue Metric
    SUM(bill.total_billed_usd) AS total_revenue_usd,
    AVG(bill.days_to_payment) AS avg_days_to_payment,
    
    -- 2. Technical Support Ticket Escalation Counts
    COUNT(CASE WHEN tkt.escalated = 1 THEN tkt.ticket_id END) AS escalated_ticket_count,
    
    -- 3. Network Utilization Data
    AVG(net.data_used_gb) AS avg_monthly_data_gb,
    
    -- 4. Customer Retention Context
    churn.churn_reason,
    AVG(churn.churn_probability_score) AS customer_churn_risk

FROM Dim_Subscriber sub

-- Bringing in transactional ledger billing streams
INNER JOIN Fact_Billing_Ledger bill 
    ON sub.subscriber_id = bill.subscriber_id

-- Left joining operational tickets to prevent excluding healthy accounts
LEFT JOIN Fact_Operations_Tickets tkt 
    ON sub.subscriber_id = tkt.subscriber_id

-- Left joining monthly network records to trace usage elasticity 
LEFT JOIN Fact_Network_Usage net 
    ON sub.subscriber_id = net.subscriber_id

-- Connecting churn analysis parameters to evaluate long-term business threat
LEFT JOIN Dim_Churn_Analysis churn 
    ON sub.subscriber_id = churn.subscriber_id

GROUP BY 
    sub.subscriber_id,
    sub.device_type,
    sub.plan_type,
    sub.contract_months,
    bill.payment_status,
    bill.year_month,
    churn.churn_reason;


-- =================================================================================
-- STEP 2: DRILL-DOWN OPTIMIZATION FOR THE DETAILED LEDGER
-- This query provides the fast-performing index view used for the bottom detailed sheet.
-- =================================================================================

SELECT 
    bill.subscriber_id,
    bill.payment_status,
    bill.total_billed_usd,
    bill.days_to_payment,
    churn.churn_reason
FROM Fact_Billing_Ledger bill
LEFT JOIN Dim_Churn_Analysis churn 
    ON bill.subscriber_id = churn.subscriber_id
WHERE bill.payment_status IN ('Failed', 'Unpaid')
ORDER BY bill.total_billed_usd DESC;
