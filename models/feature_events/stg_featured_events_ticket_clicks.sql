{{
  config(
    materialized='view',
    tags=['feature_events', 'clicks', 'staging']
  )
}}

select
    cast(artist_event_int_id as integer) as artist_event_int_id,
    cast(ds as date) as ds,
    cast(coalesce(fe_source, 'unknown') as varchar) as fe_source,
    cast(click_datetime as timestamp) as click_datetime,
    cast(user_id as integer) as user_id,
    cast(user_agent as varchar) as user_agent
from {{ source('featured_events', 'ticketclicks') }}
where artist_event_int_id is not null

