with source as (
    select * from {{ source('bronze', 'users') }}
),

typed as (
    select
        cast(uuid as uuid) as user_id,
        trim(username) as username,
        trim(name) as name,
        upper(trim(sex)) as sex,
        lower(trim(mail)) as email,
        cast(birthdate as date) as birthdate_raw,
        -- The address spans 2 lines: the street, then the city, the state and the zip code
        split_part(address, chr(10), 1) as street,
        split_part(address, chr(10), 2) as address_line_2
    from source
),

-- Ex3: first order per user to validate birthdates
first_orders as (
    select
        user_id,
        min(ordered_at) as first_ordered_at
    from {{ ref('stg_orders') }}
    group by user_id
),

cleaned as (
    select
        t.*,
        f.first_ordered_at,
        -- Ex1: normalized username
        lower(t.username) as username_normalized,
        -- Ex3: a birthdate later than the user's first order is invalid
        (
            f.first_ordered_at is null
            or t.birthdate_raw is null
            or t.birthdate_raw <= cast(f.first_ordered_at as date)
        ) as birthdate_is_valid
    from typed t
    left join first_orders f on t.user_id = f.user_id
)

select
    user_id,
    username,
    username_normalized,
    name,
    sex,
    email,
    -- Ex3: replace invalid birthdates with NULL
    case when birthdate_is_valid then birthdate_raw else null end as birthdate,
    birthdate_is_valid,
    street,
    -- Military addresses, such as "DPO AE 12345", have no comma
    nullif(regexp_extract(address_line_2, '^(.+), [A-Z]{2} \d{5}$', 1), '') as city,
    regexp_extract(address_line_2, '([A-Z]{2}) (\d{5})$', 1) as state,
    regexp_extract(address_line_2, '([A-Z]{2}) (\d{5})$', 2) as zip_code
from cleaned
