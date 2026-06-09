{{
  config(
    materialized='view',
    tags=['feature_events', 'impressions', 'staging']
  )
}}

select
    cast(cast(artist_event_int_id as varchar) as integer) as artist_event_int_id,
    cast(substr(cast(ds as varchar), 1, 10) as date) as ds,
    cast(fe_source as varchar) as fe_source,
    cast(nonce as varchar) as nonce,
    cast(cast(user_id as varchar) as integer) as user_id,
    cast(user_agent as varchar) as user_agent
from {{ source('featured_events', 'pixelactivities') }}

