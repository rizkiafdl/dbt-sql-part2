# Part 2 — Product Analysis: Answers

## Q1. Which product / product category is the biggest contributor to company revenue?

### Answer

**LOAN is the biggest contributor to revenue: 66.1 % of total balance (Rp 1,582.5 Bn).** Within LOAN, three products lead: **TERM LOAN** (Rp 318.1 Bn), **DEMAND LOAN** (Rp 290.4 Bn) and **PIF-FLOATING** (Rp 212.2 Bn).

### Assumption: balance as the revenue measure

The data has no revenue column. A bank earns revenue as a margin on the balances it manages: interest on loans, a spread on deposits, and fees on investment products. So:

> **Revenue = balance × margin.**

The margin per product is not in the data. I assume **an equal margin for every product**. Under this assumption, revenue is proportional to balance, and the product with the largest balance is the largest revenue contributor.

The measure is **total balance** = the sum of `porto.amount` over all products. It is not AUM: AUM counts only the money customers place with the bank (deposits and investments) and excludes loans.

**Why the conclusion is robust:** LOAN is more than 2× larger than FUNDING. In real banking, loans usually earn the highest margin per rupiah. So the equal-margin assumption, if anything, understates LOAN's lead. The answer holds under realistic margins too.

**Holders** = customers who hold the product with a balance above 0. Zero-balance accounts are open but unused. Q2 uses the same rule.

### Total balance by category

| Rank | Category | Holders | Total balance (Rp Bn) | Share |
|---|---|---|---|---|
| 1 | **LOAN** | 83 | **1,582.5** | **66.1 %** |
| 2 | FUNDING | 84 | 730.7 | 30.5 % |
| 3 | ORI | 46 | 49.8 | 2.1 % |
| 4 | BANCA | 54 | 25.4 | 1.1 % |
| 5 | REKSA | 54 | 5.8 | 0.2 % |

<!-- chart: q1_balance_by_category -->

> dbt model: [fct_revenue_by_category.sql](ocbc_dbt/models/mart/fct_revenue_by_category.sql)

### Products within LOAN (top 5)

| Rank | Product | Holders | Total balance (Rp Bn) | Share of LOAN |
|---|---|---|---|---|
| 1 | TERM LOAN | 5 | 318.1 | 20.1 % |
| 2 | DEMAND LOAN | 3 | 290.4 | 18.4 % |
| 3 | PIF-FLOATING | 3 | 212.2 | 13.4 % |
| 4 | KRK EMB | 26 | 125.5 | 7.9 % |
| 5 | KPR_KENDALI | 60 | 102.8 | 6.5 % |

The top 3 loan products have only 3–5 holders each. So the product ranking inside LOAN can change if one large customer repays. The category answer (LOAN) does not depend on one customer.

> dbt model: [fct_revenue_by_product.sql](ocbc_dbt/models/mart/fct_revenue_by_product.sql)

### Edge case: MULTI CURRENCY

Across all products, the single largest balance is **MULTI CURRENCY** (FUNDING, Rp 535.8 Bn, 22.4 % of total balance, 37 holders). It is a deposit product. The bank pays interest on deposits, and its revenue from them is the spread between the loan rate and the deposit rate. The data does not show that spread. So I report MULTI CURRENCY as the **largest balance**, but not as the proven largest revenue contributor.

### Why the transaction table is not used

`transaction` has no product column: `transaction_method` is a channel (BRANCH, ATM, MOBILE BANKING …). The rows that look like revenue are very small: fees (`BIAYA`) Rp 6.5 jt and penalties (`DENDA`) Rp 0.7 jt, against Rp 2,394 Bn of balance. So they cannot rank products.

### Limitations and next step

- **Equal margin is a simplification.** Margins differ by product. With margin data (net interest margin per loan product, deposit spread, fee rates for BANCA / REKSA / ORI), I would multiply each balance by its margin to get revenue directly.
- **Snapshot.** `porto` is a single snapshot of balances, not revenue over a period.
- **Data quality.** 1 porto row has no product name (LOAN, Rp 18.7 jt, shown as `(UNKNOWN)`). 5 rows have no amount and count as 0. Neither changes the result.

---

## Q2. Which product / product category is usually used by customers with high income?

### Answer

The question has two readings, and the data gives a different answer to each:

- **Most used:** high-income customers mostly use **LOAN and FUNDING** (83 % each). But other customers use them just as much (83–84 %). These are core products of every customer, not high-income products.
- **Most characteristic:** **BANCA (bancassurance)** is the category that high-income customers use clearly more than others: **67 % vs 51 % (lift 1.3)**. At product level, BANCA, TANDA360 and PERSONAL LOAN tie at 67 %; BANCA has the highest lift.

**So: BANCA is the product typical of high-income customers.** This is a directional signal from a small group (see Limitations).

### Definition of high income

High income = stated income band **`>10 Juta` per month** or more (`income_rank >= 5`): **18 of 100 customers**, about the top 20 %. The median customer is in `>3 Juta - 5 Juta`, so this is more than 2× the median.

> dbt model: [dim_customer.sql](ocbc_dbt/models/mart/dim_customer.sql) (`is_high_income`)

### Method

- **Penetration** = % of the segment's customers who hold the product with a balance above 0. "Usually used" means *how many* customers use it, not how much money is in it. Zero-balance accounts are open but unused, so they do not count.
- **Lift** = high-income penetration ÷ other customers' penetration. Lift above 1 means high-income customers use it more than others.
- The denominator is all 100 customers (18 high-income, 82 other). A customer with no product counts as "does not use it".

**Example (BANCA):**

| Step | Calculation | Result |
|---|---|---|
| High income | 12 holders ÷ 18 customers | 66.7 % |
| Other customers | 42 holders ÷ 82 customers | 51.2 % |
| Lift | 66.7 % ÷ 51.2 % | **1.30** |

High-income customers use BANCA 1.3× as often as other customers. Lift is computed from unrounded fractions.

### Penetration by category

| Category | High-income holders | High income | Other customers | Lift |
|---|---|---|---|---|
| LOAN | 15 | 83.3 % | 82.9 % | 1.00 |
| FUNDING | 15 | 83.3 % | 84.1 % | 0.99 |
| **BANCA** | **12** | **66.7 %** | **51.2 %** | **1.30** |
| REKSA | 9 | 50.0 % | 54.9 % | 0.91 |
| ORI | 8 | 44.4 % | 46.3 % | 0.96 |

<!-- chart: q2_lift_by_category -->

> dbt model: [fct_high_income_usage_by_category.sql](ocbc_dbt/models/mart/fct_high_income_usage_by_category.sql)

### Top products by high-income penetration

| Category | Product | High-income holders | High income | Other customers | Lift |
|---|---|---|---|---|---|
| BANCA | BANCA | 12 | 66.7 % | 51.2 % | **1.30** |
| FUNDING | TANDA360 | 12 | 66.7 % | 58.5 % | 1.14 |
| LOAN | PERSONAL LOAN | 12 | 66.7 % | 59.8 % | 1.12 |
| LOAN | KPR_KENDALI | 11 | 61.1 % | 59.8 % | 1.02 |
| FUNDING | TABSYA | 10 | 55.6 % | 53.7 % | 1.04 |
| FUNDING | DEPOSITO03 | 10 | 55.6 % | 61.0 % | 0.91 |
| FUNDING | DEPOSITO01 | 10 | 55.6 % | 62.2 % | 0.89 |

> dbt model: [fct_high_income_usage_by_product.sql](ocbc_dbt/models/mart/fct_high_income_usage_by_product.sql)

### Limitations

- **Small group.** 18 high-income customers: one customer moves the percentage by 5.6 points. The BANCA gap is about 3 customers, so I treat it as a directional signal, not a proven fact.
- **Product use barely differs by income** in this sample. Apart from BANCA, all lifts are between 0.9 and 1.1.
- **Snapshot.** The portfolio is a single snapshot.

**Business angle:** bancassurance is a natural entry point for wealth offers to high-income customers. Re-test on the full customer base before targeting campaigns on it.

---

## How to run

From `solution/part_2/`:

| Command | What it does |
|---|---|
| `make install` | Create `.venv` with DuckDB and dbt. |
| `make data` | Split the workbook `dataset/raw/AE Test_1126.xlsx` into `dataset/transaction.csv`, `profile.csv`, `porto.csv`. Optional: the CSV files are already there. |
| `make dbt` | Build the dbt models and run all tests into `dbt.duckdb`. |
| `make answers` | Run `make dbt`, then print the 4 fact tables (the answers). |
| `make ui` | Open the DuckDB UI with `dbt.duckdb` attached as `dbt`. Stop it before `make dbt` (DuckDB allows one writer). |

Model lineage (`raw → staging → mart`):

```
raw.profile ─► stg_profile ─► dim_customer ─┐
                                            ├─► fct_high_income_usage_by_category
raw.porto   ─► stg_porto ──┬────────────────┘   fct_high_income_usage_by_product
                           ├─► fct_revenue_by_category
                           └─► fct_revenue_by_product
```

- **Staging** cleans the data: renames `customerid` to `customer_id`, trims text, maps the income band to `income_rank` (1–8), sets a missing product to `(UNKNOWN)` and a missing amount to 0.
- **Mart** holds `dim_customer` (one row per customer, with `is_high_income`) and the 4 fact tables, one per answer table.
- `raw.transaction` is declared as a source but not used (see Q1).
