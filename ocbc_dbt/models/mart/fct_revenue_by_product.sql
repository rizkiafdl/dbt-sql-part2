with by_product as (
    select
        product,
        count(distinct customer_id) filter (where amount > 0) as holders,
        sum(amount)                                           as total_balance
    from {{ ref('stg_porto') }}
    group by product
)

select
    product,
    holders,
    total_balance,
    round(100 * total_balance / sum(total_balance) over (), 1) as share_pct,
    rank() over (order by total_balance desc)                  as balance_rank
from by_product
order by balance_rank
