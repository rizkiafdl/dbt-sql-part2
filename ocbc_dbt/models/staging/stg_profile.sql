-- Cleaned profile: blanks to NULL, plus an ordinal income_rank (1 = lowest band) for sorting and filtering.
with src as (
    select
        customer_id,
        nullif(upper(trim(gender)), '')     as gender,
        nullif(trim(customer_income), '')   as income_band
    from {{ source('raw', 'profile') }}
)

select
    customer_id,
    gender,
    income_band,
    case income_band
        when 'sd. 1 Juta'          then 1
        when '>1 Juta - 3 Juta'    then 2
        when '>3 Juta - 5 Juta'    then 3
        when '>5 Juta - 10 Juta'   then 4
        when '>10 Juta - 25 Juta'  then 5
        when '>25 Juta - 50 Juta'  then 6
        when '>50 Juta - 100 Juta' then 7
        when '>100 Juta'           then 8
    end as income_rank
from src
