{{
  config(
    materialized='view',
    tags=['feature_events', 'rsvp', 'staging']
  )
}}
select
    cast(cast(artist_event_int_id as varchar) as integer) as artist_event_int_id,
    cast(substr(cast(ds as varchar), 1, 10) as date) as ds,
    cast(source as varchar) as fe_source,
    cast(nonce as varchar) as nonce,
    cast(cast(user_id as varchar) as integer) as user_id,
    cast(status as varchar) as status
from {{ source('featured_events', 'rsvps') }}
