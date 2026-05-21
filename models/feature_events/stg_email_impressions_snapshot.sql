select
    e.ds as date,
    e.sg_message_id,
    fe_id as artist_event_int_id,
    e.category
from {{ source('featured_events', 'email_real_opens') }} as e
cross join unnest(e.featured_events_ids) as t(fe_id)

