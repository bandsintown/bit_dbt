{{
  config(
    materialized='table',
    tags=['feature_events', 'dims']
  )
}}

-- Dimension: deduplicated ticket clicks (one row per click)
select
    artist_event_int_id,
    ds,
    fe_source,
    click_datetime,
    user_id,
    user_agent
from {{ ref('stg_featured_events_ticket_clicks') }}
where artist_event_int_id is not null

