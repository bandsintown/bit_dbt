{{
  config(
    materialized='view',
    tags=['feature_events', 'impressions', 'staging']
  )
}}

with src as (
    select
        cast(artist_event_int_id as integer) as artist_event_int_id,
        cast(ds as date) as ds,
        cast(coalesce(fe_source, 'unknown') as varchar) as fe_source,
        cast(nonce as varchar) as nonce,
        cast(user_id as integer) as user_id,
        cast(user_agent as varchar) as user_agent
    from {{ source('featured_events', 'pixelactivities') }}
    where nonce is not null
)

select *
from src

