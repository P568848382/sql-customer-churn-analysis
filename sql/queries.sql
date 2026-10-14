-- The 6+1 Core Business Queries +1(bonus) for Telco Churn Analysis
-- ============================================================
-- Query 1: Overall Churn Rate
-- Business Question: What percentage of customers have churned?
-- ============================================================
select
    COUNT(*) as total_customers,
    count(case when churn='Yes' then 1 end)as total_churned,
    count(case WHEN churn='No' then 1 end) as total_retained,
    round(
        count(case when churn='Yes' then 1 end)*100.0/count(*),2
    )as churn_rate_pct,
     round(
        count(case when churn='No' then 1 end)*100.0/count(*),2
    )as retention_rate_pct
from telco_churn;

    -- ============================================================
    -- Query 2: Churn Rate by Contract Type
    -- Business Question: Which contract type loses the most customers?
    -- Why it matters: Telecom companies push annual/biennial contracts
    -- specifically to reduce churn — this query validates that strategy.
    -- ============================================================
    select
        contract,
        COUNT(*) as total_customers,
        count(case when churn='Yes' then 1 end)as total_churned,
        count(case WHEN churn='No' then 1 end) as total_retained,
        round(
            count(case when churn='Yes' then 1 end)*100.0/count(*),2
        )as churn_rate_pct,
        round(
            count(case when churn='No' then 1 end)*100.0/count(*),2
        )as retention_rate_pct,
        round(
            avg(monthly_charges)::NUMERIC,2
        )as avg_monthly_charges,
        round(
            avg(tenure)::NUMERIC,2
        )as avg_tenure_months
    from telco_churn
    group by contract
    ORDER BY churn_rate_pct desc;

-- ============================================================
-- Query 3: Churn by Internet Service Type + Security Add-on
-- Business Question: Do customers with security add-ons churn less?
-- ============================================================
select * from telco_churn;
select
    internet_service,
    online_security,
    COUNT(*) as total_customers,
    count(case when churn='Yes' then 1 end)as total_churned,
    round(
        count(case when churn='Yes' then 1 end)*100.0/count(*),2
    )as churn_rate_pct,
    round(
        avg(monthly_charges)::NUMERIC,2
    )as avg_monthly_charges
from telco_churn
group by internet_service, online_security
order by internet_service,churn_rate_pct desc;

-- ============================================================
-- Query 4: Cohort Analysis — Churn Rate by Tenure Bucket
-- Business Question: Are new customers more likely to churn?
-- This is classic cohort thinking — grouping customers by
-- how long they have been with the company.
-- ============================================================
with tenure_cohorts as(
    select
        customer_id,
        churn,
        monthly_charges,
        tenure,
        case 
            when tenure between 0 and 12  then '0-12 months'
            when tenure between 13 and 24  then '13-24 months'
            when tenure between 25 and 48  then '25-48 months'
            when tenure between 49 and 60  then '49-60 months'
            else '60+ months'
        end as tenure_group,
        case 
            when tenure between 0 and 12  then 1
            when tenure between 13 and 24  then 2
            when tenure between 25 and 48  then 3
            when tenure between 49 and 60  then 4
            else 5
        end as group_order
    from telco_churn
)
select
    tenure_group,
    COUNT(*) as total_customers,
    count(case when churn='Yes' then 1 end)as total_churned,
    round(
        count(case when churn='Yes' then 1 end)*100.0/count(*),2
    )as churn_rate_pct,
    round(
        avg(monthly_charges)::NUMERIC,2
    )as avg_monthly_charges
from tenure_cohorts
group by tenure_group, group_order
order by group_order;


-- ============================================================
-- Query 5: Monthly Charges — Churned vs Retained Customers
-- Business Question: Are churned customers paying more or less?
-- ============================================================
select
    churn,
    COUNT(*) as total_customers,
    round(avg(monthly_charges)::NUMERIC,2) as avg_monthly_charges,
    round(min(monthly_charges)::NUMERIC,2) as min_monthly_charges,
    round(max(monthly_charges)::NUMERIC,2) as max_monthly_charges,
    round(stddev(monthly_charges)::NUMERIC,2) as stddev_monthly_charges,
    round(percentile_cont(0.5) within group (order by monthly_charges)::NUMERIC,2) as median_monthly_charges,
    round(avg(tenure)::NUMERIC,2) as avg_tenure_months,
    round(avg(totalcharges_num)::NUMERIC,2) as avg_total_revenue_per_customer
from telco_churn
group by churn;


-- ============================================================
-- Query 6: Churn Risk Score — CASE WHEN Rule Engine
-- Business Question: Which active customers are at highest risk?
-- Logic: Score 0-100 based on known churn predictors.
-- This is the stretch goal — assign every retained customer a risk label.
-- ============================================================

WITH risk_scores AS (
    SELECT
        customer_id,
        gender,
        contract,
        internet_service,
        tenure,
        monthly_charges,
        churn,

        -- Each rule adds points based on known churn risk factors
        (
            -- Short tenure is highest risk signal
            CASE WHEN tenure <= 12                         THEN 35
                 WHEN tenure BETWEEN 13 AND 24             THEN 20
                 WHEN tenure BETWEEN 25 AND 48             THEN 10
                 ELSE 0
            END

            -- Month-to-month contract is very high risk
            + CASE WHEN contract = 'Month-to-month'        THEN 30
                   WHEN contract = 'One year'              THEN 10
                   ELSE 0
              END

            -- High monthly charges increase risk
            + CASE WHEN monthly_charges > 80               THEN 20
                   WHEN monthly_charges BETWEEN 60 AND 80  THEN 10
                   ELSE 0
              END

            -- Fiber optic customers churn more
            + CASE WHEN internet_service = 'Fiber optic'   THEN 10
                   ELSE 0
              END

            -- No tech support increases risk
            + CASE WHEN tech_support = 'No'
                    AND internet_service != 'No'            THEN 5
                   ELSE 0
              END
        )                                                   AS risk_score

    FROM telco_churn
    WHERE churn = 'No'   -- only score currently active customers
),
risk_labelled AS (
    SELECT
        *,
        CASE
            WHEN risk_score >= 70 THEN 'High Risk'
            WHEN risk_score >= 40 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS risk_label
    FROM risk_scores
)
SELECT
    risk_label,
    COUNT(*)                              AS customer_count,
    ROUND(AVG(monthly_charges)::numeric, 2)         AS avg_monthly_charge,
    ROUND(AVG(tenure)::numeric, 2)                 AS avg_tenure,
    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER(),
    2)                                    AS pct_of_active_customers
FROM risk_labelled
GROUP BY risk_label
ORDER BY
    CASE risk_label
        WHEN 'High Risk'   THEN 1
        WHEN 'Medium Risk' THEN 2
        ELSE 3
    END;


-- ============================================================
-- Query 7: Churn by Payment Method
-- Business Question: Does payment method affect churn?
-- ============================================================

SELECT
    payment_method,
    paperless_billing,
    COUNT(*)                                                      AS total_customers,
    COUNT(CASE WHEN churn = 'Yes' THEN 1 END)                     AS churned,
    ROUND(
        COUNT(CASE WHEN churn = 'Yes' THEN 1 END) * 100.0
        / COUNT(*),
    2)                                                            AS churn_rate_pct,
    ROUND(AVG(monthly_charges)::numeric, 2)                                 AS avg_monthly_charge
FROM telco_churn
GROUP BY payment_method, paperless_billing
ORDER BY churn_rate_pct DESC;
