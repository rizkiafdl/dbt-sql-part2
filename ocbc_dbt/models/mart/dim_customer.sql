-- One row per profile customer (all 100, also the 14 without a porto row).
-- High income = income_rank >= 5, i.e. '>10 Juta' per month or higher (18 customers).
select
    customer_id,
    gender,
    income_band,
    income_rank,
    income_rank >= 5 as is_high_income
from {{ ref('stg_profile') }}
