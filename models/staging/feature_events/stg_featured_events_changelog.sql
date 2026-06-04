{{
  config(
    materialized='view',
    tags=['feature_events', 'staging']
  )
}}
select
    cast(event_id as integer) as event_id,
    sources,
    cast(boost_start_date as varchar) as boost_start_date,
    cast(boost_end_date as varchar) as boost_end_date,
    cast(tracked_at as timestamp) as tracked_at
from {{ source('featured_events', 'featured_events_changelog') }}
