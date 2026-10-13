{{ config(severity='warn') }}

-- Ex4: state/ZIP consistency. Flags rows whose 5-digit ZIP is outside the
-- valid range for the state (reference seed ref_state_zip).
-- Reference: USPS ZIP ranges (simplified to min/max per state).
select
    u.user_id,
    u.state,
    u.zip_code
from {{ ref('stg_users') }} u
join {{ ref('ref_state_zip') }} r
    on u.state = r.code
where try_cast(u.zip_code as integer) is null
   or try_cast(u.zip_code as integer) not between r.zip_min and r.zip_max
