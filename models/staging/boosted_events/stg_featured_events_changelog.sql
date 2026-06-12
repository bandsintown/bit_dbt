{{
  config(
    materialized='view',
    tags=['feature_events', 'staging']
  )
}}

select
    cast(cast(event_id as varchar) as integer) as event_id,
    cast(cast(artist_id as varchar) as integer) as artist_id,
    cast(cast(venue_id as varchar) as integer) as venue_id,
    cast(cast(festival_id as varchar) as integer) as festival_id,
    sources,
    cast(boost_start_date as varchar) as boost_start_date,
    cast(boost_end_date as varchar) as boost_end_date,
    cast(campaign_flat_fee as double) as campaign_flat_fee,
    cast(urgency_score as double) as urgency_score,
    cast(urgency_basis as varchar) as urgency_basis,
    cast(cpc_goal_met as boolean) as cpc_goal_met,
    cast(cpm_goal_met as boolean) as cpm_goal_met,
    cast(campaign_state as varchar) as campaign_state,
    cast(goal_achieved as boolean) as goal_achieved,
    cast(change_type as varchar) as change_type,
    cast(replace(cast(tracked_at as varchar), 'T', ' ') as timestamp) as tracked_at,
    cast(dt as varchar) as dt
from {{ source('featured_events', 'featured_events_changelog') }}
