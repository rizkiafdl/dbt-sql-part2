# Part 2 — Product Analysis: Answers

## Q1. Which product / product category is the biggest contributor to company revenue?

### Answer

- **Category: LOAN**, with 66.1 % of the total balance (Rp 1,582.5 Bn).
- **Product: MULTI CURRENCY** (FUNDING), with 22.4 % of the total balance (Rp 535.8 Bn).

### How I measure revenue

The data has no revenue or margin column. A bank earns revenue as a margin on balances, so I assume **every product earns the same margin**. Then revenue follows the balance (the sum of `porto.amount`), and the biggest balance is the biggest contributor.

A holder is a customer with a balance above 0 in the product. Q2 uses the same rule.

The transaction table can't measure revenue. It has no product column (`transaction_method` is the channel), and its fee and penalty rows (`BIAYA` + `DENDA`, about Rp 7.2 jt) are tiny next to Rp 2,394 Bn of balance.

### By category

| Rank | Category | Holders | Total balance (Rp Bn) | Share |
|---|---|---|---|---|
| 1 | **LOAN** | 83 | **1,582.5** | **66.1 %** |
| 2 | FUNDING | 84 | 730.7 | 30.5 % |
| 3 | ORI | 46 | 49.8 | 2.1 % |
| 4 | BANCA | 54 | 25.4 | 1.1 % |
| 5 | REKSA | 54 | 5.8 | 0.2 % |

<!-- chart: q1_balance_by_category -->

LOAN is more than twice FUNDING. The other three categories together are under 4 %.

> dbt model: [fct_revenue_by_category.sql](ocbc_dbt/models/mart/fct_revenue_by_category.sql)

### By product (top 5 of 72)

| Rank | Category | Product | Holders | Total balance (Rp Bn) | Share of total | Share of its category |
|---|---|---|---|---|---|---|
| 1 | FUNDING | **MULTI CURRENCY** | 37 | **535.8** | **22.4 %** | 73.3 % |
| 2 | LOAN | TERM LOAN | 5 | 318.1 | 13.3 % | 20.1 % |
| 3 | LOAN | DEMAND LOAN | 3 | 290.4 | 12.1 % | 18.4 % |
| 4 | LOAN | PIF-FLOATING | 3 | 212.2 | 8.9 % | 13.4 % |
| 5 | LOAN | KRK EMB | 26 | 125.5 | 5.2 % | 7.9 % |

The top product is not in the top category. FUNDING keeps 73.3 % of its balance in MULTI CURRENCY. LOAN spreads its balance over many products.

> dbt model: [fct_revenue_by_product.sql](ocbc_dbt/models/mart/fct_revenue_by_product.sql)

### Limitations

- **Same margin for every product.** With real margins, LOAN likely stays first, because loans usually earn the most per rupiah. The product answer could change: MULTI CURRENCY is a deposit, and the bank keeps only the spread on it.
- **One point in time.** `porto` is a snapshot of balances, not revenue over a period.

---

## Q2. Which product / product category is usually used by customers with high income?

### Answer

- **Most used:** LOAN and FUNDING by category (15 of 18 high-income customers each). BANCA, TANDA360 and PERSONAL LOAN by product (12 of 18 each).
- **Most typical:** **BANCA**. 66.7 % of high-income customers hold it, against 51.2 % of other customers. LOAN and FUNDING are used just as much by everyone.

So the answer is **BANCA**, read as a direction because the group is small (18 customers).

### Who counts as high income

The question doesn't define it, so I use the stated monthly income band: **more than 10 Juta** (`income_rank >= 5`), which is 18 of 100 customers.

| income_rank | income_band | is_high_income | customers |
|---|---|---|---|
| 1 | sd. 1 Juta | false | 20 |
| 2 | >1 Juta - 3 Juta | false | 4 |
| 3 | >3 Juta - 5 Juta | false | 51 |
| 4 | >5 Juta - 10 Juta | false | 7 |
| 5 | >10 Juta - 25 Juta | true | 4 |
| 6 | >25 Juta - 50 Juta | true | 5 |
| 7 | >50 Juta - 100 Juta | true | 3 |
| 8 | >100 Juta | true | 6 |

Half of the customers earn 3–5 Juta, so more than 10 Juta is clearly above normal and is about the top fifth. A lower line (5 Juta) adds middle-income customers. A higher line (25 Juta) leaves only 14.

```sql
select income_rank, income_band, is_high_income, count(*) as customers
from dbt.main.dim_customer
group by all
order by income_rank;
```

> dbt model: [dim_customer.sql](ocbc_dbt/models/mart/dim_customer.sql)

### How to read the tables

`high_pct` = high-income holders ÷ 18. `other_pct` = other holders ÷ 82. Lift = `high_pct` ÷ `other_pct`. A lift above 1 means high-income customers use it more. A holder has a balance above 0 (same rule as Q1).

### By category

| Category | High-income holders (of 18) | High income | Other customers | Lift |
|---|---|---|---|---|
| LOAN | 15 | 83.3 % | 82.9 % | 1.00 |
| FUNDING | 15 | 83.3 % | 84.1 % | 0.99 |
| **BANCA** | **12** | **66.7 %** | **51.2 %** | **1.30** |
| REKSA | 9 | 50.0 % | 54.9 % | 0.91 |
| ORI | 8 | 44.4 % | 46.3 % | 0.96 |

<!-- chart: q2_lift_by_category -->

LOAN and FUNDING are the most used, but their lift is 1.0. BANCA is the only category clearly above 1.

> dbt model: [fct_high_income_usage_by_category.sql](ocbc_dbt/models/mart/fct_high_income_usage_by_category.sql)

### By product (top 7 of 64)

| Category | Product | High-income holders (of 18) | High income | Other customers | Lift |
|---|---|---|---|---|---|
| BANCA | BANCA | 12 | 66.7 % | 51.2 % | **1.30** |
| FUNDING | TANDA360 | 12 | 66.7 % | 58.5 % | 1.14 |
| LOAN | PERSONAL LOAN | 12 | 66.7 % | 59.8 % | 1.12 |
| LOAN | KPR_KENDALI | 11 | 61.1 % | 59.8 % | 1.02 |
| FUNDING | TABSYA | 10 | 55.6 % | 53.7 % | 1.04 |
| FUNDING | DEPOSITO03 | 10 | 55.6 % | 61.0 % | 0.91 |
| FUNDING | DEPOSITO01 | 10 | 55.6 % | 62.2 % | 0.89 |

The top three tie at 12 of 18. BANCA has the highest lift. I skip lift for small products: a lift of 9.11 from 2 customers (KMG_KENDALI) says little.

> dbt model: [fct_high_income_usage_by_product.sql](ocbc_dbt/models/mart/fct_high_income_usage_by_product.sql)

### Limitations

- **Small group.** With 18 customers, one customer moves a percentage by 5.6 points. The BANCA gap is about 3 customers.
- **One point in time.** The portfolio is a snapshot.

**What the bank could do:** use bancassurance as a way in for wealth offers to high-income customers, after re-checking it on the full customer base.
