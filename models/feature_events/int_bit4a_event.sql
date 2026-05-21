with package_with_event_info as (
    select distinct
        e.event_id
    from {{ source('featured_artist_events', 'packages') }} as p
    left join {{ source('featured_artist_events', 'events') }} as e
        on e.package_id = p.id
    where p.deleted = 0
      and e.deleted = 0
      and p.status != 'cancelled'
      and e.status != 'pending'
      and p.price is not null
)
select event_id
from package_with_event_info

