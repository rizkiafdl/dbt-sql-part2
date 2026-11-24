-- Q1 answer: total balance per product category.
-- Revenue = balance x margin, equal margin for every product, so revenue ranks the same as balance.
-- holders = customers with amount > 0 (same rule as the Q2 facts).
with by_category as (
    select
        product_category,
        count(distinct customer_id) filter (where amount > 0) as holders,
        sum(amount)                                           as total_balance
    from {{ ref('stg_porto') }}
    group by product_category
)

select
    product_category,
    holders,
    total_balance,
    round(100 * total_balance / sum(total_balance) over (), 1) as share_pct,
    rank() over (order by total_balance desc)                  as balance_rank
from by_category
order by balance_rank
