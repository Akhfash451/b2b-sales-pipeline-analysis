-- ============================================================
-- B2B Sales Performance & Pipeline Analysis
-- SQL Business Analysis
-- ============================================================
--
-- Schema assumptions (produced by b2b_sales_analysis.ipynb, Parts 2-3):
--   sales_pipeline  -- one row per opportunity, includes the derived
--                       columns won_flag/lost_flag/open_flag,
--                       sales_cycle_days, engage_quarter, close_quarter,
--                       pipeline_status (see notebook Part 2)
--   accounts        -- one row per customer account (sector typo corrected)
--   products        -- one row per product (name typo corrected)
--   sales_teams     -- one row per sales agent -> manager -> region
--
-- KPI conventions used throughout (must match notebook Part 4):
--   win_rate_pct  = Won / (Won + Lost)      -- Open opportunities excluded
--   won_revenue   = SUM(close_value) WHERE deal_stage = 'Won'
-- ============================================================


-- ============================================================
-- QUERY 01 — TOTAL OPPORTUNITIES
-- Business Question:
-- How many sales opportunities are in the CRM?
-- ============================================================

SELECT
    COUNT(*) AS total_opportunities
FROM sales_pipeline;


-- ============================================================
-- QUERY 02 — DEAL STAGE DISTRIBUTION
-- Business Question:
-- How are opportunities distributed across deal stages?
-- ============================================================

SELECT
    deal_stage,
    COUNT(*) AS opportunities
FROM sales_pipeline
GROUP BY deal_stage
ORDER BY opportunities DESC;


-- ============================================================
-- QUERY 03 — WON REVENUE
-- Business Question:
-- How much realized revenue has been generated from
-- Won opportunities?
-- ============================================================

SELECT
    SUM(close_value) AS won_revenue
FROM sales_pipeline
WHERE deal_stage = 'Won';


-- ============================================================
-- QUERY 04 — CLOSED WIN RATE
-- Business Question:
-- What percentage of closed opportunities were Won?
-- ============================================================

SELECT
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN deal_stage = 'Won' THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN deal_stage IN ('Won', 'Lost') THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS closed_win_rate_pct
FROM sales_pipeline;


-- ============================================================
-- QUERY 05 — PRODUCT PERFORMANCE
-- Business Question:
-- Which products generate the most opportunities,
-- wins, and realized revenue?
-- ============================================================

SELECT
    product,

    COUNT(*) AS opportunities,

    SUM(
        CASE
            WHEN deal_stage = 'Won' THEN 1
            ELSE 0
        END
    ) AS won_opportunities,

    SUM(
        CASE
            WHEN deal_stage = 'Lost' THEN 1
            ELSE 0
        END
    ) AS lost_opportunities,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN deal_stage = 'Won' THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN deal_stage IN ('Won', 'Lost') THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS win_rate_pct,

    SUM(
        CASE
            WHEN deal_stage = 'Won'
            THEN close_value
            ELSE 0
        END
    ) AS won_revenue

FROM sales_pipeline

GROUP BY product

ORDER BY won_revenue DESC;


-- ============================================================
-- QUERY 06 — SALES AGENT PERFORMANCE
-- Business Question:
-- Which sales agents generate the most won revenue?
-- ============================================================

SELECT
    sales_agent,

    COUNT(*) AS opportunities,

    SUM(
        CASE
            WHEN deal_stage = 'Won' THEN 1
            ELSE 0
        END
    ) AS won_opportunities,

    SUM(
        CASE
            WHEN deal_stage = 'Lost' THEN 1
            ELSE 0
        END
    ) AS lost_opportunities,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN deal_stage = 'Won' THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN deal_stage IN ('Won', 'Lost') THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS win_rate_pct,

    SUM(
        CASE
            WHEN deal_stage = 'Won'
            THEN close_value
            ELSE 0
        END
    ) AS won_revenue

FROM sales_pipeline

GROUP BY sales_agent

ORDER BY won_revenue DESC;


-- ============================================================
-- QUERY 07 — REGIONAL PERFORMANCE
-- Business Question:
-- Which regional office generates the most revenue
-- and has the strongest conversion?
-- ============================================================

SELECT
    st.regional_office,

    COUNT(*) AS opportunities,

    SUM(
        CASE
            WHEN sp.deal_stage = 'Won' THEN 1
            ELSE 0
        END
    ) AS won_opportunities,

    SUM(
        CASE
            WHEN sp.deal_stage = 'Lost' THEN 1
            ELSE 0
        END
    ) AS lost_opportunities,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN sp.deal_stage = 'Won' THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN sp.deal_stage IN ('Won', 'Lost')
                    THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS win_rate_pct,

    SUM(
        CASE
            WHEN sp.deal_stage = 'Won'
            THEN sp.close_value
            ELSE 0
        END
    ) AS won_revenue

FROM sales_pipeline AS sp

LEFT JOIN sales_teams AS st
    ON sp.sales_agent = st.sales_agent

GROUP BY st.regional_office

ORDER BY won_revenue DESC;


-- ============================================================
-- QUERY 08 — SECTOR PERFORMANCE
-- Business Question:
-- Which customer sectors generate the most won revenue?
-- ============================================================

SELECT
    a.sector,

    COUNT(*) AS opportunities,

    SUM(
        CASE
            WHEN sp.deal_stage = 'Won' THEN 1
            ELSE 0
        END
    ) AS won_opportunities,

    SUM(
        CASE
            WHEN sp.deal_stage = 'Lost' THEN 1
            ELSE 0
        END
    ) AS lost_opportunities,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN sp.deal_stage = 'Won' THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN sp.deal_stage IN ('Won', 'Lost')
                    THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS win_rate_pct,

    SUM(
        CASE
            WHEN sp.deal_stage = 'Won'
            THEN sp.close_value
            ELSE 0
        END
    ) AS won_revenue

FROM sales_pipeline AS sp

LEFT JOIN accounts AS a
    ON sp.account = a.account

WHERE sp.account IS NOT NULL

GROUP BY a.sector

ORDER BY won_revenue DESC;


-- ============================================================
-- QUERY 09 — QUARTERLY PERFORMANCE
-- Business Question:
-- How did closed sales performance vary by quarter?
--
-- Note: uses the close_quarter column produced during cleaning
-- (notebook Part 2) rather than re-deriving it from close_date,
-- so the quarter label is guaranteed to match the notebook and
-- dashboard exactly. Reminder: Q1 close figures reflect a partial
-- quarter, since pipeline engagement only begins in Oct 2016
-- (see notebook Part 1 / Part 8 limitations).
-- ============================================================

SELECT
    close_quarter,

    SUM(
        CASE
            WHEN deal_stage = 'Won' THEN 1
            ELSE 0
        END
    ) AS won_opportunities,

    SUM(
        CASE
            WHEN deal_stage = 'Lost' THEN 1
            ELSE 0
        END
    ) AS lost_opportunities,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN deal_stage = 'Won' THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN deal_stage IN ('Won', 'Lost')
                    THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS win_rate_pct

FROM sales_pipeline

WHERE deal_stage IN ('Won', 'Lost')
  AND close_date IS NOT NULL

GROUP BY close_quarter

ORDER BY close_quarter;


-- ============================================================
-- QUERY 10 — SALES-CYCLE ANALYSIS
-- Business Question:
-- How does sales-cycle length relate to win rate?
--
-- Note: uses the sales_cycle_days column produced during cleaning
-- (notebook Part 2, engage_date to close_date) rather than
-- re-deriving it with julianday(), for the same reason as Query 09.
-- ============================================================

SELECT

    CASE
        WHEN sales_cycle_days <= 14
            THEN '1-14 days'

        WHEN sales_cycle_days <= 30
            THEN '15-30 days'

        WHEN sales_cycle_days <= 60
            THEN '31-60 days'

        WHEN sales_cycle_days <= 90
            THEN '61-90 days'

        ELSE '91+ days'
    END AS sales_cycle_group,

    COUNT(*) AS opportunities,

    SUM(
        CASE
            WHEN deal_stage = 'Won' THEN 1
            ELSE 0
        END
    ) AS won_opportunities,

    SUM(
        CASE
            WHEN deal_stage = 'Lost' THEN 1
            ELSE 0
        END
    ) AS lost_opportunities,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN deal_stage = 'Won' THEN 1
                ELSE 0
            END
        )
        / COUNT(*),
        2
    ) AS win_rate_pct

FROM sales_pipeline

WHERE deal_stage IN ('Won', 'Lost')

GROUP BY sales_cycle_group

ORDER BY
    CASE sales_cycle_group
        WHEN '1-14 days' THEN 1
        WHEN '15-30 days' THEN 2
        WHEN '31-60 days' THEN 3
        WHEN '61-90 days' THEN 4
        WHEN '91+ days' THEN 5
    END;


-- ============================================================
-- QUERY 11 — TOP CUSTOMER ACCOUNTS
-- Business Question:
-- Which customer accounts generate the most won revenue?
-- ============================================================

SELECT
    a.account,
    a.sector,
    a.office_location,

    COUNT(sp.opportunity_id) AS opportunities,

    SUM(
        CASE
            WHEN sp.deal_stage = 'Won'
            THEN 1
            ELSE 0
        END
    ) AS won_opportunities,

    SUM(
        CASE
            WHEN sp.deal_stage = 'Won'
            THEN sp.close_value
            ELSE 0
        END
    ) AS won_revenue

FROM sales_pipeline AS sp

LEFT JOIN accounts AS a
    ON sp.account = a.account

WHERE sp.account IS NOT NULL

GROUP BY
    a.account,
    a.sector,
    a.office_location

ORDER BY won_revenue DESC

LIMIT 10;
