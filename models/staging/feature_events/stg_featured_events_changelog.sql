{{
  config(
    materialized='view',
    tags=['feature_events', 'staging']
  )
}}
select
    cast(cast(event_id as varchar) as integer) as event_id,
    sources,
    cast(boost_start_date as varchar) as boost_start_date,
    cast(boost_end_date as varchar) as boost_end_date,
    cast(replace(cast(tracked_at as varchar), 'T', ' ') as timestamp) as tracked_at
from {{ source('featured_events', 'featured_events_changelog') }}
