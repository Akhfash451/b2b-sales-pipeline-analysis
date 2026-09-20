# B2B Sales Performance & Pipeline Analysis

A CRM opportunity-level analysis of pipeline health, conversion, product performance, and sales-team effectiveness for a B2B sales organization — built end-to-end in Python and SQL, with an interactive dashboard for ongoing exploration.

**[View the Interactive Data Studio Dashboard](https://datastudio.google.com/reporting/435ae8a1-4d90-4e4c-b870-f5b9d04d6987)** *(Data Studio — formerly branded Looker Studio; Google renamed it back to Data Studio in April 2026)*

📓 **[View the notebook on nbviewer](https://nbviewer.org/github/Akhfash451/b2b-sales-pipeline-analysis/blob/main/b2b_sales_analysis.ipynb)** — use this if GitHub's inline preview fails to render the `.ipynb` file (a known, intermittent GitHub limitation on notebooks with many embedded charts, unrelated to the file itself)

---

## Business Objective

A sales organization needs a clear, evidence-based answer to: how much revenue is being generated, how efficiently is the pipeline converting, and where are the clearest opportunities to improve performance? This project answers that using 8,800 CRM opportunities spanning October 2016–December 2017, across four source tables (pipeline, accounts, products, sales teams).

## Key Business Questions

1. How much revenue is being generated, and how efficiently does the pipeline convert?
2. Which products perform best — and by what measure (volume, conversion, or deal value)?
3. Which sales agents, managers, and regions perform best, and through what mechanism?
4. How do customer account size and sector relate to revenue outcomes?
5. How does performance change over time, and how does sales-cycle length relate to win rate?
6. Where are the clearest, evidence-backed opportunities to improve revenue?

## Headline Results

| Metric | Value |
|---|---|
| Total Opportunities | 8,800 |
| Won / Lost / Open | 4,238 / 2,473 / 2,089 |
| Closed Win Rate | 63.15% |
| Won Revenue | $10.01M |
| Average / Median Won Deal | $2,360.91 / $1,117 |
| Average / Median Sales Cycle (closed) | 47.99 / 45 days |

**A few of the findings behind those numbers** (full detail, evidence, and interpretation are in the notebook, Parts 5 and 8):

- Product performance is multi-dimensional: the highest-volume product (GTX Basic), the highest-win-rate product (MG Special), and the highest-revenue product (GTX Pro) are three different products.
- **West** leads the three regions in Won Revenue and Closed Win Rate; **Central** carries the largest opportunity volume but the lowest win rate, making its conversion pattern worth further investigation.
- Among accounts with linked account data, the top 10 account-level contributors represent 20.72% of account-attributed Won Revenue (top 5: 12.09%) — describing the observed revenue share of the largest contributors in this dataset, not a benchmarked concentration measure.
- Won revenue and customer size are positively correlated (Pearson r = 0.756, Spearman ρ = 0.723) — a moderately strong, robust association, not a causal claim.
- Short sales cycles (1–14 days) have the *lowest* win rate, while 15–30 day and 91+ day cycles show the highest observed win rates — a descriptive pattern, not evidence that a longer cycle causes a higher chance of winning.

## Repository Structure

This repository uses a flat structure — every file lives at the repository root, and the notebook and SQL file read/write relative paths with no subfolders required.

| File | Description |
|---|---|
| `b2b_sales_analysis.ipynb` | The full analysis: data quality audit → cleaning → modeling → KPI definitions → EDA → SQL validation → dashboard export → executive summary |
| `business_analysis_queries.sql` | 11 standalone SQL business-analysis queries, runnable against the cleaned tables (mirrored and executed inside the notebook, Part 6) |
| `accounts.csv`, `products.csv`, `sales_pipeline.csv`, `sales_teams.csv` | Raw CRM source extracts (input to the notebook) |
| `accounts_clean.csv`, `products_clean.csv`, `sales_pipeline_clean.csv`, `sales_teams_clean.csv` | Cleaned tables produced by the notebook (Part 2) |
| `sales_analysis_master.csv` | The single merged, analysis-ready table (Part 3) — one row per opportunity, 29 columns |
| `looker_dashboard_data.csv` | Flat extract that feeds the Data Studio dashboard (Part 7); filename kept as-is from the original source data extract |
| `dashboard.pdf` | Static snapshot of the interactive dashboard |

## Data Sources

**Source:** [CRM Sales Opportunities](https://mavenanalytics.io/data-playground/crm-sales-opportunities), Maven Analytics Data Playground. A public-domain, B2B sales pipeline dataset for a fictitious computer-hardware vendor ("MavenTech"), covering opportunities from October 2016 to December 2017. License: Public Domain.

Four CRM extracts, all joined on a common `opportunity_id` / `product` / `sales_agent` / `account` key structure:

| File | Grain | Rows | Key Fields |
|---|---|---|---|
| `sales_pipeline.csv` | 1 row per opportunity | 8,800 | `sales_agent`, `product`, `account`, `deal_stage`, `engage_date`, `close_date`, `close_value` |
| `accounts.csv` | 1 row per customer account | 85 | `sector`, `revenue`, `employees`, `office_location` |
| `products.csv` | 1 row per product | 7 | `series`, `sales_price` |
| `sales_teams.csv` | 1 row per sales agent | 35 | `manager`, `regional_office` |

## Methodology

The notebook follows **Business Question → Analysis → Result → Interpretation** in every major section:

1. **Data Overview & Quality Assessment** — inventory all four tables; identify two source-data typos (`"GTXPro"` → `"GTX Pro"`, `"technolgy"` → `"technology"`) and confirm missing values are structural (tied to `deal_stage`), not random.
2. **Data Cleaning & Preparation** — standardize fields, correct the typos found above, engineer `won_flag`/`lost_flag`/`open_flag`, `pipeline_status`, `sales_cycle_days`, and calendar dimensions. No rows are dropped or imputed.
3. **Data Modeling** — left-join pipeline → products → sales teams → accounts into a single master table, with row-count and key-uniqueness integrity tests at every join.
4. **KPI Definitions & Core Metrics** — every metric (win rate, won revenue, average/median deal size, sales cycle) is defined explicitly once and reused consistently in every later section, in both Python and SQL.
5. **Exploratory Data Analysis** — funnel health, product performance, sales-team/regional performance, account/sector analysis, time and sales-cycle trends, and cross-factor analysis (product×region, sector×product, cycle×product, account-size correlation).
6. **SQL Validation** — the same headline metrics, computed independently in SQLite from `business_analysis_queries.sql`, are cross-checked against the Python results and match exactly.
7. **Dashboard** — the Data Studio dashboard (linked above) is built from the same KPI definitions and validated against them.
8. **Executive Summary** — findings, interpretation, and recommendations are kept in clearly separated sections, alongside an explicit limitations discussion.

## Key Methodology Decisions

- **Win rate excludes Open opportunities.** Win rate = Won ÷ (Won + Lost). Open opportunities haven't yet had a chance to convert, so including them would understate performance.
- **Average/median deal size is calculated on Won opportunities only.** Lost opportunities record `close_value = 0` (a completed, unsuccessful sales process), not a missing value — including them in a deal-size average would silently understate it. This distinction is applied consistently across every agent, manager, regional, account, and sector breakdown.
- **Left joins preserve every opportunity.** 16.2% of opportunities have no linked account; they remain in every pipeline- and product-level KPI and are explicitly excluded (via `.notna()` filters) only from account- and sector-level breakdowns.
- **Correlation is reported alongside a rank-based robustness check.** The account-size/revenue relationship is reported as both Pearson and Spearman correlation, and is explicitly described as an association, not a causal claim.
- **Account value segmentation is based on Won Revenue, not customer size.** Accounts are split into quartiles by their own `won_revenue` (labeled `won_revenue_quartile`) — a deliberately distinct measure from `account_revenue` (the customer's own reported revenue), which is used separately in the Section 5.6 correlation check.

## Tools

- **Python** (pandas, numpy, matplotlib, seaborn) — cleaning, modeling, KPI calculation, exploratory analysis
- **SQL / SQLite** — independent validation layer
- **Data Studio** (formerly Looker Studio) — interactive dashboard

## Reproducing This Analysis

```bash
git clone https://github.com/Akhfash451/b2b-sales-pipeline-analysis.git
cd b2b-sales-pipeline-analysis
pip install pandas numpy matplotlib seaborn jupyter
jupyter notebook b2b_sales_analysis.ipynb
```

Run all cells top to bottom. The notebook reads all four raw CSVs from the repository root and writes the cleaned tables, the master table, and the dashboard extract back to the same folder — no path configuration is required.

## Limitations

- **Partial Q1 2017 window:** pipeline engagement begins in October 2016, so very few opportunities had time to close in Q1 2017. Q1 2017 figures are a ramp-up period, not a comparable quarter, and should not be read as a performance dip.
- **No stage-transition history:** only `engage_date` and `close_date` are recorded per opportunity — there is no timestamp for intermediate stage changes, so sales-cycle analysis measures total time-to-close, not time spent in any individual stage.
- **Account coverage:** 16.2% of opportunities have no linked account and are excluded from account- and sector-level breakdowns only.
- **`subsidiary_of` is unused** (85.3% missing — not meaningful at that level of missingness).
- **Correlation, not causation:** the account-size/revenue relationship and the cycle-length/win-rate pattern are associations, not established causal mechanisms.
- **Single ~14-month window:** findings describe October 2016–December 2017 and should not be assumed to generalize to other periods without re-validation.

Full detail, evidence, and business recommendations are in `b2b_sales_analysis.ipynb`, Part 8 (Executive Summary, Recommendations & Limitations).
