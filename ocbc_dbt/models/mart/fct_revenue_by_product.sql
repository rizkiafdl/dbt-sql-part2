-- Q1 answer at product level. Grain is (product_category, product), never product alone:
-- GIRO, GIROSYARIAH and MULTI CURRENCY exist in both FUNDING and LOAN.
-- Same measure and holders rule as fct_revenue_by_category.
with by_product as (
    select
        product_category,
        product,
        count(distinct customer_id) filter (where amount > 0) as holders,
        sum(amount)                                           as total_balance
    from {{ ref('stg_porto') }}
    group by product_category, product
)

select
    product_category,
    product,
    holders,
    total_balance,
    round(100 * total_balance / sum(total_balance) over (), 1)                                as share_pct,
    round(100 * total_balance / sum(total_balance) over (partition by product_category), 1)   as share_in_category_pct,
    rank() over (partition by product_category order by total_balance desc)                   as rank_in_category
from by_product
order by product_category, rank_in_category
