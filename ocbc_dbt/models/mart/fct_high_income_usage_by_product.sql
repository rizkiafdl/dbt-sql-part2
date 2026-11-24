-- Q2 answer at product level: share of high-income vs other customers who use each product.
-- Grain is (product_category, product): some product names exist in two categories.
-- Uses = holds the product with amount > 0. Only products with at least 1 user appear.
-- Denominators = all customers of the segment in dim_customer (18 high / 82 other),
-- so customers with no product count as "does not use".
-- lift = high share / other share (1.0 = used equally).
with segment_size as (
    select
        count(*) filter (where is_high_income)     as high_customers,
        count(*) filter (where not is_high_income) as other_customers
    from {{ ref('dim_customer') }}
),

users as (
    select
        p.product_category,
        p.product,
        count(distinct p.customer_id) filter (where c.is_high_income)     as high_users,
        count(distinct p.customer_id) filter (where not c.is_high_income) as other_users
    from {{ ref('stg_porto') }} p
    join {{ ref('dim_customer') }} c using (customer_id)
    where p.amount > 0
    group by p.product_category, p.product
),

shares as (
    select
        u.product_category,
        u.product,
        u.high_users,
        u.high_users / s.high_customers   as high_share,
        u.other_users,
        u.other_users / s.other_customers as other_share
    from users u
    cross join segment_size s
)

select
    product_category,
    product,
    high_users,
    round(100 * high_share, 1)                      as high_pct,
    other_users,
    round(100 * other_share, 1)                     as other_pct,
    round(high_share / nullif(other_share, 0), 2)   as lift,
    rank() over (order by high_share desc)          as usage_rank
from shares
order by usage_rank, lift desc
