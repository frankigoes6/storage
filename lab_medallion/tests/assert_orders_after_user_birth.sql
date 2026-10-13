-- A user cannot order before being born: the test fails if this query returns rows
-- Ex3: birthdates cleaned in stg_users (invalid -> NULL), so this returns 0 rows
select
    o.order_id,
    o.ordered_at,
    u.user_id,
    u.birthdate
from {{ ref('stg_orders') }} o
join {{ ref('stg_users') }} u on o.user_id = u.user_id
where o.ordered_at < u.birthdate
