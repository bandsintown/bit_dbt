{{
  config(
    materialized='view',
    tags=['feature_events', 'impressions', 'staging']
  )
}}

select
    cast(fe_id as integer) as artist_event_int_id,
    cast(ds as date) as ds,
    cast('email' as varchar) as fe_source,
    cast(nonce as varchar) as nonce,
    cast(cast(user_id as varchar) as integer) as user_id,
    cast(useragent as varchar) as user_agent,
    cast(category as varchar) as category,
    cast(event as varchar) as event,
    featured_events_ids
from {{ source('featured_events', 'email_real_opens') }}
cross join unnest(featured_events_ids) as t(fe_id)

