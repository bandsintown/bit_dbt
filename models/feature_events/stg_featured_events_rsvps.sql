{{
  config(
    materialized='view',
    tags=['feature_events', 'rsvp', 'staging']
  )
}}

select
    cast(artist_event_int_id as integer) as artist_event_int_id,
    cast(ds as date) as ds,
    cast(coalesce(source, 'unknown') as varchar) as fe_source,
    cast(nonce as varchar) as nonce,
    cast(user_id as varchar) as user_id,
    cast(status as varchar) as status
from {{ source('featured_events', 'rsvps') }}
where artist_event_int_id is not null
  and nonce is not null

