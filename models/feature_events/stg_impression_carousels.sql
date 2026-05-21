select
    p.ds,
    p.nonce,
    p.source,
    fe_id as artist_event_int_id,
    p.came_from
from {{ source('featured_events', 'pixel_impressions_v2') }} as p
cross join unnest(p.featured_event_ids) as t(fe_id)

