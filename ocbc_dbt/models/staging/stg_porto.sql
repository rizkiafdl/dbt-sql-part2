-- Cleaned portfolio: key renamed to customer_id, text trimmed.
-- 1 NULL product -> '(UNKNOWN)'; 5 NULL amounts -> 0.
-- Product codes keep their original case (e.g. 'KPR-Syariah'); category is upper-cased.
select
    customerid                                       as customer_id,
    nullif(upper(trim(product_category)), '')        as product_category,
    coalesce(nullif(trim(product), ''), '(UNKNOWN)') as product,
    coalesce(amount, 0)                              as amount
from {{ source('raw', 'porto') }}
