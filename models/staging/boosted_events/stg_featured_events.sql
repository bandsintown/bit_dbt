{{
  config(
    materialized='view',
    tags=['feature_events', 'staging']
  )
}}

select
    cast(event_id as varchar) as event_id,
    cast(artist_id as varchar) as artist_id,
    cast(venue_id as varchar) as venue_id,
    cast(festival_id as varchar) as festival_id,
    cast(fe_source as varchar) as fe_source,
    cast(boost_start_date as varchar) as boost_start_date,
    cast(boost_end_date as varchar) as boost_end_date
from {{ source('featured_events', 'featured_events') }}

